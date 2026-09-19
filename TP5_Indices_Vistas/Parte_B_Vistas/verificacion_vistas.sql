-- TP5 - Verificacion de Partes B y C.
-- Las sentencias de escritura/DDL deben ejecutarse en la base de trabajo.

-- 1) La vista publica no debe exponer la columna de contrasena.
SELECT column_name
FROM information_schema.columns
WHERE table_name = 'v_usuario_publico'
ORDER BY ordinal_position;

-- 2) La vista materializada debe existir y tener datos despues de la carga.
SELECT * FROM mv_resumen_ventas_categoria_mes
ORDER BY facturacion_total DESC, id_categoria;

-- 3) Actualizacion de la vista materializada.
REFRESH MATERIALIZED VIEW mv_resumen_ventas_categoria_mes;

-- 4) Prueba conceptual de permisos. Ejecutar como propietario o superusuario.
SET ROLE tp5_reportes;
SELECT * FROM v_usuario_publico LIMIT 5;
SELECT * FROM v_reporte_ventas_cliente LIMIT 5;
SELECT * FROM v_catalogo_productos LIMIT 5;
SELECT * FROM v_detalle_pedido_producto LIMIT 5;
SELECT * FROM mv_resumen_ventas_categoria_mes LIMIT 5;
-- Esta consulta debe fallar por falta de privilegios:
-- SELECT * FROM usuario;
RESET ROLE;
