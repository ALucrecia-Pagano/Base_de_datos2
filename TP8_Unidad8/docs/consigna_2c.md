# Consigna 2.c — Casos C2 a C6

Los casos se prueban en una copia SQLite basada en la instantánea de
PostgreSQL. Cada caso usa datos ficticios y solicitudes con UUID diferentes,
excepto C6, donde se intenta reenviar intencionalmente el mismo UUID.

| Caso | Preparación | Resultado esperado |
|---|---|---|
| C2 | En la copia de PostgreSQL se sube el precio del producto 1 (1050,00 → 1100,00) y se exporta una instantánea nueva. Luego el cliente acepta: se actualiza el precio del borrador y se envía una solicitud nueva. | Primera solicitud `CONFLICTO`; nueva solicitud `SIMULADO_APROBADO`. |
| C3 | Se solicita una cantidad mayor que el stock del producto 2. | `RECHAZADO` por stock insuficiente. |
| C4 | En la copia de PostgreSQL se da de baja el producto 3 (`activo = false`) y se exporta una instantánea nueva. | `RECHAZADO` con motivo `Producto no disponible`. Al recargar el catálogo, el producto ya no aparece, pero su fila sigue en `producto_cache`. |
| C5 | Se crea una solicitud con precio, disponibilidad y cantidad compatibles. | `SIMULADO_APROBADO`. |
| C6 | Se intenta insertar nuevamente una solicitud con el mismo UUID. | Error de clave primaria; no se duplica ni se reevalúa la solicitud anterior. |

## Cómo se preparan y ejecutan los casos

1. `postgresql/verificar_sin_cambios_2c.sql` en la copia `foodstore_tp8_feria`: registra la cantidad de pedidos y el stock antes de empezar.
2. `postgresql/preparar_casos_2c.sql`: en la copia del servidor sube el precio del producto 1 (C2), da de baja el producto 3 (C4) y exporta `movil/servidor_snapshot_2c.csv`. Tiene un control que impide ejecutarlo en otra base.
3. [`casos_2c.sql`](../movil/casos_2c.sql) en SQLite: crea los borradores con la instantánea de 2.a, importa la instantánea nueva con `movil/recargar_snapshot.sql` y corre el semáforo.
4. `postgresql/verificar_sin_cambios_2c.sql` otra vez: la cantidad de pedidos y el stock deben ser iguales al paso 1.

La tablet nunca escribe en PostgreSQL. Los únicos cambios en la copia del servidor son el precio (C2) y la baja lógica (C4), hechos por el script de preparación, que representa al administrador del servidor.

## Por qué C4 da "Producto no disponible"

La vista `v_snapshot_movil` deriva `disponible` y `eliminado` de la misma columna (`activo`). Una baja lógica en PostgreSQL exporta `disponible = f` y `eliminado = t`, y el semáforo, que revisa la disponibilidad antes que la baja, registra ese motivo. El estado es el que pide la consigna: `RECHAZADO`.

## Dónde iría la protección real contra el reenvío (C6)

En la tablet, la clave primaria de `cola_sync` solo evita duplicados en la cola local. En un sistema real, la protección tiene que estar en el servidor: PostgreSQL guardaría el `solicitud_uuid` de cada solicitud recibida con una restricción `UNIQUE`, en la misma transacción que crea el pedido. Así, un reenvío del mismo UUID no genera un segundo pedido ni descuenta stock dos veces.
