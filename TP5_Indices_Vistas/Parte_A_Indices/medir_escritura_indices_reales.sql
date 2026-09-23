-- Medicion del costo de escritura de los indices ACEPTADOS EN FIRME de
-- este TP (no de un indice temporal de control ajeno al TP).
--
-- Tras el Caso 3 (ver indices.sql y informe_mediciones.md), el unico
-- indice que queda aceptado en firme es idx_producto_categoria_precio_activo
-- sobre producto. idx_pedido_fecha_hora_btree fue descartado por la
-- remedicion de 3 rondas (Caso 3); por eso este script mide sobre
-- producto, no sobre pedido/detalle_pedido -- ninguno de los dos tiene
-- hoy un indice nuevo aceptado de este TP.
--
-- 3 rondas intercaladas, DROP/CREATE del indice real dentro de
-- transacciones, \timing (no time de consola).
\set ON_ERROR_STOP on
\timing on

\echo '=== RONDA 1 - ANTES (sin idx_producto_categoria_precio_activo) ==='
BEGIN;
DROP INDEX idx_producto_categoria_precio_activo;
COMMIT;
BEGIN;
INSERT INTO producto (nombre, id_categoria, precio_lista, stock, activo)
SELECT
    'TP5-escritura-' || gs,
    (ARRAY(SELECT id FROM categoria ORDER BY id))[1 + (gs % (SELECT count(*) FROM categoria))],
    1000 + gs,
    10,
    TRUE
FROM generate_series(1, 500) AS gs;
ROLLBACK;

\echo '=== RONDA 1 - DESPUES (con idx_producto_categoria_precio_activo) ==='
BEGIN;
CREATE INDEX idx_producto_categoria_precio_activo
    ON producto (id_categoria, precio_lista DESC)
    WHERE activo = TRUE;
COMMIT;
BEGIN;
INSERT INTO producto (nombre, id_categoria, precio_lista, stock, activo)
SELECT
    'TP5-escritura-' || gs,
    (ARRAY(SELECT id FROM categoria ORDER BY id))[1 + (gs % (SELECT count(*) FROM categoria))],
    1000 + gs,
    10,
    TRUE
FROM generate_series(1, 500) AS gs;
ROLLBACK;

\echo '=== RONDA 2 - ANTES (sin idx_producto_categoria_precio_activo) ==='
BEGIN;
DROP INDEX idx_producto_categoria_precio_activo;
COMMIT;
BEGIN;
INSERT INTO producto (nombre, id_categoria, precio_lista, stock, activo)
SELECT
    'TP5-escritura-' || gs,
    (ARRAY(SELECT id FROM categoria ORDER BY id))[1 + (gs % (SELECT count(*) FROM categoria))],
    1000 + gs,
    10,
    TRUE
FROM generate_series(1, 500) AS gs;
ROLLBACK;

\echo '=== RONDA 2 - DESPUES (con idx_producto_categoria_precio_activo) ==='
BEGIN;
CREATE INDEX idx_producto_categoria_precio_activo
    ON producto (id_categoria, precio_lista DESC)
    WHERE activo = TRUE;
COMMIT;
BEGIN;
INSERT INTO producto (nombre, id_categoria, precio_lista, stock, activo)
SELECT
    'TP5-escritura-' || gs,
    (ARRAY(SELECT id FROM categoria ORDER BY id))[1 + (gs % (SELECT count(*) FROM categoria))],
    1000 + gs,
    10,
    TRUE
FROM generate_series(1, 500) AS gs;
ROLLBACK;

\echo '=== RONDA 3 - ANTES (sin idx_producto_categoria_precio_activo) ==='
BEGIN;
DROP INDEX idx_producto_categoria_precio_activo;
COMMIT;
BEGIN;
INSERT INTO producto (nombre, id_categoria, precio_lista, stock, activo)
SELECT
    'TP5-escritura-' || gs,
    (ARRAY(SELECT id FROM categoria ORDER BY id))[1 + (gs % (SELECT count(*) FROM categoria))],
    1000 + gs,
    10,
    TRUE
FROM generate_series(1, 500) AS gs;
ROLLBACK;

\echo '=== RONDA 3 - DESPUES (con idx_producto_categoria_precio_activo) ==='
BEGIN;
CREATE INDEX idx_producto_categoria_precio_activo
    ON producto (id_categoria, precio_lista DESC)
    WHERE activo = TRUE;
COMMIT;
BEGIN;
INSERT INTO producto (nombre, id_categoria, precio_lista, stock, activo)
SELECT
    'TP5-escritura-' || gs,
    (ARRAY(SELECT id FROM categoria ORDER BY id))[1 + (gs % (SELECT count(*) FROM categoria))],
    1000 + gs,
    10,
    TRUE
FROM generate_series(1, 500) AS gs;
ROLLBACK;

\echo '=== Verificacion: el indice quedo aplicado en firme al terminar ==='
SELECT indexname FROM pg_indexes WHERE indexname = 'idx_producto_categoria_precio_activo';
