# Resultado de la migración de pedidos — FoodStore, Unidad 7

Fecha del registro documental: 2026-10-28. Ejecución manual: Amanda Pagano, en la shell de MongoDB Compass, según su comunicación. Revisión del asistente: lectura del script y documentación, inspección visual de las dos capturas originales y comprobación local del hash de la extracción. El asistente no ejecutó la migración ni se conectó a PostgreSQL o MongoDB para esta revisión.

## Procedimiento y trazabilidad

1. Según lo informado por Amanda, ejecutó manualmente la [extracción de solo lectura](../postgresql/extraccion_pedidos.sql) desde `foodstore_dev.public`. Su [archivo JSON](../evidencias/extraccion_20261028_170446.json) fue validado previamente: cinco pedidos, siete líneas y controles satisfactorios. La revisión de ese archivo se detalla en el [plan de trabajo](plan_trabajo.md).
2. Se preparó [migracion_pedidos.js, versión histórica de Amanda](https://github.com/ALucrecia-Pagano/Bases-de-datos-II-NoSQL/blob/73ee80a6c5b35b75491d81ebf30c03371a88ec68/mongodb/migracion_pedidos.js) para leer ese archivo y comprobar su SHA-256 antes de construir el lote. No se transcribieron manualmente los datos de carga. IDs e importes se convierten desde texto; los cálculos se controlan con BigInt en centavos y las fechas se comprueban antes de convertirlas a Date.
3. Durante la validación manual en Compass, Amanda informó `ReferenceError: Buffer is not defined`. Se incorporó `const { Buffer } = require("buffer");` junto a los demás módulos dentro del `try`, conservando el hash y los controles. La incidencia y el ajuste se registran en [mongodb/README.md](../mongodb/README.md).
4. Amanda informó que ejecutó el modo `insertar` en `foodstore_unidad7.pedidos`. La primera captura muestra la validación local satisfactoria y la inserción confirmada de los cinco IDs. El script comprueba los IDs existentes antes de insertar con `insertMany` ordenado.
5. La segunda captura muestra la salida de verificación satisfactoria. El script incluye una verificación posterior a la inserción y un modo independiente `verificar`; las capturas no permiten determinar si esa salida procede de una ejecución independiente o de la verificación integrada. En ambos casos, la salida documentada corresponde a la comprobación del lote fuente.

Referencia permanente del procedimiento: commit `73ee80a6c5b35b75491d81ebf30c03371a88ec68`, ruta histórica `mongodb/migracion_pedidos.js`, comprobado mediante `git show`. Contiene `FUENTE` y `SHA` de Amanda y la importación de `Buffer`. El traslado posterior ajustó rutas; el [script compartido actual](../mongodb/migracion_pedidos.js) conserva `FUENTE` y `SHA` de esta fuente oficial; una revisión intermedia los había cambiado para la extracción del 29/10 del anexo de Mateo, y esa configuración se revirtió. La existencia de esta versión en Git no demuestra por sí sola qué bytes se pegaron en Compass; la ejecución se atribuye a lo informado por Amanda y a las salidas visibles.

Fuente del lote en la ejecución histórica: `evidencias/extraccion_20261028_170446.json`. Ubicación actual desde la raíz del repositorio: `TP1_FoodStore_NoSQL/evidencias/extraccion_20261028_170446.json`.

El traslado organizativo no modifica las capturas, el JSON ni el PDF original. Las rutas visibles en esas evidencias corresponden a la estructura anterior; no acreditan una nueva ejecución con las rutas actuales.

SHA-256 de sus bytes originales, coincidente con ambas capturas y comprobado localmente en esta revisión:

```text
3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243
```

## Resultados observados en las capturas

| Evidencia | Resultado visible | Alcance documental |
|---|---|---|
| [migracion_insercion.png](../evidencias/migracion_insercion.png) | Modo `insertar`; destino `foodstore_unidad7.pedidos`; cinco pedidos, siete líneas; `validacionLocal: 'satisfactoria'`; `insercionConfirmada: true`; IDs `Long('1')`, `Long('2')`, `Long('3')`, `Long('4')` y `Long('5')`. | Acredita la salida de confirmación de inserción mostrada por el script ejecutado manualmente por Amanda. |
| [migracion_verificacion_amanda.png](../evidencias/migracion_verificacion_amanda.png) | `verificacion: 'satisfactoria'`; `pedidos: 5`; `lineas: 7`; `tiposBSON: 'correctos'`; `correspondencia: 'todos los campos del lote fuente'`; prompt `foodstore_unidad7>`. | Acredita la salida satisfactoria del procedimiento de verificación sobre el lote. |

Ambas imágenes muestran la misma referencia al archivo fuente y el SHA-256 indicado. Se conservaron sin cambios; esta documentación las enlaza sin recortarlas ni reemplazarlas.

### Evidencia complementaria: documento del pedido 1

La [captura del documento](../evidencias/pedido_1_documento.png), inspeccionada visualmente, muestra la selección de `foodstore_unidad7` y `db.pedidos.findOne({ _id: Long("1") })`. La salida contiene `_id: Long('1')`, fecha `2026-03-01T23:30:00.000Z`, forma de pago `EFECTIVO`, estado `ENTREGADO`, cliente con ID Long 1 y alias `Cliente 1`, y dos líneas: producto Long 1, Muzzarella, cantidad 2, precio Decimal128 1000.00 y subtotal 2000.00; producto Long 3, Coca 1.5L, cantidad 1, precio Decimal128 800.00 y subtotal 800.00. El total visible es Decimal128 2800.00.

Esta captura ilustra un documento y su estructura; no muestra el hash ni verifica el lote completo, el tipo BSON de las cantidades o el estado actual de las bases. No sustituye las dos capturas de inserción y verificación ni acredita las consultas pendientes de las consignas 4–5. El asistente inspeccionó la imagen sin ejecutar la consulta ni modificarla.

## Qué comprueba el procedimiento

Según la lectura de la versión histórica enlazada, la salida satisfactoria se emite después de comprobar:

- Cinco documentos recuperados por los IDs del lote y siete líneas en total.
- Tipos BSON mediante `$type` en una agregación del servidor: `long` para IDs del pedido, cliente y productos; `int` para cantidades; `date` para fecha; `decimal` para precios, subtotales y total.
- Correspondencia de todos los campos y valores con los documentos generados desde la extracción, mediante Extended JSON canónico. Se ignora el orden de las claves de los objetos, pero se conserva y compara el orden de los arreglos.
- Antes de insertar: hash de la fuente, contexto de extracción, lote completo, productos sin duplicados por pedido, cantidades positivas, importes no negativos, fórmulas exactas y fechas sin pérdida de precisión submilisegundo. La igualdad posterior con ese lote vincula la verificación final con estos controles previos.

Esta explicación proviene de la revisión del código y de la salida mostrada; no equivale a una nueva ejecución de los controles por el asistente. El cliente conserva solo ID y alias sintético; se excluyen observaciones y datos personales del cliente. Los nombres de productos son descripciones actuales del origen, mientras que los precios proceden del detalle histórico.

Comprobación local de la extracción original de Amanda, sin motores: cinco pedidos y siete líneas; cantidades enteras positivas, importes finitos no negativos, cada subtotal igual a cantidad por precio histórico y total igual a suma de subtotales, mediante aritmética decimal exacta. Totales de pedidos 1–5: **2800.00, 1500.00, 3150.00, 6200.00 y 1050.00**. Esta comprobación del archivo no es una consulta nueva a las bases.

## Límites de la verificación

- Las dos capturas de inserción y verificación muestran resúmenes de salida. La captura complementaria muestra el documento del pedido 1; no hay una transcripción íntegra de la sesión ni capturas de todos los documentos. El detalle del mecanismo se obtiene de la versión histórica enlazada.
- La comprobación cubre los IDs 1–5 del lote; no demuestra que la colección contenga únicamente esos documentos ni verifica otros pedidos.
- La comparación se realiza contra la extracción guardada. No es una comparación nueva contra el estado actual de PostgreSQL ni prueba sincronización futura entre motores.
- No se instalaron validadores permanentes. La verificación de una carga no garantiza que futuras escrituras mantengan las reglas de integridad.
- Una inserción ordenada no constituye una transacción de todo el lote. El resultado satisfactorio de esta ejecución no demuestra que los mecanismos de error o concurrencia se hayan ensayado. No se documentan reintentos ni recuperaciones automáticas.
- `retryWrites=false` es un requisito de las instrucciones de ejecución, pero no aparece en estas capturas y no se acredita su configuración mediante ellas.
- La fecha indicada arriba es la del registro documental. No se infiere una hora exacta de migración a partir de los nombres de las imágenes o de la fecha de la extracción. Las versiones de MongoDB Server y Compass siguen pendientes de registrar.

## Estado académico y siguientes tareas

La migración del lote está **ejecutada manualmente por Amanda y verificada según las evidencias inspeccionadas**. Este registro no declara aprobación grupal del diseño ni resuelve la consulta pendiente sobre suficiencia académica del cliente con ID y alias.

Las consultas y comparación de las consignas 4 y 5 fueron aportadas posteriormente, con ejecución informada por Mateo; la reejecución de Amanda del 2026-11-01 completó sus evidencias, con resultados coincidentes, según [comparacion_resultados.md](comparacion_resultados.md). Las consignas 6 y 7 fueron aportadas por Lucas en [contraste_ia.md](contraste_ia.md); queda pendiente la captura de la respuesta original de Gemini, además de la revisión grupal de conclusión e informe. Las verificaciones internas de migración no sustituyen las evidencias específicas de las consultas.
