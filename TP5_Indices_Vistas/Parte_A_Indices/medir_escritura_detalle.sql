-- Medicion reproducible del costo de escritura en detalle_pedido.
-- Ejecutar en foodstore_tp3_carga sobre la copia de trabajo autorizada.
-- La prueba usa un indice temporal sobre la tabla medida y lo revierte.
\set ON_ERROR_STOP on
\timing on

BEGIN;
DROP INDEX IF EXISTS tp5_medicion_detalle_cantidad_idx;
COMMIT;

CREATE TEMP TABLE tp5_muestra_detalle (
    id_pedido bigint NOT NULL,
    id_producto bigint NOT NULL,
    precio_unitario numeric(10, 2) NOT NULL,
    PRIMARY KEY (id_pedido, id_producto)
);

INSERT INTO tp5_muestra_detalle (id_pedido, id_producto, precio_unitario)
SELECT p.id, pr.id, pr.precio_lista
FROM pedido AS p
CROSS JOIN LATERAL (
    SELECT id, precio_lista
    FROM producto
    ORDER BY id
    OFFSET ((p.id - 1) % 500)::integer
    LIMIT 1
) AS pr
WHERE NOT EXISTS (
    SELECT 1
    FROM detalle_pedido AS existente
    WHERE existente.id_pedido = p.id AND existente.id_producto = pr.id
)
ORDER BY p.id
LIMIT 500;

DO $$
BEGIN
    IF (SELECT count(*) FROM tp5_muestra_detalle) <> 500 THEN
        RAISE EXCEPTION 'No se pudo construir una muestra de 500 filas';
    END IF;
END
$$;

-- Cada ronda alterna el estado del indice. El tiempo mostrado por \timing
-- corresponde al INSERT de 500 filas y no incluye crear ni eliminar el indice.
BEGIN;
\echo 'RONDA 1 - ANTES: INSERT sin indice de prueba'
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT id_pedido, id_producto, 1, precio_unitario
FROM tp5_muestra_detalle;
ROLLBACK;

BEGIN;
CREATE INDEX tp5_medicion_detalle_cantidad_idx
    ON detalle_pedido (cantidad);
COMMIT;
BEGIN;
\echo 'RONDA 1 - DESPUES: INSERT con indice de prueba'
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT id_pedido, id_producto, 1, precio_unitario
FROM tp5_muestra_detalle;
ROLLBACK;
BEGIN;
DROP INDEX tp5_medicion_detalle_cantidad_idx;
COMMIT;

BEGIN;
\echo 'RONDA 2 - ANTES: INSERT sin indice de prueba'
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT id_pedido, id_producto, 1, precio_unitario
FROM tp5_muestra_detalle;
ROLLBACK;

BEGIN;
CREATE INDEX tp5_medicion_detalle_cantidad_idx
    ON detalle_pedido (cantidad);
COMMIT;
BEGIN;
\echo 'RONDA 2 - DESPUES: INSERT con indice de prueba'
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT id_pedido, id_producto, 1, precio_unitario
FROM tp5_muestra_detalle;
ROLLBACK;
BEGIN;
DROP INDEX tp5_medicion_detalle_cantidad_idx;
COMMIT;

BEGIN;
\echo 'RONDA 3 - ANTES: INSERT sin indice de prueba'
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT id_pedido, id_producto, 1, precio_unitario
FROM tp5_muestra_detalle;
ROLLBACK;

BEGIN;
CREATE INDEX tp5_medicion_detalle_cantidad_idx
    ON detalle_pedido (cantidad);
COMMIT;
BEGIN;
\echo 'RONDA 3 - DESPUES: INSERT con indice de prueba'
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT id_pedido, id_producto, 1, precio_unitario
FROM tp5_muestra_detalle;
ROLLBACK;
BEGIN;
DROP INDEX tp5_medicion_detalle_cantidad_idx;
COMMIT;
