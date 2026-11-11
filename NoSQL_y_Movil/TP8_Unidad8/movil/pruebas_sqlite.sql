PRAGMA foreign_keys = ON;



INSERT INTO producto_cache(
    id,
    nombre,
    precio_centavos,
    stock_visto,
    disponible,
    eliminado,
    fecha_copia
) VALUES
    (1, 'Muzzarella', 105000, 10, 1, 0, '2026-11-02T18:00:00Z'),
    (2, 'Napolitana', 150000, 8, 1, 0, '2026-11-02T18:00:00Z'),
    (3, 'Coca 1.5L', 80000, 20, 1, 0, '2026-11-02T18:00:00Z'),
    (4, 'Producto retirado', 50000, 0, 0, 1, '2026-11-02T18:00:00Z');

BEGIN;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES (
    '11111111-1111-4111-8111-111111111111',
    'operador_demo',
    'EFECTIVO',
    '2026-11-02T18:05:00Z'
);

INSERT INTO item_borrador (
    id_local,
    producto_id,
    cantidad,
    precio_centavos_visto
) VALUES
    ('11111111-1111-4111-8111-111111111111', 1, 2, 105000),
    ('11111111-1111-4111-8111-111111111111', 3, 1, 80000);

INSERT INTO cola_sync (
    solicitud_uuid,
    id_local,
    estado,
    motivo
)
VALUES (
    '22222222-2222-4222-8222-222222222222',
    '11111111-1111-4111-8111-111111111111',
    'PENDIENTE',
    NULL
);

COMMIT;
-- Comprobación del borrador confirmado.
SELECT
    p.id_local,
    p.forma_pago,
    COUNT(i.producto_id) AS cantidad_items,
    c.estado
FROM pedido_borrador AS p
JOIN item_borrador AS i ON i.id_local = p.id_local
JOIN cola_sync AS c ON c.id_local = p.id_local
WHERE p.id_local = '11111111-1111-4111-8111-111111111111'
GROUP BY p.id_local, p.forma_pago, c.estado;

-- 2. Operación deshecha: no debe persistir ninguna de sus filas.
BEGIN;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES (
    '33333333-3333-4333-8333-333333333333',
    'operador_demo',
    'TARJETA',
    '2026-11-02T18:10:00Z'
);

INSERT INTO item_borrador (
    id_local,
    producto_id,
    cantidad,
    precio_centavos_visto
)
VALUES (
    '33333333-3333-4333-8333-333333333333',
    2,
    1,
    150000
);

ROLLBACK;

SELECT
    (SELECT COUNT(*) FROM pedido_borrador
      WHERE id_local = '33333333-3333-4333-8333-333333333333') AS borradores_revertidos,
    (SELECT COUNT(*) FROM item_borrador
      WHERE id_local = '33333333-3333-4333-8333-333333333333') AS items_revertidos;

-- 3. Caso C1: el catálogo disponible se consulta sin conectarse al servidor.
SELECT id, nombre, precio_centavos, stock_visto
FROM producto_cache
WHERE disponible = 1
  AND eliminado = 0
  AND stock_visto > 0
ORDER BY id;

-- 4. Caso C7.a: cantidad cero. La sentencia debe fallar por CHECK.
-- La transacción contiene una fila válida antes del error y luego se revierte.
BEGIN;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES (
    'c7-cantidad-cero',
    'operador_demo',
    'EFECTIVO',
    '2026-11-02T18:20:00Z'
);

INSERT INTO item_borrador (
    id_local,
    producto_id,
    cantidad,
    precio_centavos_visto
)
VALUES (
    'c7-cantidad-cero',
    2,
    1,
    150000
);

-- La ejecución debe continuar para comprobar que no quedan filas parciales.
INSERT INTO item_borrador (
    id_local,
    producto_id,
    cantidad,
    precio_centavos_visto
)
VALUES (
    'c7-cantidad-cero',
    3,
    0,
    80000
);

ROLLBACK;

SELECT COUNT(*) AS items_con_cantidad_cero
FROM item_borrador
WHERE id_local = 'c7-cantidad-cero';

-- 5. Caso C7.b: producto inexistente. La sentencia debe fallar por FK.
-- También se revierte la fila válida insertada antes del error.
BEGIN;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES (
    'c7-producto-inexistente',
    'operador_demo',
    'EFECTIVO',
    '2026-11-02T18:21:00Z'
);

INSERT INTO item_borrador (
    id_local,
    producto_id,
    cantidad,
    precio_centavos_visto
)
VALUES (
    'c7-producto-inexistente',
    2,
    1,
    150000
);

INSERT INTO item_borrador (
    id_local,
    producto_id,
    cantidad,
    precio_centavos_visto
)
VALUES (
    'c7-producto-inexistente',
    999,
    1,
    100
);

ROLLBACK;

SELECT COUNT(*) AS items_con_producto_inexistente
FROM item_borrador
WHERE id_local = 'c7-producto-inexistente';
