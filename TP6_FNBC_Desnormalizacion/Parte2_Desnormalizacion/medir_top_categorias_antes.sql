\set ON_ERROR_STOP on

BEGIN READ ONLY;

DO $$
BEGIN
    IF current_database() <> 'foodstore_copia_trabajo' THEN
        RAISE EXCEPTION
            'Base no permitida: %. Conectarse a foodstore_copia_trabajo.',
            current_database();
    END IF;
END;
$$;

-- Fecha histórica reproducible: 2026-06-25 en America/Buenos_Aires.
-- Sustituye CURRENT_DATE porque la carga no contiene pedidos de hoy.
-- pedido y detalle_pedido no tienen columnas eliminado: se consideran
-- todos los registros existentes del día, sin filtros por estado o activo.

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

EXPLAIN (ANALYZE, BUFFERS)
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

ROLLBACK;
