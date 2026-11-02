# Aporte de Mateo — consultas y comparación entre motores

Redactado por Amanda a partir del trabajo de Mateo (consultas, parámetros y ejecución del 2026-10-29) y de la reejecución de Amanda del 2026-11-01; con OK de Mateo del 2026-11-01.

Aporte integrado al informe final aprobado, consignas 4 y 5 (sección 3 del esquema). Detalle completo, comandos y límites: [comparacion_resultados.md](../docs/comparacion_resultados.md).

## 3. Consultas y comparación de resultados

**Parámetros.** Todas las consultas se limitan al lote migrado, pedidos 1–5, para no comparar contra pedidos ajenos a la migración. Estado: `ENTREGADO`, presente en los cinco pedidos. Producto: ID `1`, presente en los pedidos 1, 3 y 5. Umbral de d): total mayor que `Decimal128("3000.00")`.

**Consultas MongoDB (consigna 4)**, sobre `foodstore_unidad7.pedidos`:

- a) `find` del lote con proyección de `_id` y `estado`.
- b) `find` del lote con `estado: "ENTREGADO"`.
- c) `aggregate` que filtra `lineas.id_producto: Long(1)` y proyecta con `$filter` solo la línea coincidente, conservando cantidad y precio histórico.
- d) `find` del lote con `total: { $gt: Decimal128("3000.00") }`; Decimal128 evita convertir dinero a Number/Double.

**Equivalentes PostgreSQL (consigna 5)**, sobre `foodstore_dev.public`: b) `pedido` filtrado por estado; c) `pedido` unido a `detalle_pedido` filtrado por `id_producto = 1`, con `cantidad` y `precio_unitario`.

**Comparación de b) y c).**

| Consulta | Parámetro | Cantidad PostgreSQL | Cantidad MongoDB | IDs | Coinciden los IDs |
|---|---|---|---|---|---|
| b) Estado | `ENTREGADO` | 5 | 5 | 1, 2, 3, 4, 5 | Sí |
| c) Producto | ID `1` | 3 | 3 | 1, 3, 5 | Sí |

En c), ambos motores devolvieron las mismas cantidades y precios históricos: pedido 1 (2 × 1000.00), pedido 3 (3 × 1050.00) y pedido 5 (1 × 1050.00).

**Resultado de d).** MongoDB devolvió los pedidos 3 (total 3150.00) y 4 (total 6200.00). El lote suma 14700.00 en cinco pedidos, con un promedio de 2940.00; el umbral de 3000.00 selecciona los pedidos por encima del promedio y excluye el de 2800.00, cercano a él.

**Interpretación.** Las consultas equivalentes devuelven las mismas cantidades y los mismos IDs en ambos motores, y conservan cantidades y precios históricos, lo que es coherente con una migración sin pérdida del lote. La comparación se limita a los cinco pedidos migrados y a las ejecuciones registradas; no demuestra sincronización futura entre motores ni mide rendimiento.

**Ejecuciones.** Mateo informó la ejecución el 2026-10-29 en su computadora; su captura MongoDB no mostraba completas c) y d). Amanda reejecutó los mismos scripts, sin modificarlos, el 2026-11-01 en su computadora (PostgreSQL con `psql`, MongoDB en la shell de Compass) y obtuvo los mismos resultados, con salidas completas.

**Referencias:** [consultas_mongodb.js](../mongodb/consultas_mongodb.js) y [consultas_postgresql.sql](../postgresql/consultas_postgresql.sql). Capturas de Mateo: [MongoDB](../evidencias/consultas_mongodb_consignas_4_5.png) y [PostgreSQL](../evidencias/consultas_postgresql_consignas_4_5.png). Capturas de Amanda: [PostgreSQL](../evidencias/consultas_postgresql_amanda.png), [MongoDB 1](../evidencias/consultas_mongodb_amanda_1.png), [MongoDB 2](../evidencias/consultas_mongodb_amanda_2.png) y [MongoDB 3](../evidencias/consultas_mongodb_amanda_3.png).

**Asistencia de IA:** Claude (Anthropic) asistió en la redacción de este texto a partir de los scripts, las capturas y la comparación documentada; no ejecutó motores.
