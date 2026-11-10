# Resultado de las pruebas SQLite

## Ejecución

Las pruebas se ejecutaron desde la terminal con SQLite CLI 3.53.4 sobre una
base nueva de pruebas:

```powershell
sqlite3 TP8_Unidad8\movil\foodstore_movil_pruebas.db
```

Dentro de SQLite se ejecutaron:

```text
.read TP8_Unidad8/movil/schema_sqlite.sql
.read TP8_Unidad8/movil/pruebas_sqlite.sql
```

## Resultados observados

- El borrador confirmado quedó guardado con forma de pago `EFECTIVO`, estado
  `PENDIENTE` y dos ítems.
- El borrador de prueba del `ROLLBACK` no dejó filas:
  `borradores_revertidos = 0` e `items_revertidos = 0`.
- La consulta C1 devolvió los tres productos disponibles con stock:
  `Muzzarella`, `Napolitana` y `Coca 1.5L`.
- C7 rechazó la cantidad cero con `CHECK constraint failed: cantidad > 0`.
- C7 rechazó el producto inexistente con `FOREIGN KEY constraint failed`.
- Las consultas posteriores confirmaron cero filas inválidas en ambos casos.
- La base contiene las tablas `cola_sync`, `item_borrador`,
  `pedido_borrador` y `producto_cache`.

Las dos salidas de error de C7 son esperadas y constituyen parte de la prueba
de las restricciones. La ejecución se realizó sobre la copia de prueba y no
modificó PostgreSQL ni MongoDB.

## Reejecución de corrección

El 2026-11-03 se repitió `pruebas_sqlite.sql` sobre
`foodstore_movil_1c_retest.db`. La ejecución volvió a confirmar el borrador
confirmado, el `ROLLBACK` sin filas, la consulta C1 y los dos rechazos de C7.
El estado final fue de cuatro productos, un borrador confirmado, dos ítems y
una solicitud `PENDIENTE`; no quedaron filas de la operación revertida ni de
los intentos inválidos.

La versión corregida del script agrega una inserción válida previa a cada
error C7 y ejecuta `ROLLBACK`, de modo que la prueba también verifica que no
queden filas parciales. Esta variante debe reejecutarse para actualizar la
evidencia de ejecución.
