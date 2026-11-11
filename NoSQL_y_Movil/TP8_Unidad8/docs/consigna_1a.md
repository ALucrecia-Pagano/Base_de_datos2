# Consigna 1.a — Datos que viajan a la tablet

La tablet recibe una copia mínima del catálogo para consultar productos y armar
borradores sin conexión. La copia no reemplaza al servidor: PostgreSQL sigue
siendo la fuente de verdad para el precio vigente, el stock, la disponibilidad
y cualquier venta.

| Dato de `producto` | Viaja a SQLite | Representación en `producto_cache` | Motivo |
|---|---:|---|---|
| `id` | Sí | `id` | Identificar el producto en los ítems del borrador. |
| `nombre` | Sí | `nombre` | Mostrar el producto en la consulta local. |
| `precio_lista` | Sí, como precio observado | `precio_centavos` | Armar el borrador sin usar `REAL`; se conserva como entero en centavos. |
| `stock` | Sí, como observación | `stock_visto` | Permitir una validación preliminar offline. |
| `activo` | Sí, como disponibilidad | `disponible` | Ocultar productos que el servidor marcó como no disponibles. |
| Baja lógica | Sí, si corresponde | `eliminado` | Identificar productos retirados en una instantánea posterior. |
| Fecha de copia | Sí | `fecha_copia` | Registrar cuándo se obtuvo la instantánea del servidor. |
| `id_categoria` | No | — | No es necesario para consultar ni armar el borrador. |
| `descripcion` | No | — | No es necesaria para las reglas de sincronización de este práctico. |
| `created_at` | No | — | Es un metadato que no interviene en la operación offline. |

`precio_centavos` y `stock_visto` representan valores observados, no
autorizaciones. Al sincronizar, el servidor vuelve a comparar cada solicitud
con una instantánea de PostgreSQL antes de clasificarla.

