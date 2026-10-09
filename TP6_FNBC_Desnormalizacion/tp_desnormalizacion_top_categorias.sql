-- TP6 — Parte 2: propuesta de desnormalización transaccional.
-- Ejecutar completo con psql exclusivamente en la copia de trabajo.
-- Requiere respaldo previo porque contiene DDL.
-- No instala cambios persistentes: termina con ROLLBACK.
--
-- Alcance de sincronización:
-- DML normal con triggers habilitados y aislamiento READ COMMITTED.
-- No cubre escrituras que deshabiliten triggers o usen replicación
-- para omitirlos. Las pruebas concurrentes quedan pendientes.

\set ON_ERROR_STOP on

BEGIN;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- ============================================================
-- 1. Base, tablas y condiciones de ejecución
-- ============================================================

DO $$
DECLARE
    v_tabla TEXT;
BEGIN
    IF current_database() <> 'foodstore_copia_trabajo' THEN
        RAISE EXCEPTION
            'Base no permitida: %. Usar foodstore_copia_trabajo.',
            current_database();
    END IF;

    IF current_setting('session_replication_role') <> 'origin' THEN
        RAISE EXCEPTION
            'La prueba requiere session_replication_role = origin.';
    END IF;

    FOREACH v_tabla IN ARRAY ARRAY[
        'pedido', 'detalle_pedido', 'producto', 'categoria', 'cliente'
    ]
    LOOP
        IF NOT EXISTS (
            SELECT 1
            FROM pg_catalog.pg_class AS c
            JOIN pg_catalog.pg_namespace AS n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'public'
              AND c.relname = v_tabla
              AND c.relkind = 'r'
              AND NOT c.relrowsecurity
        ) THEN
            RAISE EXCEPTION
                'public.% debe existir como tabla ordinaria sin RLS para esta propuesta.',
                v_tabla;
        END IF;
    END LOOP;
END;
$$;

-- Bloquea escrituras y DDL concurrente durante instalación,
-- carga inicial, pruebas y mediciones. NOWAIT evita quedar esperando.
-- ACCESS EXCLUSIVE también bloquea lectores: es una instalación
-- de laboratorio, no una migración en línea.
-- No hay una ventana entre carga y activación de triggers.

LOCK TABLE
    public.categoria,
    public.cliente,
    public.pedido,
    public.producto,
    public.detalle_pedido
IN ACCESS EXCLUSIVE MODE NOWAIT;

