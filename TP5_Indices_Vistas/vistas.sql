-- TP5 - Parte B: vistas de reportes y exposicion controlada
-- Ejecutar despues de schema.sql y usuarios.sql.

CREATE OR REPLACE VIEW v_usuario_publico AS
SELECT
    id,
    nombre,
    apellido,
    mail,
    celular,
    rol,
    created_at
FROM usuario
WHERE eliminado = FALSE;

CREATE OR REPLACE VIEW v_reporte_ventas_cliente AS
SELECT
    c.id AS cliente_id,
    c.nombre_completo,
    COUNT(DISTINCT p.id) AS pedidos,
    COALESCE(SUM(dp.subtotal), 0)::NUMERIC(12, 2) AS total_facturado
FROM cliente AS c
LEFT JOIN pedido AS p
    ON p.id_cliente = c.id
   AND p.estado <> 'CANCELADO'
LEFT JOIN detalle_pedido AS dp
    ON dp.id_pedido = p.id
GROUP BY c.id, c.nombre_completo;

CREATE OR REPLACE VIEW v_catalogo_productos AS
SELECT
    p.id AS producto_id,
    p.nombre AS producto,
    c.nombre AS categoria,
    p.precio_lista,
    p.stock
FROM producto AS p
JOIN categoria AS c ON c.id = p.id_categoria
WHERE p.activo = TRUE
  AND c.activo = TRUE;

COMMENT ON VIEW v_usuario_publico IS 'Vista segura: omite deliberadamente usuario.contrasena.';
COMMENT ON VIEW v_reporte_ventas_cliente IS 'Reporte de ventas por cliente sin exponer credenciales.';
COMMENT ON VIEW v_catalogo_productos IS 'Catalogo operativo de productos y categorias activas.';
