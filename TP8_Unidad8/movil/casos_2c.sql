PRAGMA foreign_keys = ON;

-- Esta prueba se ejecuta sobre una copia con la instantánea inicial cargada.
-- Cada solicitud usa un UUID distinto, salvo la repetición intencional de C6.

-- C2: cambio de precio => CONFLICTO.
INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('c2-original', 'operador_demo', 'EFECTIVO', '2026-11-02T21:10:00Z');
INSERT INTO item_borrador (
    id_local, producto_id, cantidad, precio_centavos_visto
) VALUES ('c2-original', 1, 1, 105000);
INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c2-solicitud-1', 'c2-original', 'PENDIENTE', NULL);

UPDATE snapshot_servidor
SET precio_centavos = 110000
WHERE id = 1;

-- C3: stock insuficiente => RECHAZADO.
INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('c3-stock', 'operador_demo', 'TARJETA', '2026-11-02T21:11:00Z');
INSERT INTO item_borrador (
    id_local, producto_id, cantidad, precio_centavos_visto
) VALUES ('c3-stock', 2, 36, 150000);
INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c3-solicitud', 'c3-stock', 'PENDIENTE', NULL);

-- C4: baja lógica => RECHAZADO.
INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('c4-baja', 'operador_demo', 'TRANSFERENCIA', '2026-11-02T21:12:00Z');
INSERT INTO item_borrador (
    id_local, producto_id, cantidad, precio_centavos_visto
) VALUES ('c4-baja', 3, 1, 80000);
INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c4-solicitud', 'c4-baja', 'PENDIENTE', NULL);

UPDATE snapshot_servidor
SET eliminado = 1
WHERE id = 3;

-- C5: sin cambios => SIMULADO_APROBADO.
INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('c5-sin-cambios', 'operador_demo', 'EFECTIVO', '2026-11-02T21:13:00Z');
INSERT INTO item_borrador (
    id_local, producto_id, cantidad, precio_centavos_visto
) VALUES ('c5-sin-cambios', 1, 1, 110000);
INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c5-solicitud', 'c5-sin-cambios', 'PENDIENTE', NULL);

-- Evaluar C2, C3, C4 y C5.
.read TP8_Unidad8/movil/semaforo.sql

-- C2: aceptación del precio actualizado y nueva solicitud aprobable.
UPDATE snapshot_servidor
SET disponible = 1, eliminado = 0
WHERE id = 1;

INSERT INTO pedido_borrador (id_local, usuario, forma_pago, fecha)
VALUES ('c2-aceptado', 'operador_demo', 'EFECTIVO', '2026-11-02T21:14:00Z');
INSERT INTO item_borrador (
    id_local, producto_id, cantidad, precio_centavos_visto
) VALUES ('c2-aceptado', 1, 1, 110000);
INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c2-solicitud-2', 'c2-aceptado', 'PENDIENTE', NULL);

-- C6: el mismo UUID no puede reenviarse y la solicitud ya aprobada no se reevalúa.
.read TP8_Unidad8/movil/semaforo.sql
INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c5-solicitud', 'c5-sin-cambios', 'PENDIENTE', NULL);

-- Resultados resumidos de C2 a C6.
SELECT solicitud_uuid, estado, motivo
FROM cola_sync
WHERE solicitud_uuid IN (
    'c2-solicitud-1',
    'c2-solicitud-2',
    'c3-solicitud',
    'c4-solicitud',
    'c5-solicitud'
)
ORDER BY solicitud_uuid;
