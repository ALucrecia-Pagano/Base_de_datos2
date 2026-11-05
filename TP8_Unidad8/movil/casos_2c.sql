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

-- Instantánea nueva: el servidor subió el precio del producto 1 (C2) y dio
-- de baja el producto 3 (C4). Se generó con postgresql/preparar_casos_2c.sql.
DELETE FROM snapshot_servidor_import;
.import --csv --skip 1 TP8_Unidad8/movil/servidor_snapshot_2c.csv snapshot_servidor_import
.read TP8_Unidad8/movil/recargar_snapshot.sql

-- C4: al recargar el catálogo, el producto 3 ya no aparece...
SELECT id, nombre, precio_centavos, stock_visto
FROM producto_cache
WHERE disponible = 1
  AND eliminado = 0
  AND stock_visto > 0
ORDER BY id;

-- ...pero su fila sigue en la tablet (baja lógica, no borrado).
SELECT id, nombre, disponible, eliminado, fecha_copia
FROM producto_cache
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

-- C2: el cliente acepta el precio nuevo. Se actualiza el precio del borrador
-- y se envía una solicitud nueva (UUID distinto).
UPDATE item_borrador
SET precio_centavos_visto = 110000
WHERE id_local = 'c2-original'
  AND producto_id = 1;

INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c2-solicitud-2', 'c2-original', 'PENDIENTE', NULL);

-- C6: el mismo UUID no puede reenviarse y la solicitud ya aprobada no se reevalúa.
.read TP8_Unidad8/movil/semaforo.sql
INSERT INTO cola_sync (solicitud_uuid, id_local, estado, motivo)
VALUES ('c5-solicitud', 'c5-sin-cambios', 'PENDIENTE', NULL);

-- C6: repetir la simulación no reevalúa lo que ya no está PENDIENTE.
.read TP8_Unidad8/movil/semaforo.sql

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
