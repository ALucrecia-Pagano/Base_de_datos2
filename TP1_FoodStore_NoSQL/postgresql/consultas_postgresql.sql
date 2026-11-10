-- FoodStore — Unidad 7 NoSQL. Responsable: Mateo, consigna 5.
-- Lectura únicamente. Conectarse a foodstore_dev, esquema public.
-- El lote explícito evita comparar contra pedidos ajenos a la migración.

-- b) Estado equivalente a consultas_mongodb.js.
WITH parametros AS (
    SELECT 'ENTREGADO'::text AS estado
),
lote AS (
    SELECT unnest(ARRAY[1, 2, 3, 4, 5]::bigint[]) AS id
)
SELECT p.id, p.estado
FROM public.pedido AS p
JOIN lote ON lote.id = p.id
CROSS JOIN parametros
WHERE p.estado::text = parametros.estado
ORDER BY p.id;

-- c) Producto equivalente a consultas_mongodb.js.
-- Se devuelve una fila por línea coincidente, con cantidad y precio histórico.
WITH parametros AS (
    SELECT 1::bigint AS id_producto
),
lote AS (
    SELECT unnest(ARRAY[1, 2, 3, 4, 5]::bigint[]) AS id
)
SELECT
    p.id AS id_pedido,
    p.estado,
    dp.id_producto,
    dp.cantidad,
    dp.precio_unitario
FROM public.pedido AS p
JOIN lote ON lote.id = p.id
JOIN public.detalle_pedido AS dp ON dp.id_pedido = p.id
CROSS JOIN parametros
WHERE dp.id_producto = parametros.id_producto
ORDER BY p.id, dp.id_producto;
