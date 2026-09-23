-- Verificacion ejecutable de equivalencia para las vistas de TP5.
-- El script falla si alguna diferencia (EXCEPT) o algun conteo (count(*))
-- no coincide. EXCEPT por si solo compara conjuntos y no detecta
-- duplicados: dos relaciones con las mismas filas distintas pero distinta
-- cantidad de repeticiones dan 0 diferencias en el EXCEPT y aun asi no
-- son equivalentes como resultado de consulta. El chequeo de count(*)
-- cubre ese caso.
\set ON_ERROR_STOP on

CREATE TEMP TABLE tp5_equivalencia (
    vista text PRIMARY KEY,
    diferencias bigint NOT NULL
);

CREATE TEMP TABLE tp5_conteos (
    vista text PRIMARY KEY,
    conteo_vista bigint NOT NULL,
    conteo_manual bigint NOT NULL
);

-- v_catalogo_productos ------------------------------------------------------

INSERT INTO tp5_equivalencia
SELECT 'v_catalogo_productos', count(*)
FROM (
    (
        SELECT producto_id, producto, categoria, precio_lista, stock
        FROM v_catalogo_productos
        EXCEPT
        SELECT p.id, p.nombre, c.nombre, p.precio_lista, p.stock
        FROM producto AS p
        JOIN categoria AS c ON c.id = p.id_categoria
        WHERE p.activo = TRUE AND c.activo = TRUE
    )
    UNION ALL
    (
        SELECT p.id, p.nombre, c.nombre, p.precio_lista, p.stock
        FROM producto AS p
        JOIN categoria AS c ON c.id = p.id_categoria
        WHERE p.activo = TRUE AND c.activo = TRUE
        EXCEPT
        SELECT producto_id, producto, categoria, precio_lista, stock
        FROM v_catalogo_productos
    )
) AS diferencias;

INSERT INTO tp5_conteos
SELECT 'v_catalogo_productos',
    (SELECT count(*) FROM v_catalogo_productos),
    (SELECT count(*) FROM producto AS p
        JOIN categoria AS c ON c.id = p.id_categoria
        WHERE p.activo = TRUE AND c.activo = TRUE);

-- v_reporte_ventas_cliente ---------------------------------------------------
-- (consulta manual con subconsultas escalares, deliberadamente distinta a
-- la forma con JOIN + GROUP BY de la vista)

INSERT INTO tp5_equivalencia
SELECT 'v_reporte_ventas_cliente', count(*)
FROM (
    (
        SELECT cliente_id, nombre_completo, pedidos, total_facturado
        FROM v_reporte_ventas_cliente
        EXCEPT
        SELECT c.id, c.nombre_completo,
               (SELECT COUNT(*) FROM pedido pe
                WHERE pe.id_cliente = c.id AND pe.estado <> 'CANCELADO'),
               COALESCE((
                   SELECT SUM(dp.subtotal)
                   FROM pedido pe
                   JOIN detalle_pedido dp ON dp.id_pedido = pe.id
                   WHERE pe.id_cliente = c.id AND pe.estado <> 'CANCELADO'
               ), 0)::NUMERIC(12, 2)
        FROM cliente AS c
    )
    UNION ALL
    (
        SELECT c.id, c.nombre_completo,
               (SELECT COUNT(*) FROM pedido pe
                WHERE pe.id_cliente = c.id AND pe.estado <> 'CANCELADO'),
               COALESCE((
                   SELECT SUM(dp.subtotal)
                   FROM pedido pe
                   JOIN detalle_pedido dp ON dp.id_pedido = pe.id
                   WHERE pe.id_cliente = c.id AND pe.estado <> 'CANCELADO'
               ), 0)::NUMERIC(12, 2)
        FROM cliente AS c
        EXCEPT
        SELECT cliente_id, nombre_completo, pedidos, total_facturado
        FROM v_reporte_ventas_cliente
    )
) AS diferencias;

INSERT INTO tp5_conteos
SELECT 'v_reporte_ventas_cliente',
    (SELECT count(*) FROM v_reporte_ventas_cliente),
    (SELECT count(*) FROM cliente);

-- v_detalle_pedido_producto --------------------------------------------------

INSERT INTO tp5_equivalencia
SELECT 'v_detalle_pedido_producto', count(*)
FROM (
    (
        SELECT id_pedido, id_producto, producto, cantidad, precio_unitario, subtotal
        FROM v_detalle_pedido_producto
        EXCEPT
        SELECT dp.id_pedido, dp.id_producto, pr.nombre,
               dp.cantidad, dp.precio_unitario, dp.subtotal
        FROM detalle_pedido AS dp
        JOIN producto AS pr ON pr.id = dp.id_producto
    )
    UNION ALL
    (
        SELECT dp.id_pedido, dp.id_producto, pr.nombre,
               dp.cantidad, dp.precio_unitario, dp.subtotal
        FROM detalle_pedido AS dp
        JOIN producto AS pr ON pr.id = dp.id_producto
        EXCEPT
        SELECT id_pedido, id_producto, producto, cantidad, precio_unitario, subtotal
        FROM v_detalle_pedido_producto
    )
) AS diferencias;

INSERT INTO tp5_conteos
SELECT 'v_detalle_pedido_producto',
    (SELECT count(*) FROM v_detalle_pedido_producto),
    (SELECT count(*) FROM detalle_pedido AS dp
        JOIN producto AS pr ON pr.id = dp.id_producto);

-- v_usuario_publico -----------------------------------------------------------

