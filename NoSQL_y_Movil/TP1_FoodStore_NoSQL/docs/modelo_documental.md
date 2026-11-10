# Modelo documental — diseño inicial e implementación, consignas 1 y 3

Responsable: Amanda. Fecha: 2026-10-28. **Estado actual: implementado y migrado manualmente por Amanda, con verificación documentada; aprobado por el equipo con el informe final (2026-11-01).** Referencias: [plan](plan_trabajo.md), [decisiones](decisiones.md) y [reglas](../../AGENTS.md).

La referencia académica principal es la [consigna oficial](../consignas/BDII_Unidad7_TP_FoodStore_NoSQL.pdf): página 1, consignas 1–3; página 2, consultas y entrega; página 3, correspondencia con la versión real de FoodStore. La consigna 1 pide identificar tablas y claves y esquematizar documentos; la 3 pide dos reglas de integridad y justificar el embebido. La migración de la consigna 2 ya fue ejecutada por Amanda y se documenta en el [resultado](resultado_migracion.md); se conserva el procedimiento inicialmente propuesto como antecedente.

Este documento conserva los antecedentes del diseño inicial y actualiza el destino, la correspondencia y los controles con lo implementado. El ejemplo y la secuencia original de la sección 7 se identifican como antecedentes; no implican aprobación grupal. El asistente no ejecutó motores ni migraciones.

## Implementación posterior y estado de revisión

Amanda ejecutó manualmente la extracción y la migración a `foodstore_unidad7.pedidos`. Las [capturas de inserción](../evidencias/migracion_insercion.png) y [verificación](../evidencias/migracion_verificacion_amanda.png), inspeccionadas documentalmente, muestran IDs Long 1–5, cinco pedidos, siete líneas, tipos BSON correctos y correspondencia de todos los campos con el lote fuente. Ver [resultado de la migración](resultado_migracion.md) para procedimiento y límites; no son nuevas ejecuciones del asistente.

