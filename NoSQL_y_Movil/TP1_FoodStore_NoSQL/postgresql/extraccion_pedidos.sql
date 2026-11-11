-- FoodStore, Unidad 7. Extracción ejecutada manualmente por Amanda y documentada.
-- Registro: TP1_FoodStore_NoSQL/docs/resultado_migracion.md. El asistente no ejecutó los motores.
-- Origen de la extracción documentada: foodstore_dev, esquema public, pedidos 1 a 5.
-- Destino de la migración documentada: foodstore_unidad7.pedidos; este SQL no crea ni carga MongoDB.
-- Referencias PREVIAS de Amanda: cinco pedidos, siete detalles, ENTREGADO.
-- Los VALUES son referencias para contrastar, nunca resultados observados.
-- No se extraen datos personales del cliente ni observaciones (excluidas).
-- El alias es sintético; el nombre del producto es su descripción actual.
-- JSON de intercambio: IDs e importes como texto; NO es BSON/Extended JSON.
-- Convertir posteriormente a Long, Int32, Date y Decimal128 requiere revisión.
-- Ejecutar completo en una sesión nueva de psql, sin transacción previa.
-- Solo funciones incorporadas: sin DDL, DML, auxiliares ni extensiones.

BEGIN ISOLATION LEVEL REPEATABLE READ, READ ONLY;