-- ============================================================
-- 2. Rechazar objetos existentes y condiciones incompatibles
-- ============================================================

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_attribute
        WHERE attrelid = 'public.detalle_pedido'::regclass
          AND attname IN (
              'fecha_hora_pedido_cache',
              'id_categoria_cache'
          )
          AND NOT attisdropped
    ) THEN
        RAISE EXCEPTION
            'Ya existe alguna columna cache. No se sobrescribirá.';
    END IF;

    -- Rechaza cualquier sobrecarga con estos nombres.
    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_proc AS p
        JOIN pg_catalog.pg_namespace AS n
          ON n.oid = p.pronamespace
        WHERE n.nspname = 'public'
          AND p.proname IN (
              'fn_tp6_sync_detalle_cache',
              'fn_tp6_propagar_fecha_cache',
              'fn_tp6_propagar_categoria_cache'
          )
    ) THEN
        RAISE EXCEPTION
            'Ya existe alguna función reservada para TP6.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_trigger
        WHERE tgrelid IN (
            'public.detalle_pedido'::regclass,
            'public.pedido'::regclass,
            'public.producto'::regclass
        )
          AND tgname IN (
              'zz_tp6_sync_detalle_cache',
              'trg_tp6_propagar_fecha_cache',
              'trg_tp6_propagar_categoria_cache'
          )
    ) THEN
        RAISE EXCEPTION
            'Ya existe algún trigger reservado para TP6.';
    END IF;

    -- También rechaza una relación de otro tipo con el nombre del índice.
    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_class AS c
        JOIN pg_catalog.pg_namespace AS n
          ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relname = 'idx_tp6_detalle_fecha_cache'
    ) THEN
        RAISE EXCEPTION
            'Ya existe public.idx_tp6_detalle_fecha_cache.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_constraint
        WHERE conrelid = 'public.detalle_pedido'::regclass
          AND conname = 'fk_tp6_detalle_categoria_cache'
    ) THEN
        RAISE EXCEPTION
            'Ya existe la restricción reservada para TP6.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_class
        WHERE relnamespace = pg_my_temp_schema()
          AND relname IN (
              'tp6_auditoria_cache',
              'tp6_top_normalizado',
              'tp6_top_cache',
              'tp6_diferencias_top'
          )
    ) THEN
        RAISE EXCEPTION
            'Ya existe alguna relación temporal reservada para esta prueba.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM pg_catalog.pg_trigger
        WHERE tgrelid IN (
            'public.detalle_pedido'::regclass,
            'public.pedido'::regclass,
            'public.producto'::regclass
        )
          AND NOT tgisinternal
          AND tgenabled <> 'O'
    ) THEN
        RAISE EXCEPTION
            'Hay triggers de usuario fuera del modo origin habilitado. Revisar antes de continuar.';
    END IF;

    -- Verifica la existencia de los padres y de la categoría.
    -- No compara cantidad con stock actual: esa comparación no
    -- determina la validez de un detalle histórico para este ensayo.
    --
    -- El repositorio contiene un script de validación de stock,
    -- pero la comprobación real de esta copia no encontró triggers
    -- de usuario instalados en pedido, detalle_pedido ni producto.
    -- No se instala esa regla ni se modifican cantidades o stock.

    IF EXISTS (
        SELECT 1
        FROM public.detalle_pedido AS dp
        LEFT JOIN public.producto AS pr
          ON pr.id = dp.id_producto
        LEFT JOIN public.pedido AS ped
          ON ped.id = dp.id_pedido
        LEFT JOIN public.categoria AS c
          ON c.id = pr.id_categoria
        WHERE pr.id IS NULL
           OR ped.id IS NULL
           OR c.id IS NULL
    ) THEN
        RAISE EXCEPTION
            'Hay detalles sin pedido, producto o categoría existentes. Carga inicial abortada.';
    END IF;
END;
$$;

-- ============================================================
-- 3. Columnas y sincronización de detalles
-- ============================================================

ALTER TABLE public.detalle_pedido
    ADD COLUMN fecha_hora_pedido_cache TIMESTAMPTZ,
    ADD COLUMN id_categoria_cache BIGINT;

CREATE FUNCTION public.fn_tp6_sync_detalle_cache()
RETURNS TRIGGER
LANGUAGE plpgsql
VOLATILE
SET search_path = pg_catalog, public
AS $$
DECLARE
    v_fecha TIMESTAMPTZ;
    v_categoria BIGINT;
BEGIN
    IF current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION
            'La sincronización TP6 soporta únicamente READ COMMITTED.';
    END IF;

    -- Orden de lectura/bloqueo: pedido, después producto.
    -- Los bloqueos se conservan hasta terminar la transacción.
    SELECT ped.fecha_hora
      INTO v_fecha
      FROM public.pedido AS ped
     WHERE ped.id = NEW.id_pedido
     FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No existe el pedido %.', NEW.id_pedido;
    END IF;

    SELECT pr.id_categoria
      INTO v_categoria
      FROM public.producto AS pr
     WHERE pr.id = NEW.id_producto
     FOR SHARE;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'No existe el producto %.', NEW.id_producto;
    END IF;

    -- Siempre se recalcula: no se aceptan copias arbitrarias,
    -- incluso si el UPDATE menciona directamente las columnas cache.
    NEW.fecha_hora_pedido_cache := v_fecha;
    NEW.id_categoria_cache := v_categoria;

    RETURN NEW;
END;
$$;

