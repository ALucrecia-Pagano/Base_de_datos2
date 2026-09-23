-- Verificacion ejecutable de equivalencia para las vistas de TP5.
-- El script falla si alguna diferencia es distinta de cero.
\set ON_ERROR_STOP on

CREATE TEMP TABLE tp5_equivalencia (
    vista text PRIMARY KEY,
    diferencias bigint NOT NULL
);

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

INSERT INTO tp5_equivalencia
SELECT 'v_pedido_cliente', count(*)
FROM (
    SELECT pedido_id, fecha_hora, forma_pago, estado,
           cliente_id, nombre_completo, email
    FROM v_pedido_cliente
    EXCEPT
    SELECT p.id, p.fecha_hora, p.forma_pago, p.estado,
           c.id, c.nombre_completo, c.email
    FROM pedido AS p
    JOIN cliente AS c ON c.id = p.id_cliente
    UNION ALL
    SELECT p.id, p.fecha_hora, p.forma_pago, p.estado,
           c.id, c.nombre_completo, c.email
    FROM pedido AS p
    JOIN cliente AS c ON c.id = p.id_cliente
    EXCEPT
    SELECT pedido_id, fecha_hora, forma_pago, estado,
           cliente_id, nombre_completo, email
    FROM v_pedido_cliente
) AS diferencias;

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

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM tp5_equivalencia WHERE diferencias <> 0) THEN
        RAISE EXCEPTION 'La verificacion de equivalencia fallo: %',
            (SELECT string_agg(vista || '=' || diferencias::text, ', ')
             FROM tp5_equivalencia WHERE diferencias <> 0);
    END IF;
END
$$;

SELECT vista, diferencias
FROM tp5_equivalencia
ORDER BY vista;
