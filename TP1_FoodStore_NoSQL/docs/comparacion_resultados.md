# Comparación de resultados — consignas 4 y 5

Responsable: Mateo, consignas 4–5. Referencias: [plan](plan_trabajo.md), [reglas](../../AGENTS.md) y [registro de evidencias](../evidencias/README.md).

## Contexto de ejecución

Mateo aportó las [consultas MongoDB](../mongodb/consultas_mongodb.js), las [consultas PostgreSQL](../postgresql/consultas_postgresql.sql) y su comparación, e informó su ejecución el 2026-10-29. El 2026-11-01 Amanda volvió a ejecutar esos mismos scripts en su computadora para completar las evidencias (ver [Reejecución de Amanda](#reejecución-de-amanda--2026-11-01)). La revisión estática de los scripts muestra consultas de lectura; el asistente no ejecutó motores.

La fuente oficial de la migración (consigna 2) es [extraccion_20261028_170446.json](../evidencias/extraccion_20261028_170446.json), de Amanda, con SHA-256 `3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`; es la configurada en [migracion_pedidos.js](../mongodb/migracion_pedidos.js). Según lo informado, Mateo cargó y verificó los datos en su computadora usando su propia extracción del 29/10, que se conserva como anexo de esa prueba local independiente. Su arreglo `extraccion` es idéntico al de la fuente oficial (comprobado localmente comparando ambos JSON); solo difieren `fecha_registro_utc` y la versión del servidor PostgreSQL en el contexto. Por eso los resultados de Mateo siguen siendo válidos para el lote migrado.

Versiones informadas por Mateo: MongoDB Server `9.0.4`, `mongosh 2.14.0` y PostgreSQL `17.10` mediante `psql`. El contexto de `extraccion_20261029_102959.json` (anexo) registra PostgreSQL Server `17.10` y la captura SQL muestra el uso de `psql`; no acredita la versión del cliente. Las versiones de MongoDB Server y mongosh no quedan comprobadas mediante los archivos o capturas disponibles. Estos registros no prueban por sí solos autoría ni máquina de ejecución.

- Subconjunto común: pedidos `1, 2, 3, 4 y 5`.
- Estado elegido: `ENTREGADO`, existente en los cinco pedidos del lote.
- Producto elegido: ID `1`, presente en los pedidos `1, 3 y 5`.
- Umbral de la consulta d): total estrictamente mayor que `Decimal128("3000.00")`. El lote suma `14700.00` en cinco pedidos, con un promedio de `2940.00`; el umbral selecciona los pedidos con total por encima del promedio y excluye el de `2800.00`, cercano a él.
- Origen documentado: PostgreSQL `foodstore_dev.public`; destino documentado: MongoDB `foodstore_unidad7.pedidos`.
- Fuente oficial del lote: [extraccion_20261028_170446.json](../evidencias/extraccion_20261028_170446.json), SHA-256 `3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`.
- Anexo de la prueba local de Mateo: [extraccion_20261029_102959.json](../evidencias/extraccion_20261029_102959.json). El hash `0e17c782de3063ec88fd871251b848aedac4084d4620663b336475f0db1b794f` corresponde a su copia local con finales CRLF; la copia versionada en el repositorio, con finales LF, da `cece1385d89c038b25c268799e812c4a0773fa4c2a4bd4bd6141de66cda9dd09`. Este archivo no es la fuente operativa de la migración.

## Evidencias

Ejecución de Mateo, 2026-10-29:

- [Salida de MongoDB — consignas 4–5](../evidencias/consultas_mongodb_consignas_4_5.png)
- [Salida de PostgreSQL — consignas 4–5](../evidencias/consultas_postgresql_consignas_4_5.png)
- [Verificación de migración de Mateo](../evidencias/migracion_verificacion_mateo_20261029.png)

Reejecución de Amanda, 2026-11-01:

- [PostgreSQL: b) y c)](../evidencias/consultas_postgresql_amanda.png)
- [MongoDB 1: base, conteo, script y parámetros](../evidencias/consultas_mongodb_amanda_1.png)
- [MongoDB 2: a), b) e inicio de c)](../evidencias/consultas_mongodb_amanda_2.png)
- [MongoDB 3: c) y d) completas, hasta el prompt final](../evidencias/consultas_mongodb_amanda_3.png)

Fuentes de datos:

- [Fuente oficial de la migración](../evidencias/extraccion_20261028_170446.json)
- [Anexo: extracción de la prueba local de Mateo](../evidencias/extraccion_20261029_102959.json)

