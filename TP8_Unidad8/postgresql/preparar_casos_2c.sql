-- Consigna 2.c. Prepara los casos en la COPIA del servidor y exporta
-- una instantánea nueva para la tablet.
-- Ejecutar desde la raíz del repositorio, solo en foodstore_tp8_feria.
-- No crea pedidos ni cambia stock: solo un precio (C2) y una baja lógica (C4).

\set ON_ERROR_STOP on

-- Seguro: si no estamos en la copia, no se ejecuta nada.
SELECT current_database() = 'foodstore_tp8_feria' AS es_copia \gset
\if :es_copia
\else
    \echo 'ERROR: este script solo se ejecuta en foodstore_tp8_feria.'
    \quit
\endif

BEGIN;

-- C2: el servidor sube el precio de la Muzzarella (1050.00 -> 1100.00).
UPDATE producto
SET precio_lista = 1100.00
WHERE id = 1;

-- C4: baja lógica de la Coca 1.5L. La fila queda; solo se marca inactiva.
UPDATE producto
SET activo = false
WHERE id = 3;

-- C3, C5 y C6 no necesitan cambios en el servidor.

SELECT id, nombre, precio_lista, stock, activo
FROM producto
WHERE id IN (1, 2, 3)
ORDER BY id;

COMMIT;

-- Instantánea nueva para la tablet (la de 2.a queda intacta).
\copy (SELECT * FROM v_snapshot_movil) TO 'TP8_Unidad8/movil/servidor_snapshot_2c.csv' CSV HEADER