INSERT INTO tp5_equivalencia
SELECT 'v_usuario_publico', count(*)
FROM (
    (
        SELECT id, nombre, apellido, mail, celular, rol, created_at
        FROM v_usuario_publico
        EXCEPT
        SELECT id, nombre, apellido, mail, celular, rol, created_at
        FROM usuario
        WHERE eliminado = FALSE
    )
    UNION ALL
    (
        SELECT id, nombre, apellido, mail, celular, rol, created_at
        FROM usuario
        WHERE eliminado = FALSE
        EXCEPT
        SELECT id, nombre, apellido, mail, celular, rol, created_at
        FROM v_usuario_publico
    )
) AS diferencias;

INSERT INTO tp5_conteos
SELECT 'v_usuario_publico',
    (SELECT count(*) FROM v_usuario_publico),
    (SELECT count(*) FROM usuario WHERE eliminado = FALSE);

-- v_pedido_cliente --------------------------------------------------------------
-- NOTA DE CORRECCION: esta comparacion estaba sin los parentesis que
-- separan las dos mitades del EXCEPT bidireccional. Sin ellos, UNION ALL
-- y EXCEPT se asocian a izquierda con la misma precedencia y la
-- expresion se evaluaba como ((A EXCEPT B) UNION ALL B) EXCEPT A, que
-- algebraicamente equivale a "B EXCEPT A" solamente: detecta filas que
-- estan en la consulta manual y faltan en la vista, pero NO detecta
-- filas que la vista tenga de mas. Corregido para que sea el mismo
-- patron bidireccional que las demas vistas de este archivo.

INSERT INTO tp5_equivalencia
SELECT 'v_pedido_cliente', count(*)
FROM (
    (
        SELECT pedido_id, fecha_hora, forma_pago, estado,
               cliente_id, nombre_completo, email
        FROM v_pedido_cliente
        EXCEPT
        SELECT p.id, p.fecha_hora, p.forma_pago, p.estado,
               c.id, c.nombre_completo, c.email
        FROM pedido AS p
        JOIN cliente AS c ON c.id = p.id_cliente
    )
    UNION ALL
    (
        SELECT p.id, p.fecha_hora, p.forma_pago, p.estado,
               c.id, c.nombre_completo, c.email
        FROM pedido AS p
        JOIN cliente AS c ON c.id = p.id_cliente
        EXCEPT
        SELECT pedido_id, fecha_hora, forma_pago, estado,
               cliente_id, nombre_completo, email
        FROM v_pedido_cliente
    )
) AS diferencias;

INSERT INTO tp5_conteos
SELECT 'v_pedido_cliente',
    (SELECT count(*) FROM v_pedido_cliente),
    (SELECT count(*) FROM pedido AS p JOIN cliente AS c ON c.id = p.id_cliente);

-- v_pedido_usuario --------------------------------------------------------------

INSERT INTO tp5_equivalencia
SELECT 'v_pedido_usuario', count(*)
FROM (
    (
     SELECT pedido_id, fecha_hora, forma_pago, estado,
         usuario_id, nombre, apellido, mail
     FROM v_pedido_usuario
     EXCEPT
     SELECT p.id, p.fecha_hora, p.forma_pago, p.estado,
         u.id, u.nombre, u.apellido, u.mail
     FROM pedido AS p
     JOIN cliente AS c ON c.id = p.id_cliente
     JOIN usuario AS u ON lower(u.mail) = lower(c.email)
     WHERE u.eliminado = FALSE
    )
    UNION ALL
    (
     SELECT p.id, p.fecha_hora, p.forma_pago, p.estado,
         u.id, u.nombre, u.apellido, u.mail
     FROM pedido AS p
     JOIN cliente AS c ON c.id = p.id_cliente
     JOIN usuario AS u ON lower(u.mail) = lower(c.email)
     WHERE u.eliminado = FALSE
     EXCEPT
     SELECT pedido_id, fecha_hora, forma_pago, estado,
         usuario_id, nombre, apellido, mail
     FROM v_pedido_usuario
    )
) AS diferencias;

INSERT INTO tp5_conteos
SELECT 'v_pedido_usuario',
    (SELECT count(*) FROM v_pedido_usuario),
    (SELECT count(*) FROM pedido AS p
        JOIN cliente AS c ON c.id = p.id_cliente
        JOIN usuario AS u ON lower(u.mail) = lower(c.email)
        WHERE u.eliminado = FALSE);

-- Verificacion final ------------------------------------------------------------

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM tp5_equivalencia WHERE diferencias <> 0) THEN
        RAISE EXCEPTION 'La verificacion de equivalencia (EXCEPT) fallo: %',
            (SELECT string_agg(vista || '=' || diferencias::text, ', ')
             FROM tp5_equivalencia WHERE diferencias <> 0);
    END IF;
    IF EXISTS (SELECT 1 FROM tp5_conteos WHERE conteo_vista <> conteo_manual) THEN
        RAISE EXCEPTION 'La verificacion de conteo (count(*)) fallo: %',
            (SELECT string_agg(vista || ' vista=' || conteo_vista::text
                                || ' manual=' || conteo_manual::text, ', ')
             FROM tp5_conteos WHERE conteo_vista <> conteo_manual);
    END IF;
END
$$;

SELECT e.vista, e.diferencias, c.conteo_vista, c.conteo_manual
FROM tp5_equivalencia AS e
JOIN tp5_conteos AS c ON c.vista = e.vista
ORDER BY e.vista;
