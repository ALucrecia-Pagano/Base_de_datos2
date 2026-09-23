-- Medicion del plan actual de Q1 y Q3 (queries.sql) para el Punto 7 de
-- la auditoria: evaluar si alguna necesita todavia un indice nuevo de
-- este TP, o si ya esta resuelta por un indice de un TP anterior.
\set ON_ERROR_STOP on
\timing on

\echo '=== Q1 (pedidos pendientes) - plan actual ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, fecha_hora, forma_pago, id_cliente
FROM pedido
WHERE estado = 'PENDIENTE'
ORDER BY fecha_hora DESC
LIMIT 50;

\echo '=== Q3 (total facturado por cliente en rango de fechas) - plan actual ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.id, c.nombre_completo, SUM(dp.subtotal) AS total_facturado
FROM cliente c
JOIN pedido p ON p.id_cliente = c.id
JOIN detalle_pedido dp ON dp.id_pedido = p.id
WHERE p.fecha_hora BETWEEN '2025-06-01' AND '2025-12-31'
GROUP BY c.id, c.nombre_completo
ORDER BY total_facturado DESC
LIMIT 20;