CREATE TRIGGER zz_tp6_sync_detalle_cache
BEFORE INSERT OR UPDATE ON public.detalle_pedido
FOR EACH ROW
EXECUTE FUNCTION public.fn_tp6_sync_detalle_cache();

-- ============================================================
-- 4. Propagación desde pedidos y productos
-- ============================================================

CREATE FUNCTION public.fn_tp6_propagar_fecha_cache()
RETURNS TRIGGER
LANGUAGE plpgsql
VOLATILE
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION
            'La sincronización TP6 soporta únicamente READ COMMITTED.';
    END IF;

    -- El UPDATE del padre ya mantiene su bloqueo de fila.
    -- Este UPDATE obtiene una instantánea nueva en READ COMMITTED.
    -- El trigger del detalle vuelve a derivar ambas copias.
    UPDATE public.detalle_pedido
       SET fecha_hora_pedido_cache = NEW.fecha_hora
     WHERE id_pedido = NEW.id
       AND fecha_hora_pedido_cache IS DISTINCT FROM NEW.fecha_hora;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_tp6_propagar_fecha_cache
AFTER UPDATE ON public.pedido
FOR EACH ROW
WHEN (OLD.fecha_hora IS DISTINCT FROM NEW.fecha_hora)
EXECUTE FUNCTION public.fn_tp6_propagar_fecha_cache();

CREATE FUNCTION public.fn_tp6_propagar_categoria_cache()
RETURNS TRIGGER
LANGUAGE plpgsql
VOLATILE
SET search_path = pg_catalog, public
AS $$
BEGIN
    IF current_setting('transaction_isolation') <> 'read committed' THEN
        RAISE EXCEPTION
            'La sincronización TP6 soporta únicamente READ COMMITTED.';
    END IF;

    UPDATE public.detalle_pedido
       SET id_categoria_cache = NEW.id_categoria
     WHERE id_producto = NEW.id
       AND id_categoria_cache IS DISTINCT FROM NEW.id_categoria;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_tp6_propagar_categoria_cache
AFTER UPDATE ON public.producto
FOR EACH ROW
WHEN (OLD.id_categoria IS DISTINCT FROM NEW.id_categoria)
EXECUTE FUNCTION public.fn_tp6_propagar_categoria_cache();

-- DELETE de detalle elimina también las copias, sin acumulados externos.
-- DELETE de pedido conserva el CASCADE existente hacia sus detalles.
-- Las restricciones originales impiden borrar productos/categorías
-- utilizados.
-- No se modifican las FK originales ni se instalan los triggers de TP2.
-- Los únicos triggers creados aquí son los de sincronización TP6.
--
-- categoria.nombre no se copia: el JOIN muestra su valor vigente.

-- ============================================================
-- 5. Carga inicial, restricciones e índice
-- ============================================================

UPDATE public.detalle_pedido AS dp
SET
    fecha_hora_pedido_cache = ped.fecha_hora,
    id_categoria_cache = pr.id_categoria
FROM public.pedido AS ped,
     public.producto AS pr
WHERE ped.id = dp.id_pedido
  AND pr.id = dp.id_producto;

ALTER TABLE public.detalle_pedido
    ALTER COLUMN fecha_hora_pedido_cache SET NOT NULL,
    ALTER COLUMN id_categoria_cache SET NOT NULL,
    ADD CONSTRAINT fk_tp6_detalle_categoria_cache
        FOREIGN KEY (id_categoria_cache)
        REFERENCES public.categoria (id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE;

-- Índice acotado a la búsqueda diaria.
-- Su costo y beneficio forman parte de la adaptación completa.
CREATE INDEX idx_tp6_detalle_fecha_cache
ON public.detalle_pedido (fecha_hora_pedido_cache);

-- ============================================================
-- 6. Auditoría completa, sin limitarse al día de medición
-- ============================================================

CREATE TEMP VIEW tp6_auditoria_cache AS
SELECT
    dp.id_pedido,
    dp.id_producto,
    dp.fecha_hora_pedido_cache,
    ped.fecha_hora AS fecha_hora_original,
    dp.id_categoria_cache,
    pr.id_categoria AS id_categoria_original
FROM public.detalle_pedido AS dp
LEFT JOIN public.pedido AS ped
    ON ped.id = dp.id_pedido
LEFT JOIN public.producto AS pr
    ON pr.id = dp.id_producto
LEFT JOIN public.categoria AS c
    ON c.id = dp.id_categoria_cache
WHERE ped.id IS NULL
   OR pr.id IS NULL
   OR c.id IS NULL
   OR dp.fecha_hora_pedido_cache IS DISTINCT FROM ped.fecha_hora
   OR dp.id_categoria_cache IS DISTINCT FROM pr.id_categoria;

SELECT *
FROM pg_temp.tp6_auditoria_cache
ORDER BY id_pedido, id_producto;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_temp.tp6_auditoria_cache) THEN
        RAISE EXCEPTION
            'Auditoría inicial fallida: hay datos cache desincronizados.';
    END IF;
