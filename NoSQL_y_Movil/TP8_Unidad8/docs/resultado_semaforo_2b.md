# Resultado de la prueba del semáforo

Se ejecutó [`semaforo.sql`](../movil/semaforo.sql) en la copia SQLite
[`foodstore_sync_2b.db`](../movil/foodstore_sync_2b.db), construida a partir de
la instantánea exportada de PostgreSQL. Se cargó un borrador ficticio con dos
unidades del producto 1, precio observado de 105000 centavos y una solicitud
`PENDIENTE`.

Resultado de la primera evaluación:

```text
estado: SIMULADO_APROBADO
motivo: Precio, disponibilidad y stock coinciden
```

El semáforo se ejecutó una segunda vez. El resultado permaneció igual y la
cantidad de solicitudes siguió siendo una, porque el `UPDATE` solo procesa
solicitudes cuyo estado es `PENDIENTE`.

Esta prueba verifica el camino verde y la idempotencia. Los caminos rojo y
amarillo se verificarán con los casos C2 a C6, utilizando instantáneas nuevas
según corresponda. La prueba no modificó PostgreSQL ni MongoDB.

## Reejecución de corrección

El 2026-11-03 se repitió el semáforo corregido en
`foodstore_movil_2b_retest.db`. La primera y la segunda evaluación devolvieron
`SIMULADO_APROBADO`, con el motivo `Precio, disponibilidad y stock coinciden`,
y la cantidad de solicitudes permaneció en una. También se corrigió un alias
SQL con espacio que impedía analizar el script.

La versión corregida de `semaforo.sql` conserva estos resultados y agrega una
evaluación agrupada por solicitud mediante una tabla temporal, además de
rechazar solicitudes sin ítems. Esta variante debe reejecutarse para actualizar
la evidencia de ejecución.
