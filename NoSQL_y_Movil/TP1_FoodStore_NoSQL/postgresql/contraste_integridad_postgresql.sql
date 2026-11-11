-- FoodStore - Unidad 7 NoSQL. Consigna 7: contraste de afirmaciones de la IA.
-- Responsable: Lucas. Prueba de laboratorio de integridad en PostgreSQL.
-- Ejecutar SOLO sobre la copia descartable foodstore_restore_test (restaurada
-- desde un respaldo en el TP8). Cada prueba corre dentro de BEGIN ... ROLLBACK:
-- no deja filas guardadas. Cada prueba rechazada debe mostrar un ERROR.
-- Nota: una sentencia INSERT, aunque falle, consume un valor de la secuencia de
-- identidad de pedido; no afecta los datos y la copia es descartable.

\set ON_ERROR_STOP off
\pset pager off

SELECT current_database() = 'foodstore_restore_test' AS destino_ok \gset
\if :destino_ok
\else
  \echo 'DETENIDO: esta prueba solo se ejecuta en foodstore_restore_test.'
  \quit
\endif

\echo '== 0. Estado inicial (copia restaurada) =='
SELECT current_database() AS base,
       (SELECT count(*) FROM pedido) AS pedidos,
       (SELECT count(*) FROM detalle_pedido) AS lineas;

\echo '== 0b. pedido NO tiene columna total; subtotal es columna generada =='
SELECT column_name FROM information_schema.columns
 WHERE table_schema = 'public' AND table_name = 'pedido' ORDER BY ordinal_position;
SELECT column_name, is_generated, generation_expression
  FROM information_schema.columns
 WHERE table_schema = 'public' AND table_name = 'detalle_pedido'
   AND column_name = 'subtotal';

\echo '== 1. Pedido con cliente inexistente: debe fallar (clave foranea) =='
BEGIN;
INSERT INTO pedido (id_cliente, forma_pago) VALUES (999999, 'EFECTIVO');
ROLLBACK;

\echo '== 2. Escribir un subtotal a mano: debe fallar (columna generada) =='
BEGIN;
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario, subtotal)
SELECT (SELECT min(id) FROM pedido), (SELECT min(id) FROM producto), 2, 100.00, 1.00;
ROLLBACK;

\echo '== 3. Cantidad cero: debe fallar (CHECK chk_detalle_cantidad_positiva) =='
BEGIN;
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT (SELECT min(id) FROM pedido), (SELECT min(id) FROM producto), 0, 100.00;
ROLLBACK;

\echo '== 4. Linea con producto inexistente: debe fallar (clave foranea fk_detalle_pedido_producto) =='
BEGIN;
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT (SELECT min(id) FROM pedido), 999999, 1, 100.00;
ROLLBACK;

\echo '== 5. Control positivo: linea valida, el motor calcula el subtotal (2 x 100.00) =='
BEGIN;
WITH nuevo AS (
  INSERT INTO pedido (id_cliente, forma_pago)
  SELECT min(id), 'EFECTIVO' FROM cliente RETURNING id
)
INSERT INTO detalle_pedido (id_pedido, id_producto, cantidad, precio_unitario)
SELECT nuevo.id, (SELECT min(id) FROM producto), 2, 100.00 FROM nuevo
RETURNING cantidad, precio_unitario, subtotal;
ROLLBACK;

\echo '== 6. Estado final: nada quedo guardado =='
SELECT (SELECT count(*) FROM pedido) AS pedidos,
       (SELECT count(*) FROM detalle_pedido) AS lineas;