## Reejecución de Amanda — 2026-11-01

Según lo informado por Amanda, ejecutó manualmente en su computadora las consultas de solo lectura, sin modificar ningún script. El asistente no ejecutó motores: inspeccionó las capturas y documentó los resultados.

**PostgreSQL**, desde Git Bash en la raíz del repositorio:

```bash
psql -X -U postgres -d foodstore_dev -f TP1_FoodStore_NoSQL/postgresql/consultas_postgresql.sql
```

- b) 5 filas: pedidos 1, 2, 3, 4 y 5, todos `ENTREGADO`.
- c) 3 filas: pedidos 1, 3 y 5 con producto 1; cantidades 2, 3 y 1; precios unitarios 1000.00, 1050.00 y 1050.00.

**MongoDB**, en la shell integrada de Compass sobre `foodstore_unidad7`: `db.pedidos.countDocuments()` devolvió `5`; luego se pegó completo [consultas_mongodb.js](../mongodb/consultas_mongodb.js).

- a) y b) 5 pedidos: `_id` Long 1–5, todos `ENTREGADO`.
- c) Pedidos 1, 3 y 5, cada uno con su línea del producto `Long('1')` (`Muzzarella`): cantidades 2, 3 y 1; `precio_unitario` Decimal128 1000.00, 1050.00 y 1050.00; `subtotal` Decimal128 2000.00, 3150.00 y 1050.00.
- d) Pedidos 3 (`total` Decimal128 3150.00) y 4 (`total` Decimal128 6200.00).

Estas capturas completan la evidencia de c) y d) en MongoDB, que la captura de Mateo no mostraba completa. Los resultados coinciden con los informados por Mateo, que se conservan sin cambios. El comentario de la consulta d) del script se actualizó después de esta ejecución, por lo que la captura 1 muestra la redacción anterior; el código ejecutado no cambió. Las capturas no acreditan las versiones de MongoDB Server ni de Compass usadas por Amanda.

## Parámetros y equivalencia

Las consultas b) usan el mismo estado y las consultas c) el mismo ID de producto. En MongoDB se filtra `lineas.id_producto` y se proyecta la línea coincidente; en PostgreSQL se une `detalle_pedido` y se conserva `cantidad` junto con `precio_unitario`. En ambos casos se cuentan pedidos distintos mediante sus IDs, no filas ajenas al lote.

## Resultados comparados

Resultados de la ejecución de Mateo, confirmados por la reejecución de Amanda.

| Consulta | Parámetro | Cantidad PostgreSQL | IDs PostgreSQL | Cantidad MongoDB | IDs MongoDB | Coinciden los IDs | Evidencia |
|---|---|---|---|---|---|---|---|
| b) Estado | `ENTREGADO` | 5 | 1, 2, 3, 4, 5 | 5 | 1, 2, 3, 4, 5 | Sí | [psql Mateo](../evidencias/consultas_postgresql_consignas_4_5.png), [psql Amanda](../evidencias/consultas_postgresql_amanda.png), [mongosh Mateo](../evidencias/consultas_mongodb_consignas_4_5.png), [Compass Amanda](../evidencias/consultas_mongodb_amanda_2.png) |
| c) Producto | ID `1` | 3 | 1, 3, 5 | 3 | 1, 3, 5 | Sí | [psql Mateo](../evidencias/consultas_postgresql_consignas_4_5.png), [psql Amanda](../evidencias/consultas_postgresql_amanda.png), [Compass Amanda](../evidencias/consultas_mongodb_amanda_3.png) |

Consulta d), solo en MongoDB (la consigna 5 compara b) y c)): total mayor que `Decimal128("3000.00")` devolvió los pedidos 3 y 4, con totales 3150.00 y 6200.00. Evidencia: [Compass Amanda](../evidencias/consultas_mongodb_amanda_3.png).

## Interpretación

Coinciden las cantidades y los IDs en ambos motores: b) devuelve los cinco pedidos con estado `ENTREGADO`, y c) devuelve los pedidos 1, 3 y 5 que contienen el producto 1. En c), ambos motores también conservaron las cantidades y precios históricos: (1, 2, 1000.00), (3, 3, 1050.00) y (5, 1, 1050.00). La consulta d) devolvió los pedidos 3 y 4, los únicos con total por encima del promedio del lote. La comparación queda limitada al subconjunto migrado y a las ejecuciones registradas; no demuestra sincronización futura.
