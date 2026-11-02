# Comparación de resultados — consignas 4 y 5

Responsable: Mateo, consignas 4–5. Referencias: [plan](plan_trabajo.md), [reglas](../../AGENTS.md) y [registro de evidencias](../evidencias/README.md).

## Contexto de ejecución

Mateo aportó las [consultas MongoDB](../mongodb/consultas_mongodb.js), las [consultas PostgreSQL](../postgresql/consultas_postgresql.sql) y su comparación, e informó su ejecución el 2026-10-29. La revisión estática de esos scripts muestra consultas de lectura; no se ejecutaron motores en esta revisión.

La fuente oficial de la migración (consigna 2) es [extraccion_20261028_170446.json](../evidencias/extraccion_20261028_170446.json), de Amanda, con SHA-256 `3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`; es la configurada en [migracion_pedidos.js](../mongodb/migracion_pedidos.js). Según lo informado, Mateo cargó y verificó los datos en su computadora usando su propia extracción del 29/10, que se conserva como anexo de esa prueba local independiente. Su arreglo `extraccion` es idéntico al de la fuente oficial (comprobado localmente comparando ambos JSON); solo difieren `fecha_registro_utc` y la versión del servidor PostgreSQL en el contexto. Por eso los resultados de Mateo siguen siendo válidos para el lote migrado.

Versiones informadas por Mateo: MongoDB Server `9.0.4`, `mongosh 2.14.0` y PostgreSQL `17.10` mediante `psql`. El contexto de `extraccion_20261029_102959.json` (anexo) registra PostgreSQL Server `17.10` y la captura SQL muestra el uso de `psql`; no acredita la versión del cliente. Las versiones de MongoDB Server y mongosh no quedan comprobadas mediante los archivos o capturas disponibles. Estos registros no prueban por sí solos autoría ni máquina de ejecución.

- Subconjunto común: pedidos `1, 2, 3, 4 y 5`.
- Estado elegido: `ENTREGADO`, existente en los cinco pedidos del lote.
- Producto elegido: ID `1`, presente en los pedidos `1, 3 y 5`.
- Umbral de la consulta d): total estrictamente mayor que `Decimal128("3000.00")`. Se justifica porque distingue los pedidos de mayor importe del lote y no incluye el total de `2800.00`.
- Origen documentado: PostgreSQL `foodstore_dev.public`; destino documentado: MongoDB `foodstore_unidad7.pedidos`.
- Fuente oficial del lote: [extraccion_20261028_170446.json](../evidencias/extraccion_20261028_170446.json), SHA-256 `3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`.
- Anexo de la prueba local de Mateo: [extraccion_20261029_102959.json](../evidencias/extraccion_20261029_102959.json). El hash `0e17c782de3063ec88fd871251b848aedac4084d4620663b336475f0db1b794f` corresponde a su copia local con finales CRLF; la copia versionada en el repositorio, con finales LF, da `cece1385d89c038b25c268799e812c4a0773fa4c2a4bd4bd6141de66cda9dd09`. Este archivo no es la fuente operativa de la migración.

## Evidencias

- [Salida de MongoDB — consignas 4–5](../evidencias/consultas_mongodb_consignas_4_5.png)
- [Salida de PostgreSQL — consignas 4–5](../evidencias/consultas_postgresql_consignas_4_5.png)
- [Verificación de migración de Mateo](../evidencias/migracion_verificacion_mateo_20261029.png)
- [Fuente oficial de la migración](../evidencias/extraccion_20261028_170446.json)
- [Anexo: extracción de la prueba local de Mateo](../evidencias/extraccion_20261029_102959.json)

## Alcance de la evidencia y estado de revisión

Las consultas y la comparación de las consignas 4–5 fueron aportadas, con ejecución informada por Mateo. La captura MongoDB disponible está recortada: no muestra completa c) ni la salida de d). Los resultados aportados se conservan; queda pendiente completar esas evidencias antes de cerrar la revisión de las consignas 4–5. La captura MongoDB muestra a), b) y parte de c), hasta el pedido 3; no permite verificar visualmente el resultado completo de c) ni el de d). La captura PostgreSQL sí muestra b) y c) completas. La verificación de migración no sustituye las salidas faltantes de consultas. Esta limitación no invalida ni elimina los resultados informados.

## Parámetros y equivalencia

Las consultas b) usan el mismo estado y las consultas c) el mismo ID de producto. En MongoDB se filtra `lineas.id_producto` y se proyecta la línea coincidente; en PostgreSQL se une `detalle_pedido` y se conserva `cantidad` junto con `precio_unitario`. En ambos casos se cuentan pedidos distintos mediante sus IDs, no filas ajenas al lote.

## Resultados comparados

Resultados aportados por Mateo; para c) en MongoDB y para d), se conservan como resultados informados con respaldo visual incompleto.

| Consulta | Parámetro | Cantidad PostgreSQL | IDs PostgreSQL | Cantidad MongoDB | IDs MongoDB | Evidencia |
|---|---|---|---|---|---|---|
| b) Estado | `ENTREGADO` | 5 | 1, 2, 3, 4, 5 | 5 | 1, 2, 3, 4, 5 | [psql](../evidencias/consultas_postgresql_consignas_4_5.png), [mongosh](../evidencias/consultas_mongodb_consignas_4_5.png) |
| c) Producto | ID `1` | 3 | 1, 3, 5 | 3 | 1, 3, 5 | [psql](../evidencias/consultas_postgresql_consignas_4_5.png), [mongosh](../evidencias/consultas_mongodb_consignas_4_5.png) |

## Interpretación

Según los resultados aportados por Mateo, coinciden las cantidades e IDs: b) devuelve los cinco pedidos con estado `ENTREGADO`, y c) devuelve los pedidos 1, 3 y 5 que contienen el producto 1. En c), ambos motores también conservaron las cantidades y precios históricos: (1, 2, 1000.00), (3, 3, 1050.00) y (5, 1, 1050.00). La consulta d) de MongoDB devolvió los pedidos 3 y 4, cuyos totales son 3150.00 y 6200.00. La comparación queda limitada al subconjunto migrado y a la ejecución registrada; no demuestra sincronización futura.
