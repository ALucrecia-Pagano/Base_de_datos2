-- ============================================================================
-- TRABAJO PRÁCTICO N.º 3 - OPTIMIZACIÓN Y PERFORMANCE DE CONSULTAS
-- Archivo: parte1_carga_masiva/seed_masivo.sql
-- Motor: PostgreSQL 17
-- Adaptación del script Genera_registros.sql provisto por la cátedra al
-- esquema real de FoodStore (TP1). Mapeo aplicado:
--   usuario                     -> cliente
--   usuario.nombre + apellido   -> cliente.nombre_completo
--   usuario.mail                -> cliente.email
--   usuario.celular             -> cliente.telefono
--   usuario.contrasena          -> (no existe en este esquema, se omite)
--   producto.categoria_id       -> producto.id_categoria
--   producto.precio             -> producto.precio_lista
--   pedido.usuario_id           -> pedido.id_cliente
--   pedido.fecha (DATE)         -> pedido.fecha_hora (TIMESTAMPTZ)
--   detalle_pedido.producto_id/pedido_id -> id_producto / id_pedido
--   estado: 'CONFIRMADO'->'EN_PREPARACION', 'TERMINADO'->'ENTREGADO'
--   precio_unitario: sin trigger trg_subtotal en este esquema, se completa
--                     explícitamente con el precio_lista del producto elegido
-- ============================================================================
BEGIN;

-- 1) Productos: 50.000 filas repartidas entre las categorías existentes
INSERT INTO producto (nombre, precio_lista, descripcion, stock, id_categoria)
SELECT 'Producto ' || i,
       (random() * 4500 + 500)::numeric(10,2),
       'Producto generado para prueba de carga',
       (random() * 200)::int,
       (SELECT id FROM categoria ORDER BY random() LIMIT 1)
FROM generate_series(1, 50000) AS s(i);

-- 2) Clientes: 20.000 filas
INSERT INTO cliente (nombre_completo, email, telefono)
SELECT 'Usuario' || i || ' Apellido' || i,
       'usuario' || i || '@test.com',
       '261' || lpad((random()*9999999)::int::text, 7, '0')
FROM generate_series(1, 20000) AS s(i);

-- 3) Pedidos: 200.000 filas, con cliente existente elegido al azar
INSERT INTO pedido (fecha_hora, estado, forma_pago, id_cliente)
SELECT (CURRENT_DATE - (random()*365)::int)::timestamptz,
       (ARRAY['PENDIENTE','EN_PREPARACION','ENTREGADO','CANCELADO']::estado_pedido_enum[])
           [floor(random()*4+1)],
       (ARRAY['TARJETA','TRANSFERENCIA','EFECTIVO']::forma_pago_enum[])
           [floor(random()*3+1)],
       (SELECT id FROM cliente ORDER BY random() LIMIT 1)
FROM generate_series(1, 200000) AS s(i);

-- 4) Detalle de pedido: entre 1 y 4 líneas por pedido, sin repetir producto
INSERT INTO detalle_pedido (cantidad, id_producto, id_pedido, precio_unitario)
SELECT cantidad, id_producto, id_pedido, precio_lista
FROM (
    SELECT p.id AS id_pedido, pr.id_producto, pr.precio_lista,
           (random()*3 + 1)::int AS cantidad,
           row_number() OVER (PARTITION BY p.id ORDER BY random()) AS rn,
           (1 + floor(random()*4))::int AS n_lineas
    FROM pedido p
    CROSS JOIN LATERAL (
        SELECT id AS id_producto, precio_lista
        FROM producto
        ORDER BY random() LIMIT 4
    ) pr
) sub
WHERE rn <= n_lineas
ON CONFLICT (id_pedido, id_producto) DO NOTHING;

COMMIT;

ANALYZE producto; ANALYZE cliente; ANALYZE pedido; ANALYZE detalle_pedido;
