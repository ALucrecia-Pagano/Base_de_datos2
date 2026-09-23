-- Medicion reproducible del candidato BRIN para Q4.
-- La creacion del indice y la medicion se revierten al finalizar.
\set ON_ERROR_STOP on
BEGIN;
CREATE INDEX idx_pedido_fecha_hora_brin_tp5
    ON pedido USING BRIN (fecha_hora)
    WITH (pages_per_range = 32);
ANALYZE pedido;
EXPLAIN (ANALYZE, BUFFERS)
WITH ventas_producto AS (
    SELECT cat.id AS id_categoria, cat.nombre AS categoria,
           p.id AS id_producto, p.nombre AS producto,
           SUM(dp.cantidad) AS unidades_vendidas,
           SUM(dp.subtotal) AS facturacion_producto
    FROM categoria AS cat
    JOIN producto AS p ON p.id_categoria = cat.id
    JOIN detalle_pedido AS dp ON dp.id_producto = p.id
    JOIN pedido AS ped ON ped.id = dp.id_pedido
    WHERE ped.estado <> 'CANCELADO'
      AND ped.fecha_hora >= now() - interval '6 months'
      AND cat.activo = TRUE
      AND p.activo = TRUE
    GROUP BY cat.id, cat.nombre, p.id, p.nombre
), ranking AS (
    SELECT categoria, producto, unidades_vendidas,
           facturacion_producto,
           ROUND(100.0 * facturacion_producto /
                 SUM(facturacion_producto) OVER (PARTITION BY id_categoria), 2)
                 AS pct_de_su_categoria,
           RANK() OVER (
               PARTITION BY id_categoria
               ORDER BY facturacion_producto DESC
           ) AS ranking_en_categoria
    FROM ventas_producto
)
SELECT *
FROM ranking
WHERE ranking_en_categoria <= 3
ORDER BY categoria, ranking_en_categoria;
ROLLBACK;
