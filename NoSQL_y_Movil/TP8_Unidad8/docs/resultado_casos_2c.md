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

## Reejecución con instantánea nueva de PostgreSQL (04/11/2026)

Ejecutada por Amanda Pagano con SQLite CLI 3.54.1 (base en memoria) y PostgreSQL en la copia `foodstore_tp8_feria`, creada a partir de `foodstore_dev`. Esta sección complementa la ejecución anterior: ahora los cambios de C2 y C4 se hicieron en la copia del servidor y se exportó `servidor_snapshot_2c.csv`.

Comando (desde la raíz del repositorio):

```bash
sqlite3 :memory: ".read TP8_Unidad8/movil/schema_sqlite.sql" ".import --csv --skip 1 TP8_Unidad8/movil/servidor_snapshot.csv snapshot_servidor_import" ".read TP8_Unidad8/movil/importar_snapshot.sql" ".read TP8_Unidad8/movil/casos_2c.sql"
```

| Caso | Solicitud | Estado | Motivo |
|---|---|---|---|
| C2 | `c2-solicitud-1` | `CONFLICTO` | Cambió el precio observado |
| C2 (aceptado) | `c2-solicitud-2` | `SIMULADO_APROBADO` | Precio, disponibilidad y stock coinciden |
| C3 | `c3-solicitud` | `RECHAZADO` | Stock insuficiente |
| C4 | `c4-solicitud` | `RECHAZADO` | Producto no disponible |
| C5 | `c5-solicitud` | `SIMULADO_APROBADO` | Precio, disponibilidad y stock coinciden |
| C6 | reenvío de `c5-solicitud` | Error `UNIQUE constraint failed: cola_sync.solicitud_uuid` | La tercera ejecución del semáforo deja los cinco estados sin cambios |

**C4, catálogo recargado.** El catálogo disponible muestra solo la Muzzarella (110000 centavos, stock 50) y la Napolitana (150000 centavos, stock 35). La fila de la Coca 1.5L sigue en `producto_cache` con `disponible = 0` y `eliminado = 1`: es una baja lógica, no un borrado.

**PostgreSQL no cambió** (`postgresql/verificar_sin_cambios_2c.sql`):

| Medición | Antes (20:47) | Después (21:01) |
|---|---|---|
| Cantidad de pedidos | 5 | 5 |
| Cantidad de detalles de pedido | 7 | 7 |
| Stock de los productos 1, 2 y 3 | 50 / 35 / 100 | 50 / 35 / 100 |
| Stock total | 185 | 185 |

El precio del producto 1 y el estado `activo` del producto 3 sí cambiaron en la copia: los cambió el script de preparación (el servidor), no la tablet.