END;
$$;

-- ============================================================
-- 7. Consultas acordadas
-- ============================================================
-- Fecha histórica reproducible: 2026-06-25, America/Buenos_Aires.
-- Sustituye CURRENT_DATE porque la carga no contiene pedidos de hoy.
-- No existen columnas eliminado en pedido/detalle_pedido.
-- Se consideran todos los registros del día, sin estado ni activo.
--
-- Estas vistas son temporales y normales, no materializadas.
-- El planificador expande sus definiciones.

CREATE TEMP VIEW tp6_top_normalizado AS
SELECT
    c.nombre AS categoria,
    SUM(dp.subtotal) AS total_vendido
FROM public.detalle_pedido AS dp
JOIN public.producto AS pr
    ON pr.id = dp.id_producto
JOIN public.categoria AS c
    ON c.id = pr.id_categoria
JOIN public.pedido AS ped
    ON ped.id = dp.id_pedido
WHERE ped.fecha_hora >= (
    TIMESTAMP '2026-06-25 00:00:00'
    AT TIME ZONE 'America/Buenos_Aires'
)
  AND ped.fecha_hora < (
    TIMESTAMP '2026-06-26 00:00:00'
    AT TIME ZONE 'America/Buenos_Aires'
)
GROUP BY c.nombre
ORDER BY total_vendido DESC
LIMIT 5;

CREATE TEMP VIEW tp6_top_cache AS
SELECT
    c.nombre AS categoria,
    SUM(dp.subtotal) AS total_vendido
FROM public.detalle_pedido AS dp
JOIN public.categoria AS c
    ON c.id = dp.id_categoria_cache
WHERE dp.fecha_hora_pedido_cache >= (
    TIMESTAMP '2026-06-25 00:00:00'
    AT TIME ZONE 'America/Buenos_Aires'
)
  AND dp.fecha_hora_pedido_cache < (
    TIMESTAMP '2026-06-26 00:00:00'
    AT TIME ZONE 'America/Buenos_Aires'
)
GROUP BY c.nombre
ORDER BY total_vendido DESC
LIMIT 5;

CREATE TEMP VIEW tp6_diferencias_top AS
SELECT 'normalizado_menos_cache'::TEXT AS sentido, d.*
FROM (
    SELECT categoria, total_vendido
    FROM pg_temp.tp6_top_normalizado
    EXCEPT
    SELECT categoria, total_vendido
    FROM pg_temp.tp6_top_cache
) AS d
UNION ALL
SELECT 'cache_menos_normalizado'::TEXT AS sentido, d.*
FROM (
    SELECT categoria, total_vendido
    FROM pg_temp.tp6_top_cache
    EXCEPT
    SELECT categoria, total_vendido
    FROM pg_temp.tp6_top_normalizado
) AS d;

