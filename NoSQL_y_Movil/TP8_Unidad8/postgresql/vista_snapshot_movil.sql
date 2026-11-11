-- Consigna 2.a. Ejecutar únicamente en la copia de pruebas de foodstore_dev.
-- No modifica tablas: crea o reemplaza la vista de lectura para exportación.

CREATE OR REPLACE VIEW v_snapshot_movil AS
SELECT
    p.id,
    p.nombre,
    (p.precio_lista * 100)::bigint AS precio_centavos,
    p.stock::bigint AS stock,
    p.activo AS disponible,
    (NOT p.activo) AS eliminado,
    CURRENT_TIMESTAMP AS fecha_copia
FROM public.producto AS p
ORDER BY p.id;