WITH
-- Clientes esperados según información previa, no extraídos de datos personales.
objetivo(id, cliente_esperado) AS (
  VALUES (1::bigint, 1::bigint), (2, 2), (3, 1), (4, 3), (5, 2)
),
esperado(id_pedido, id_producto, cantidad, precio, subtotal) AS (
  VALUES
    (1::bigint, 1::bigint, 2, 1000.00::numeric, 2000.00::numeric),
    (1, 3, 1, 800.00, 800.00),
    (2, 2, 1, 1500.00, 1500.00),
    (3, 1, 3, 1050.00, 3150.00),
    (4, 2, 2, 1500.00, 3000.00),
    (4, 3, 4, 800.00, 3200.00),
    (5, 1, 1, 1050.00, 1050.00)
),
-- LEFT JOIN conserva los pedidos esperados aunque falten pedidos o clientes.
pedidos AS (
  SELECT o.id AS id_esperado, o.cliente_esperado,
    p.id, p.id_cliente, p.fecha_hora, p.forma_pago, p.estado,
    c.id AS cliente_encontrado
  FROM objetivo AS o
  LEFT JOIN public.pedido AS p
    ON p.id = o.id AND current_database() = 'foodstore_dev'
  LEFT JOIN public.cliente AS c ON c.id = p.id_cliente
),
-- Se lee detalle independientemente de pedido: no oculta detalles huérfanos.
detalles AS (
  SELECT d.id_pedido, d.id_producto, d.cantidad,
    d.precio_unitario::numeric AS precio,
    d.subtotal::numeric AS subtotal_origen,
    d.cantidad::numeric * d.precio_unitario::numeric AS subtotal_calculado,
    pr.id AS producto_encontrado, pr.nombre AS nombre_producto,
    count(*) OVER (PARTITION BY d.id_pedido, d.id_producto) AS repeticiones
  FROM public.detalle_pedido AS d
  LEFT JOIN public.producto AS pr ON pr.id = d.id_producto
  WHERE d.id_pedido IN (1, 2, 3, 4, 5)
    AND current_database() = 'foodstore_dev'
),
control_pedidos AS (
  SELECT id_esperado::text AS id_esperado, id::text AS id_origen,
    id_cliente::text AS id_cliente, cliente_esperado::text AS cliente_esperado,
    id IS NOT NULL AS pedido_existe,
    cliente_encontrado IS NOT NULL AS cliente_existe,
    COALESCE(id_cliente = cliente_esperado, false) AS cliente_coincide,
    forma_pago, estado,
    COALESCE(estado = 'ENTREGADO', false) AS estado_coincide_referencia,
    CASE WHEN isfinite(fecha_hora) THEN
      to_char(fecha_hora AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
      ELSE fecha_hora::text END AS fecha_utc,
    COALESCE(isfinite(fecha_hora), false) AS fecha_finita,
    COALESCE(fecha_hora <> date_trunc('milliseconds', fecha_hora, 'UTC'),
      false) AS tiene_submilisegundos,
    pg_typeof(id)::text AS tipo_id,
    pg_typeof(id_cliente)::text AS tipo_id_cliente,
    pg_typeof(fecha_hora)::text AS tipo_fecha
  FROM pedidos
),
-- FULL JOIN hace visibles tanto líneas faltantes como líneas no esperadas.
control_detalles AS (
  SELECT COALESCE(e.id_pedido, d.id_pedido)::text AS id_pedido,
    COALESCE(e.id_producto, d.id_producto)::text AS id_producto,
    e.id_pedido IS NOT NULL AS linea_esperada,
    d.id_pedido IS NOT NULL AS linea_encontrada,
    d.producto_encontrado IS NOT NULL AS producto_existe,
    d.nombre_producto, d.cantidad, e.cantidad AS cantidad_esperada,
    d.precio::text AS precio_historico, e.precio::text AS precio_esperado,
    d.subtotal_origen::text AS subtotal_origen,
    d.subtotal_calculado::text AS subtotal_calculado,
    e.subtotal::text AS subtotal_esperado,
    COALESCE(d.repeticiones, 0) AS repeticiones,
    COALESCE(d.cantidad > 0 AND d.cantidad <= 2147483647
      AND d.cantidad::numeric = trunc(d.cantidad::numeric), false) AS cantidad_ok,
    COALESCE(d.precio >= 0 AND d.subtotal_origen >= 0
      AND d.precio::text NOT IN ('NaN', 'Infinity', '-Infinity')
      AND d.subtotal_origen::text NOT IN ('NaN', 'Infinity', '-Infinity'),
      false) AS importes_ok,
    COALESCE(d.subtotal_origen = d.subtotal_calculado, false) AS formula_ok,
    COALESCE(d.cantidad = e.cantidad AND d.precio = e.precio
      AND d.subtotal_origen = e.subtotal, false) AS coincide_referencia,
    pg_typeof(d.id_producto)::text AS tipo_id_producto,
    pg_typeof(d.cantidad)::text AS tipo_cantidad
  FROM esperado AS e
  FULL JOIN detalles AS d
    ON d.id_pedido = e.id_pedido AND d.id_producto = e.id_producto
),
agrupados AS (
  SELECT id_pedido,
    sum(subtotal_calculado)::numeric AS total,
    jsonb_agg(jsonb_build_object(
      'id_producto', id_producto::text,
      'nombre_producto', nombre_producto,
      'cantidad', cantidad,
      'precio_unitario', precio::text,
      'subtotal', subtotal_calculado::text
    ) ORDER BY id_producto) AS lineas
  FROM detalles
  GROUP BY id_pedido
),
controles AS (
  SELECT
    current_database() = 'foodstore_dev' AS base_correcta,
    (SELECT count(*) = 5 AND count(DISTINCT id) = 5
      FROM pedidos WHERE id IS NOT NULL) AS cinco_pedidos,
    (SELECT count(*) = 7 FROM detalles) AS siete_detalles,
    (SELECT COALESCE(bool_and(pedido_existe AND cliente_existe
      AND cliente_coincide AND estado_coincide_referencia), false)
      FROM control_pedidos) AS pedidos_ok,
    (SELECT COALESCE(bool_and(fecha_finita AND NOT tiene_submilisegundos), false)
      FROM control_pedidos) AS fechas_compatibles_bson_date,
    (SELECT COALESCE(bool_and(linea_esperada AND linea_encontrada
      AND producto_existe AND repeticiones = 1 AND cantidad_ok
      AND importes_ok AND formula_ok AND coincide_referencia), false)
      FROM control_detalles) AS detalles_ok
),
habilitacion AS (
  SELECT *, base_correcta AND cinco_pedidos AND siete_detalles
    AND pedidos_ok AND fechas_compatibles_bson_date AND detalles_ok AS extraer
  FROM controles
)
-- Un informe JSON; extracción separada de controles y referencias previas.
-- Si falla un control, extraccion queda null: revisar, no truncar ni corregir datos.
SELECT jsonb_pretty(jsonb_build_object(
  'contexto', jsonb_build_object(
    'base', current_database(),
    'esquema', 'public',
    'version_servidor', version(),
    'server_version_num', current_setting('server_version_num'),
    'aislamiento', current_setting('transaction_isolation'),
    'solo_lectura', current_setting('transaction_read_only'),
    'fecha_registro_utc', to_char(transaction_timestamp() AT TIME ZONE 'UTC',
      'YYYY-MM-DD"T"HH24:MI:SS.US"Z"')
  ),
  'referencias_previas', 'Amanda: 5 pedidos y 7 detalles; no son resultados nuevos',
  'controles', to_jsonb(h),
  'pedidos_control', (SELECT jsonb_agg(to_jsonb(cp) ORDER BY id_esperado::bigint)
    FROM control_pedidos AS cp),
  'detalles_control', (SELECT jsonb_agg(to_jsonb(cd)
    ORDER BY id_pedido::bigint, id_producto::bigint)
    FROM control_detalles AS cd),
  'totales_control', (SELECT jsonb_agg(jsonb_build_object(
      'id_pedido', o.id::text,
      'total_calculado', a.total::text,
      'total_esperado', (SELECT sum(e.subtotal)::numeric::text
        FROM esperado AS e WHERE e.id_pedido = o.id),
      'lineas_encontradas', (SELECT count(*) FROM detalles AS d
        WHERE d.id_pedido = o.id)
    ) ORDER BY o.id)
    FROM objetivo AS o
    LEFT JOIN agrupados AS a ON a.id_pedido = o.id),
  'estado', CASE
    WHEN NOT base_correcta THEN 'BLOQUEADA: base distinta de foodstore_dev'
    WHEN NOT fechas_compatibles_bson_date THEN
      'BLOQUEADA: revisar fechas; BSON Date no conserva submilisegundos'
    WHEN NOT extraer THEN 'BLOQUEADA: revisar controles y diferencias con referencias'
    ELSE 'Extracción de intercambio; pendiente de revisión y conversión BSON' END,
  'extraccion', CASE WHEN extraer THEN (
    SELECT jsonb_agg(jsonb_build_object(
      '_id', p.id::text,
      'fecha_hora', to_char(p.fecha_hora AT TIME ZONE 'UTC',
        'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'),
      'forma_pago', p.forma_pago,
      'estado', p.estado,
      'cliente', jsonb_build_object('id', p.id_cliente::text,
        'alias', 'Cliente ' || p.id_cliente::text),
      'lineas', a.lineas,
      'total', a.total::text
    ) ORDER BY p.id)
    FROM pedidos AS p
    LEFT JOIN agrupados AS a ON a.id_pedido = p.id
  ) ELSE NULL END
)) AS informe_extraccion
FROM habilitacion AS h;

ROLLBACK;