-- ============================================================
-- 8. Pruebas de sincronización reversibles
-- ============================================================
-- IDs negativos explícitos: no se consumen secuencias.
-- OVERRIDING SYSTEM VALUE respeta los identity ALWAYS originales.
-- Se utiliza un cliente existente sin modificarlo.
-- Las filas de prueba tienen cantidades positivas y fechas históricas.
-- No se cambia el estado de los pedidos ni se alteran filas originales.
-- No hay triggers de usuario previos instalados en esta copia;
-- los scripts de TP2 permanecen en el repositorio y no se ejecutan aquí.
-- Las pruebas se deshacen mediante ROLLBACK TO SAVEPOINT.

SAVEPOINT pruebas_sincronizacion;

DO $$
DECLARE
    v_cliente BIGINT;
    v_fecha TIMESTAMPTZ;
    v_categoria BIGINT;
    v_nombre TEXT;
BEGIN
    IF EXISTS (
        SELECT 1 FROM public.categoria WHERE id IN (-6001, -6002)
    ) OR EXISTS (
        SELECT 1 FROM public.producto WHERE id IN (-6001, -6002)
    ) OR EXISTS (
        SELECT 1 FROM public.pedido WHERE id IN (-6001, -6002)
    ) OR EXISTS (
        SELECT 1
        FROM public.categoria
        WHERE nombre IN (
            'TP6_TEST_CACHE_A',
            'TP6_TEST_CACHE_B',
            'TP6_TEST_CACHE_RENOMBRADA'
        )
    ) THEN
        RAISE EXCEPTION
            'Conflicto con IDs o nombres reservados para las pruebas.';
    END IF;

    SELECT id INTO v_cliente
    FROM public.cliente
    ORDER BY id
    LIMIT 1;

    IF v_cliente IS NULL THEN
        RAISE EXCEPTION
            'Se necesita un cliente existente para los pedidos de prueba.';
    END IF;

    INSERT INTO public.categoria (id, nombre)
    OVERRIDING SYSTEM VALUE
    VALUES
        (-6001, 'TP6_TEST_CACHE_A'),
        (-6002, 'TP6_TEST_CACHE_B');

    INSERT INTO public.producto (
        id, id_categoria, nombre, precio_lista, stock
    )
    OVERRIDING SYSTEM VALUE
    VALUES
        (-6001, -6001, 'TP6 producto prueba A', 10.00, 100),
        (-6002, -6002, 'TP6 producto prueba B', 20.00, 100);

    INSERT INTO public.pedido (
        id, id_cliente, fecha_hora, forma_pago
    )
    OVERRIDING SYSTEM VALUE
    VALUES
        (
            -6001, v_cliente,
            TIMESTAMP '2026-06-25 10:00:00'
                AT TIME ZONE 'America/Buenos_Aires',
            'EFECTIVO'
        ),
        (
            -6002, v_cliente,
            TIMESTAMP '2026-06-24 10:00:00'
                AT TIME ZONE 'America/Buenos_Aires',
            'EFECTIVO'
        );

    -- INSERT: copias derivadas y subtotal generado.
    INSERT INTO public.detalle_pedido (
        id_pedido, id_producto, cantidad, precio_unitario
    )
    VALUES (-6001, -6001, 2, 10.00);

    IF NOT EXISTS (
        SELECT 1
        FROM public.detalle_pedido
        WHERE id_pedido = -6001
          AND id_producto = -6001
          AND fecha_hora_pedido_cache = (
              TIMESTAMP '2026-06-25 10:00:00'
              AT TIME ZONE 'America/Buenos_Aires'
          )
          AND id_categoria_cache = -6001
          AND subtotal = 20.00
    ) THEN
        RAISE EXCEPTION 'Falló la prueba de INSERT.';
    END IF;

    -- UPDATE: cambia monto y rechaza copias arbitrarias.
    UPDATE public.detalle_pedido
    SET cantidad = 3,
        precio_unitario = 12.00,
        fecha_hora_pedido_cache = (
            TIMESTAMP '2000-01-01 00:00:00'
            AT TIME ZONE 'America/Buenos_Aires'
        ),
        id_categoria_cache = -6002
    WHERE id_pedido = -6001
      AND id_producto = -6001;

    IF NOT EXISTS (
        SELECT 1
        FROM public.detalle_pedido
        WHERE id_pedido = -6001
          AND id_producto = -6001
          AND id_categoria_cache = -6001
          AND fecha_hora_pedido_cache = (
              TIMESTAMP '2026-06-25 10:00:00'
              AT TIME ZONE 'America/Buenos_Aires'
          )
          AND subtotal = 36.00
    ) THEN
        RAISE EXCEPTION 'Falló la prueba de UPDATE del detalle.';
    END IF;

    -- Cambia ambos padres del detalle.
    UPDATE public.detalle_pedido
    SET id_pedido = -6002,
        id_producto = -6002
    WHERE id_pedido = -6001
      AND id_producto = -6001;

    IF NOT EXISTS (
        SELECT 1
        FROM public.detalle_pedido
        WHERE id_pedido = -6002
          AND id_producto = -6002
          AND id_categoria_cache = -6002
          AND fecha_hora_pedido_cache = (
              TIMESTAMP '2026-06-24 10:00:00'
              AT TIME ZONE 'America/Buenos_Aires'
          )
    ) THEN
        RAISE EXCEPTION 'Falló la prueba de cambio de padres.';
    END IF;

    -- Fecha del pedido: el detalle vuelve al día medido.
    UPDATE public.pedido
    SET fecha_hora = (
        TIMESTAMP '2026-06-25 11:00:00'
        AT TIME ZONE 'America/Buenos_Aires'
    )
    WHERE id = -6002;

    SELECT fecha_hora_pedido_cache INTO v_fecha
    FROM public.detalle_pedido
    WHERE id_pedido = -6002 AND id_producto = -6002;

    IF v_fecha IS DISTINCT FROM (
        TIMESTAMP '2026-06-25 11:00:00'
        AT TIME ZONE 'America/Buenos_Aires'
    ) THEN
        RAISE EXCEPTION 'Falló la propagación de fecha.';
    END IF;

    -- Categoría actual del producto.
    UPDATE public.producto
    SET id_categoria = -6001
    WHERE id = -6002;

    SELECT id_categoria_cache INTO v_categoria
    FROM public.detalle_pedido
    WHERE id_pedido = -6002 AND id_producto = -6002;

    IF v_categoria IS DISTINCT FROM -6001::BIGINT THEN
        RAISE EXCEPTION 'Falló la propagación de categoría.';
    END IF;

    -- Nombre: el JOIN debe mostrar el cambio sin copiarlo.
    UPDATE public.categoria
    SET nombre = 'TP6_TEST_CACHE_RENOMBRADA'
    WHERE id = -6001;

    SELECT c.nombre INTO v_nombre
    FROM public.detalle_pedido AS dp
    JOIN public.categoria AS c
      ON c.id = dp.id_categoria_cache
    WHERE dp.id_pedido = -6002 AND dp.id_producto = -6002;

    IF v_nombre IS DISTINCT FROM 'TP6_TEST_CACHE_RENOMBRADA' THEN
        RAISE EXCEPTION 'Falló la prueba de nombre de categoría.';
    END IF;

    IF EXISTS (SELECT 1 FROM pg_temp.tp6_auditoria_cache) THEN
        RAISE EXCEPTION 'Auditoría fallida durante las pruebas.';
    END IF;

    IF EXISTS (SELECT 1 FROM pg_temp.tp6_diferencias_top) THEN
        RAISE EXCEPTION 'Resultados diferentes durante las pruebas.';
    END IF;

    -- DELETE directo.
    DELETE FROM public.detalle_pedido
    WHERE id_pedido = -6002 AND id_producto = -6002;

    IF EXISTS (
        SELECT 1 FROM public.detalle_pedido
        WHERE id_pedido = -6002 AND id_producto = -6002
    ) THEN
        RAISE EXCEPTION 'Falló la prueba de DELETE.';
    END IF;

    -- DELETE del pedido con CASCADE.
    INSERT INTO public.detalle_pedido (
        id_pedido, id_producto, cantidad, precio_unitario
    )
    VALUES (-6002, -6002, 1, 20.00);

    DELETE FROM public.pedido WHERE id = -6002;

    IF EXISTS (
        SELECT 1 FROM public.detalle_pedido WHERE id_pedido = -6002
    ) THEN
        RAISE EXCEPTION 'Falló la prueba de DELETE CASCADE.';
    END IF;

    IF EXISTS (SELECT 1 FROM pg_temp.tp6_auditoria_cache) THEN
        RAISE EXCEPTION 'Auditoría fallida después de DELETE.';
    END IF;

    RAISE NOTICE
        'Pruebas de sincronización secuenciales superadas; no son pruebas concurrentes.';
