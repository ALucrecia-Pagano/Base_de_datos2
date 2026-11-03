# Consigna 2.c — Casos C2 a C6

Los casos se prueban en una copia SQLite basada en la instantánea de
PostgreSQL. Cada caso usa datos ficticios y solicitudes con UUID diferentes,
excepto C6, donde se intenta reenviar intencionalmente el mismo UUID.

| Caso | Preparación | Resultado esperado |
|---|---|---|
| C2 | Se modifica el precio del producto 1 en la instantánea. Luego se crea una nueva solicitud con el precio aceptado. | Primera solicitud `CONFLICTO`; nueva solicitud `SIMULADO_APROBADO`. |
| C3 | Se solicita una cantidad mayor que el stock del producto 2. | `RECHAZADO` por stock insuficiente. |
| C4 | Se marca el producto 3 como no disponible y dado de baja. | `RECHAZADO` por baja lógica. |
| C5 | Se crea una solicitud con precio, disponibilidad y cantidad compatibles. | `SIMULADO_APROBADO`. |
| C6 | Se intenta insertar nuevamente una solicitud con el mismo UUID. | Error de clave primaria; no se duplica ni se reevalúa la solicitud anterior. |

El script [`casos_2c.sql`](../movil/casos_2c.sql) se ejecuta sobre una copia
de trabajo, no sobre PostgreSQL. Las modificaciones de `snapshot_servidor`
representan nuevas instantáneas de prueba y no ventas ni cambios reales del
servidor.
