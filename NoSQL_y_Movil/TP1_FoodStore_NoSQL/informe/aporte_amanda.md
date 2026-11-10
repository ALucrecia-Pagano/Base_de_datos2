# Aporte de Amanda — modelo, integridad y migración

Aporte breve integrado al informe final aprobado, consignas 1–3; no constituye el informe final ni su conclusión.

Se representó el subconjunto de cinco pedidos de FoodStore en `foodstore_unidad7.pedidos`, con un documento por pedido, cliente mínimo embebido y un arreglo de líneas. Se conservó el ID del pedido como `_id`; los identificadores de pedido, cliente y producto usan BSON Long, las cantidades Int32, las fechas Date en UTC y los importes Decimal128. El cliente contiene su ID y un alias sintético `Cliente <id>`, sin nombres ni contactos reales. Se excluyeron observaciones. Los precios históricos proceden de `detalle_pedido.precio_unitario`; los nombres de productos son descripciones actuales del origen.

Tablas y claves del modelo relacional aportado:

| Tabla | Claves |
|---|---|
| `pedido` | PK `id`; FK `id_cliente` → `cliente.id` |
| `detalle_pedido` | PK (`id_pedido`, `id_producto`); FK `id_pedido` → `pedido.id`; FK `id_producto` → `producto.id` |
| `cliente` | PK `id` |
| `producto` | PK `id`; FK `id_categoria` → `categoria.id` |

`categoria` queda fuera del subconjunto migrado. Esquema breve de la colección, con los nombres implementados (notación descriptiva, no ejecutable):

```text
pedidos {
  _id: Long, fecha_hora: Date, forma_pago: String, estado: String,
  cliente: { id: Long, alias: String },
  lineas: [{ id_producto: Long, nombre_producto: String, cantidad: Int32,
             precio_unitario: Decimal128, subtotal: Decimal128 }],
  total: Decimal128
}
```

Se conservaron dos reglas principales de integridad:

1. Cantidad entera positiva e importes finitos no negativos.
2. Subtotal igual a cantidad por precio histórico y total igual a suma de subtotales.

El procedimiento controla además IDs, existencia de referencias al extraer y ausencia de productos duplicados por pedido. Los cálculos se realizan de forma exacta y se comprueba que las fechas no pierdan precisión al convertirlas a BSON Date. Estos controles del procedimiento no son restricciones de PostgreSQL trasladadas automáticamente ni validadores permanentes de MongoDB.

Se embebieron cliente y líneas para recuperar el pedido completo en una sola estructura. Esto duplica datos descriptivos entre pedidos y exige una política explícita si cambian; no se midió rendimiento ni se acreditó un historial de nombres.

Según lo informado por Amanda, realizó manualmente la extracción de solo lectura desde `foodstore_dev.public` y la migración en Compass desde el JSON conservado con SHA-256. El script validó el lote, comprobó IDs existentes e insertó mediante `insertMany` ordenado. La verificación posterior comparó todos los campos con el lote fuente y comprobó tipos BSON. Las capturas inspeccionadas documentan inserción confirmada de IDs Long 1–5 y verificación satisfactoria de cinco pedidos y siete líneas. La revisión del asistente fue documental y visual, sin nuevas ejecuciones en motores.

Fuente original: `TP1_FoodStore_NoSQL/evidencias/extraccion_20261028_170446.json`; SHA-256 `3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`. El [script histórico de Amanda](https://github.com/ALucrecia-Pagano/Bases-de-datos-II-NoSQL/blob/73ee80a6c5b35b75491d81ebf30c03371a88ec68/mongodb/migracion_pedidos.js) conserva esa fuente (con la ruta anterior al traslado) y su hash; el script compartido actual vuelve a usar esa misma fuente oficial y su hash, después de una revisión intermedia configurada con la extracción del anexo de Mateo.

La [captura del pedido 1](../evidencias/pedido_1_documento.png) muestra `_id: Long('1')`, fecha UTC, estado `ENTREGADO`, cliente con ID y alias, dos líneas de productos y total `Decimal128('2800.00')`. Ilustra ese documento; no verifica por sí sola el lote completo ni el tipo BSON de las cantidades mostradas como números.

El resultado cubre este lote y su correspondencia con la extracción, no el estado futuro de las bases. Una inserción ordenada no es una transacción del lote. El diseño fue aprobado por el equipo con el informe final; sigue pendiente la confirmación docente de la suficiencia del cliente con ID y alias.

Referencias para integrar: [modelo documental](../docs/modelo_documental.md), [resultado y límites de migración](../docs/resultado_migracion.md), [extracción original](../evidencias/extraccion_20261028_170446.json), [captura de inserción](../evidencias/migracion_insercion.png), [captura de verificación](../evidencias/migracion_verificacion_amanda.png) y [documento del pedido 1](../evidencias/pedido_1_documento.png). Este aporte no completa las consultas de Mateo ni el análisis de IA y la conclusión de Lucas.