END;
$$;

ROLLBACK TO SAVEPOINT pruebas_sincronizacion;
RELEASE SAVEPOINT pruebas_sincronizacion;

-- ============================================================
-- 9. Auditoría y equivalencia después de deshacer las pruebas
-- ============================================================

SELECT *
FROM pg_temp.tp6_auditoria_cache
ORDER BY id_pedido, id_producto;

SELECT *
FROM pg_temp.tp6_diferencias_top
ORDER BY sentido, categoria;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_temp.tp6_auditoria_cache) THEN
        RAISE EXCEPTION
            'Auditoría completa fallida después de las pruebas.';
    END IF;

    IF EXISTS (SELECT 1 FROM pg_temp.tp6_diferencias_top) THEN
        RAISE EXCEPTION
            'EXCEPT bidireccional detectó resultados diferentes.';
    END IF;

    RAISE NOTICE
        'Auditoría completa y EXCEPT bidireccional: resultados vacíos.';
END;
$$;

-- ============================================================
-- 10. Medición comparable después de cargar e indexar
-- ============================================================
-- Ambas consultas ven las mismas filas y estadísticas.
-- La carga inicial genera versiones de filas y puede afectar
-- visibilidad/index-only scans: no representa una tabla ya aspirada.
-- No se ejecuta VACUUM dentro de esta transacción.
-- Se informa este límite al interpretar los resultados.

