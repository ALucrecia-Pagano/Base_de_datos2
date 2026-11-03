# Resultado de los casos C2 a C6

Los casos se ejecutaron con SQLite CLI 3.53.4 en la copia
[`foodstore_sync_2c.db`](../movil/foodstore_sync_2c.db), construida a partir de
la instantánea de 2.a. PostgreSQL y MongoDB no fueron modificados.

| Caso | Resultado observado | Motivo |
|---|---|---|
| C2, solicitud original | `CONFLICTO` | Cambió el precio observado. |
| C2, solicitud nueva | `SIMULADO_APROBADO` | Se aceptó el precio actualizado de 110000 centavos. |
| C3 | `RECHAZADO` | Stock insuficiente. |
| C4 | `RECHAZADO` | Producto dado de baja. |
| C5 | `SIMULADO_APROBADO` | Precio, disponibilidad y stock coinciden. |
| C6 | Error `UNIQUE constraint failed: cola_sync.solicitud_uuid` | El UUID repetido no se duplica ni reevalúa la solicitud anterior. |

La tabla `cola_sync` terminó con cinco solicitudes únicas: las dos de C2 y una
de cada caso C3, C4 y C5. La ejecución posterior al error de C6 confirmó que
los estados anteriores permanecieron sin cambios.