La implementación utiliza `_id` igual al ID del pedido, cliente con ID Long y alias sintético, líneas embebidas, cantidades Int32, fechas Date e importes Decimal128. **Se excluyeron todas las observaciones**, además de nombres/contactos personales del cliente; esto concreta y acota la opción inicialmente contemplada en la tabla de correspondencia. Los nombres de productos son actuales y los precios históricos provienen del detalle. El [script histórico con fuente y SHA de Amanda](https://github.com/ALucrecia-Pagano/Bases-de-datos-II-NoSQL/blob/73ee80a6c5b35b75491d81ebf30c03371a88ec68/mongodb/migracion_pedidos.js) calcula con BigInt en centavos, controla fechas sin pérdida submilisegundo e incorpora `Buffer` mediante `require("buffer")` para Compass.

La [extracción real](../evidencias/extraccion_20261028_170446.json), con SHA-256 `3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`, informa claves bigint, cantidades integer y fechas sin submilisegundos. Sus controles y las capturas documentan la ejecución del procedimiento; no se instalaron validadores permanentes. El diseño fue aprobado por el equipo con el informe final; sigue pendiente la confirmación docente de la suficiencia de ID más alias. Las consignas 4–5 se documentan en [comparacion_resultados.md](comparacion_resultados.md) y las 6–7 en [contraste_ia.md](contraste_ia.md).

Las elecciones iniciales se implementaron sin que ello constituya aprobación grupal. La sección 7 conserva explícitamente la secuencia propuesta antes de ejecutar; el [traspaso al equipo](traspaso_equipo.md) describe el procedimiento de reproducción y la organización del trabajo.

La referencia histórica fija el procedimiento con la fuente y el hash de Amanda; el [script compartido actual](../mongodb/migracion_pedidos.js) usa esa misma fuente oficial y su hash. Una revisión intermedia los había cambiado para la extracción del 29/10 del anexo de Mateo; esa configuración se revirtió. Las rutas de las capturas son anteriores al traslado a `TP1_FoodStore_NoSQL/`.

## 1. Subconjunto y claves del origen

Origen: PostgreSQL, base `foodstore_dev`.

| Tabla | Clave y relación que intervienen | Papel en el documento |
|---|---|---|
| `pedido` | PK `id`; FK `id_cliente` → `cliente.id` | Un documento por pedido |
| `detalle_pedido` | PK compuesta (`id_pedido`, `id_producto`); FK `id_pedido` → `pedido.id`; FK `id_producto` → `producto.id` | Un elemento de `lineas` por detalle |
| `cliente` | PK `id` | Identificador y alias sintético embebidos |
| `producto` | PK `id`; FK `id_categoria` → `categoria.id` | Identificador y nombre actual en cada línea; `categoria` queda fuera del subconjunto migrado |

Estas relaciones describen el modelo aportado. La extracción documenta tipos y existencia de referencias del lote; esta revisión documental no verifica las definiciones de claves mediante una conexión al esquema real.

Destino implementado: base `foodstore_unidad7`, colección `pedidos`, prevista como colección ordinaria local sin particionamiento. Las capturas documentan la carga en ese destino; no se migraron colecciones adicionales. El diseño fue aprobado por el equipo con el informe final.

## 2. Correspondencia PostgreSQL → MongoDB

| Origen | Campo documental | BSON implementado | Transformación o criterio |
|---|---|---|---|
| `pedido.id` | `_id` | Long (`long`, entero de 64 bits) | Mismo ID de origen, sin generar ObjectId |
| `pedido.id_cliente` / `cliente.id` | `cliente.id` | Long | Verificar igualdad y existencia del cliente |
| Derivado de `cliente.id` | `cliente.alias` | String | `Cliente ` seguido del ID decimal; no procede de `nombre_completo` |
| `pedido.fecha_hora` (`timestamptz`) | `fecha_hora` | Date | Convertir a UTC sin cambiar el instante, sujeto al control de precisión indicado abajo |
| `pedido.forma_pago` | `forma_pago` | String | Conservar el valor aportado |
| `pedido.estado` | `estado` | String | Conservar el valor; los cinco están `ENTREGADO` |
| `pedido.observaciones` | Excluido | No aplica | Se excluyeron todas las observaciones del modelo implementado por privacidad; no se sustituyen por null ni texto inventado |
| Detalles agrupados por `id_pedido` | `lineas` | Array de objetos | Mantener una línea por par de la clave compuesta |
| `detalle_pedido.id_pedido` | Pertenencia al documento con ese `_id` | Sin campo duplicado | La agrupación conserva la relación con el pedido |
| `detalle_pedido.id_producto` / `producto.id` | `lineas[].id_producto` | Long | Conservar ID y comprobar existencia del producto |
| `producto.nombre` | `lineas[].nombre_producto` | String | Descripción actual obtenida al extraer, no nombre histórico acreditado |
| `detalle_pedido.cantidad` | `lineas[].cantidad` | Int32 (`int`, entero de 32 bits) | Positivo y dentro de 1 a 2147483647; suficiente para los valores 1–4 aportados |
| `detalle_pedido.precio_unitario` (`numeric(10,2)`) | `lineas[].precio_unitario` | Decimal128 (`decimal`) | Precio histórico tomado del detalle, convertido desde texto decimal |
| `detalle_pedido.subtotal` generado | `lineas[].subtotal` | Decimal128 | Recalcular exactamente y comparar con el subtotal del origen |
| Suma de subtotales por pedido | `total` | Decimal128 | Campo derivado, no columna de `pedido` informada |

No se trasladan nombres, email, teléfono, dirección ni `created_at` del cliente. Tampoco categoría, descripción, `precio_lista`, stock, activo ni `created_at` del producto: no son necesarios para el subconjunto pedido y no reemplazan sus precios históricos. Todas las observaciones quedaron excluidas, sin publicar su texto original.

### Tipos y precisión

- **IDs:** se implementó Long para los identificadores bigint informados por la extracción; el script comprueba los rangos del lote. En mongosh, `Long("1")` evita pasar por un número JavaScript potencialmente impreciso para IDs grandes. No convertir primero a Double. Una nueva fuente con tipos o rangos distintos exige revisión antes de cargar. [S1]
- **Cantidades:** usar `Int32(2)` explícito, comprobando que el origen contiene enteros dentro del rango elegido; detener la transformación ante desbordamiento en lugar de redondear. [S1]
- **Importes:** `Decimal128("1000.00")` expresa un decimal BSON; construirlo desde texto, sin conversión intermedia a Double. Decimal128 admite 34 cifras significativas, suficientes para estos precios `numeric(10,2)` y los totales aportados. No impone por sí mismo una escala de dos decimales ni las reglas del negocio. [S1, S2]
- **Fecha:** `ISODate("2026-03-01T23:30:00.000Z")` representa el mismo instante que `2026-03-01T20:30:00-03:00`; `Z` indica UTC. BSON Date registra milisegundos desde la época Unix y no almacena el desplazamiento original. La extracción y el script comprobaron que las fechas del lote no tienen fracciones submilisegundo. Una nueva fuente con esas fracciones debe bloquearse y revisarse, sin truncarlas silenciosamente. No confundir Date con el tipo interno Timestamp. [S2]

La sintaxis se contrastó documentalmente con MongoDB; no se evaluó el ejemplo en mongosh. Versiones informadas por Amanda: MongoDB Server 9.0.4, Compass 1.53.2 y mongosh integrado 2.9.2.

## 3. Cliente embebido y privacidad

Se implementó `cliente` con `id` y `alias` determinista: para el cliente 1, `Cliente 1`. El alias es una **transformación sintética para la entrega**, no un nombre extraído de PostgreSQL. El mismo ID produce el mismo alias en todos sus pedidos.

Esto permite reconocer al cliente asociado y vincular sus pedidos sin publicar nombres o contactos reales. Es una representación mínima razonable para consultar pedidos, pero la consigna no define qué considera datos esenciales: el equipo lo aprobó con el informe final y **queda pendiente la confirmación docente de que ID más alias satisface ese requisito**. Si se pide más información, acordar su tratamiento antes de implementarla, sin inventar atributos reales ni incorporar contactos personales.

Conservar IDs es necesario para la trazabilidad exigida, pero el alias no garantiza anonimización irreversible: los IDs pueden vincularse con el origen privado. Mantener el origen y cualquier correspondencia personal fuera de la entrega pública.

## 4. Único documento ilustrativo: pedido 1

**Ejemplo ilustrativo del diseño inicial, no ejecutado como bloque**, escrito en notación de mongosh para mostrar tipos BSON; no es JSON estricto ni un script de inserción. El modelo implementado conserva esta estructura y fue aprobado por el equipo con el informe final. Las observaciones están excluidas del modelo implementado.

```javascript
{
  _id: Long("1"),
  fecha_hora: ISODate("2026-03-01T23:30:00.000Z"),
  forma_pago: "EFECTIVO",
  estado: "ENTREGADO",
  cliente: {
    id: Long("1"),
    alias: "Cliente 1"
  },
  lineas: [
    {
      id_producto: Long("1"),
      nombre_producto: "Muzzarella",
      cantidad: Int32(2),
      precio_unitario: Decimal128("1000.00"),
      subtotal: Decimal128("2000.00")
    },
    {
      id_producto: Long("3"),
      nombre_producto: "Coca 1.5L",
      cantidad: Int32(1),
      precio_unitario: Decimal128("800.00"),
      subtotal: Decimal128("800.00")
    }
  ],
  total: Decimal128("2800.00")
}
```

Los nombres de productos se conocen como valores actuales aportados por Amanda. Solo los precios del detalle se consideran históricos.

## 5. Dos reglas principales de integridad — consigna 3

1. **Dominio numérico:** cada cantidad debe ser un entero positivo; precio unitario, subtotal y total deben ser decimales finitos no negativos. Rechazar nulos, valores ausentes, NaN, infinitos y tipos incompatibles. Un precio cero es válido según la restricción informada del origen.
2. **Coherencia de importes:** en cada línea, `subtotal = cantidad × precio_unitario histórico`; en el pedido, `total = suma de los subtotales`. El cálculo debe ser decimal exacto, sin operadores JavaScript que conviertan los importes a Double. Decimal128 almacena el resultado, pero no calcula estas igualdades automáticamente. Se utilizó NUMERIC en la extracción y BigInt en centavos en el script de migración, conservando los importes como texto al construir Decimal128.

### Controles del diseño inicial y alcance de las garantías

La tabla conserva los criterios previstos antes de ejecutar. Su implementación usa los controles de extracción y migración y la comparación posterior completa con el lote validado, según el [resultado documentado](resultado_migracion.md); no constituye una nueva ejecución de esos controles.

| Control | Antes de insertar: responsabilidad del futuro script/procedimiento | Verificación posterior prevista | Garantía del motor y límite |
|---|---|---|---|
| IDs y correspondencia | Seleccionar pedidos 1–5; comprobar claves, IDs únicos, cliente, fecha, estado, forma de pago y cada par pedido/producto contra la extracción | Igualdad de conjuntos de IDs y comparación campo por campo; cinco documentos y siete líneas no bastan por sí solos | El índice único de `_id` protege IDs de pedidos en una colección ordinaria; no demuestra correspondencia con PostgreSQL [S4] |
| Productos sin duplicación | Comparar número de líneas con número de IDs de producto distintos en cada pedido; rechazar repetidos, sin fusionarlos | Repetir la comprobación por documento | La PK (`id_pedido`, `id_producto`) se traduce en unicidad de `id_producto` dentro de `lineas`, no en unicidad global del producto. Un índice único multikey no evita repeticiones dentro de un mismo documento [S4] |
| Referencias existentes | Comprobar que cada `id_cliente` y `id_producto` existe al extraer; detectar huérfanos antes de agrupar. No usar joins que oculten filas faltantes sin detectarlas | Confrontar IDs embebidos con la extracción de clientes y productos del lote | Los IDs embebidos no crean claves foráneas ni prueban existencia en el origen |
| Regla 1 | Verificar tipos, rangos y signos de cada valor antes de construir documentos | Revisar tipos BSON y todos los valores del lote | Requeriría validación adicional del servidor para rechazar futuras escrituras ajenas al procedimiento [S5] |
| Regla 2 | Recalcular subtotales y total; comparar con origen y detenerse ante diferencias | Recalcular desde los documentos almacenados y comparar exactamente, además de contrastar con el origen | Requeriría validación adicional para imponer igualdades a toda escritura; no se hereda el subtotal generado de PostgreSQL [S5] |

Para evitar un `total` desactualizado se propone cargar el lote como una instantánea sin ediciones manuales de importes. Cualquier modificación futura autorizada de líneas deberá recalcular subtotales y total y escribirlos conjuntamente en una operación sobre el mismo documento, con control de concurrencia cuando corresponda. MongoDB ofrece atomicidad por documento, pero no recalcula campos ni impone las fórmulas por sí solo. Sin validación adicional, una escritura que omita el procedimiento puede romperlas. [S6]

No se instaló un validador permanente en MongoDB. Los controles del procedimiento sí se implementaron y el lote tiene verificación documentada; esto no garantiza las reglas ante futuras escrituras ajenas al procedimiento.

## 6. Justificación del embebido

Las líneas pertenecen al pedido y se consultan junto con él; el cliente mínimo también se necesita para interpretar el pedido completo. Embebidos, se recuperan con el pedido sin reconstruir relaciones entre colecciones. Este criterio se ajusta al acceso frecuente a pedidos completos indicado en la consigna 6 y a la recomendación de MongoDB para datos relacionados consultados juntos. No implica haber medido una mejora de rendimiento. [S3]

El costo es duplicar el ID y alias del cliente en varios pedidos y el nombre actual del producto en varias líneas. Cambiar una descripción no actualiza automáticamente sus copias. Se propone tratarlas como información descriptiva de la extracción, sin prometer sincronización ni historial de nombres. Los precios permanecen como valores históricos propios de cada detalle. El modelo facilita leer el agregado y mantener sus importes conjuntamente, pero no sustituye las relaciones y restricciones del origen. No se requieren colecciones separadas para este lote pequeño. [S3, S6]

## 7. Antecedente: método de migración propuesto antes de ejecutar

El diseño inicial propuso **extracción de solo lectura y un archivo mongosh revisable con inserción ordenada mediante `insertMany`**. Amanda ejecutó posteriormente ese procedimiento en Compass, según el [resultado documentado](resultado_migracion.md). La lista siguiente conserva la secuencia propuesta como antecedente, no como tareas de migración aún pendientes ni como aprobación grupal acreditada:

1. Aprobar nombres, tipos, cliente y método; identificar versiones, conexión y destino sin secretos y obtener autorización de ejecución para ambos motores. No modificar PostgreSQL.
2. Obtener una extracción consistente de pedidos 1–5 y sus siete detalles, junto con las referencias existentes; registrar fecha y contexto. Comprobar que corresponda con los datos aportados antes de continuar.
3. Transformar de forma determinista: pedidos ordenados por ID y líneas por producto; aplicar alias; convertir IDs y decimales desde texto; convertir fechas a UTC. Conservar el insumo revisable sin datos personales publicables y las reglas de transformación para reproducir el lote.
4. Aplicar todos los controles previos de la sección 5. Calcular en decimal los subtotales y totales y confrontar con el origen. Revisar el archivo antes de autorizar su ejecución.
5. Antes de cualquier inserción, consultar el destino por todos los IDs del lote. Si ya existe cualquiera, detener todo el lote e informar; no usar reemplazos, upsert, borrados ni recreaciones automáticas. Una nueva ejecución debe detectar los IDs existentes y detenerse, no duplicar ni actualizar silenciosamente.
6. Solo con autorización, crear el destino si no existe o comprobar el destino existente e insertar el lote ordenado. `insertMany` ordenado se detiene ante un error, pero no revierte inserciones anteriores: no es una transacción de todo el lote. Si ocurre una carga parcial o un conflicto concurrente tras la comprobación previa, detenerse, registrar los IDs efectivamente insertados y el error, y pedir revisión antes de recuperar; no reintentar ciegamente. [S7]
7. Verificar los documentos almacenados contra la extracción y registrar evidencias anonimizadas. No declarar migración completa por el solo éxito de la inserción.

### Referencias de control derivadas de los datos aportados

| Pedido | Cliente | IDs de producto | Líneas | Total calculado esperado |
|---|---|---|---|---|
| 1 | 1 | 1, 3 | 2 | 2800.00 |
| 2 | 2 | 2 | 1 | 1500.00 |
| 3 | 1 | 1 | 1 | 3150.00 |
| 4 | 3 | 2, 3 | 2 | 6200.00 |
| 5 | 2 | 1 | 1 | 1050.00 |

Estas referencias se calcularon antes de ejecutar y luego coincidieron con la extracción guardada. El total conjunto es 14700.00; la verificación documentada compara también cada campo y línea, sin limitarse al agregado. La tabla no acredita las consultas académicas de las consignas 4–5.

## 8. Fuentes oficiales consultadas y dudas

Consulta documental: 2026-10-28. La documentación en línea no acredita la versión instalada ni reemplaza la comprobación futura en el entorno del equipo.

- **S1.** [MongoDB Shell — Data Types](https://www.mongodb.com/docs/mongodb-shell/reference/data-types/): sintaxis explícita `Long("1")`, `Int32(2)`, `Decimal128("1000.00")` e `ISODate`.
- **S2.** [MongoDB — BSON Types](https://www.mongodb.com/docs/manual/reference/bson-types/): Long, Date en milisegundos UTC y precisión de Decimal128.
- **S3.** [MongoDB — Embedded Data](https://www.mongodb.com/docs/manual/data-modeling/embedding/): recuperación conjunta y embebido.
- **S4.** [MongoDB — Unique Indexes](https://www.mongodb.com/docs/manual/core/index-unique/): `_id` único y límites de unicidad multikey dentro del documento.
- **S5.** [MongoDB — Schema Validation](https://www.mongodb.com/docs/manual/core/schema-validation/): esquema flexible y validación explícita.
- **S6.** [MongoDB — Atomicity and Transactions](https://www.mongodb.com/docs/manual/core/write-operations-atomicity/): atomicidad por documento y concurrencia.
- **S7.** [MongoDB — insertMany](https://www.mongodb.com/docs/manual/reference/method/db.collection.insertMany/): inserción ordenada y detención ante errores.
- **S8.** [MongoDB — Model Monetary Data](https://www.mongodb.com/docs/manual/tutorial/model-monetary-data/): uso de decimal para importes frente a aproximaciones binarias.

Estado: diseño implementado aprobado por el equipo con el informe final (2026-11-01); pendiente la confirmación docente de la suficiencia de ID más alias. Versiones informadas por Amanda: MongoDB Server 9.0.4, Compass 1.53.2 y mongosh integrado 2.9.2. Los tipos y las fechas del lote ya fueron comprobados según la extracción y la verificación documentada; todas las observaciones se excluyeron. No se eligió moneda porque no fue informada. Cualquier nueva ejecución requiere autorización y no debe repetir la inserción existente.
