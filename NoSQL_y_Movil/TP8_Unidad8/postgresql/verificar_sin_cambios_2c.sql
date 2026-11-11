-- Consigna 2.c. Verificación de que la simulación no cambió pedidos ni stock.
-- Solo lectura. Se ejecuta en la copia foodstore_tp8_feria dos veces:
-- antes de preparar los casos y después de correr el semáforo en SQLite.

SELECT current_database() AS base, CURRENT_TIMESTAMP AS momento;

-- La tablet nunca confirma ventas: la cantidad de pedidos no debe cambiar.
SELECT COUNT(*) AS cantidad_pedidos FROM pedido;
SELECT COUNT(*) AS cantidad_detalles FROM detalle_pedido;

-- La tablet nunca descuenta stock: el stock no debe cambiar.
SELECT id, nombre, stock
FROM producto
WHERE id IN (1, 2, 3)
ORDER BY id;

SELECT SUM(stock) AS stock_total FROM producto;