ANALYZE public.pedido;
ANALYZE public.producto;
ANALYZE public.categoria;
ANALYZE public.detalle_pedido;

-- Resultados y calentamiento previo de ambos recorridos.
SELECT categoria, total_vendido
FROM pg_temp.tp6_top_normalizado
ORDER BY total_vendido DESC;

SELECT categoria, total_vendido
FROM pg_temp.tp6_top_cache
ORDER BY total_vendido DESC;

-- Ronda 1: normalizada, luego desnormalizada.
\echo 'Ronda 1 — consulta normalizada'

EXPLAIN (ANALYZE, BUFFERS)
SELECT categoria, total_vendido
FROM pg_temp.tp6_top_normalizado
ORDER BY total_vendido DESC;

\echo 'Ronda 1 — consulta desnormalizada'

EXPLAIN (ANALYZE, BUFFERS)
SELECT categoria, total_vendido
FROM pg_temp.tp6_top_cache
ORDER BY total_vendido DESC;

-- Ronda 2: orden inverso.
\echo 'Ronda 2 — consulta desnormalizada'

EXPLAIN (ANALYZE, BUFFERS)
SELECT categoria, total_vendido
FROM pg_temp.tp6_top_cache
ORDER BY total_vendido DESC;

\echo 'Ronda 2 — consulta normalizada'

EXPLAIN (ANALYZE, BUFFERS)
SELECT categoria, total_vendido
FROM pg_temp.tp6_top_normalizado
ORDER BY total_vendido DESC;

-- No se adjudica una mejora antes de observar tiempos y buffers.
-- La referencia histórica de 47.151 ms se conserva como contexto;
-- la comparación directa usa estas mediciones bajo el mismo estado.
--
-- Resultado de referencia para la carga revisada:
-- Bebidas  5589534.40
-- Pizzas   5215387.22

-- ============================================================
-- 11. Descartar estructura, sincronización y cambios de prueba
-- ============================================================

ROLLBACK;
