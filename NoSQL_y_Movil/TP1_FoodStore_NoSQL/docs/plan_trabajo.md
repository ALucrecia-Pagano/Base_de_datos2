# Plan de trabajo — FoodStore, Unidad 7 NoSQL

Las atribuciones de ejecución a Amanda y Mateo y las referencias a sus máquinas corresponden a lo informado por los integrantes; Git y los JSON no demuestran por sí solos autoría ni máquina de ejecución. No deben presentarse como una única ejecución; ambos aportes se integran en la entrega grupal.

Las consultas y la comparación de las consignas 4–5 fueron aportadas, con ejecución informada por Mateo. Su captura MongoDB no mostraba completas c) ni d); la reejecución de Amanda del 2026-11-01, con los mismos scripts, completa esa evidencia con resultados coincidentes. Los resultados de Mateo se conservan.

## Alcance

Preparar un modelo de pedidos con detalles y datos esenciales del cliente; migrar al menos cinco pedidos desde PostgreSQL a MongoDB conservando identificadores, instantes de fecha, estados, cantidades y precios históricos. Las reglas comunes están en [AGENTS.md](../../AGENTS.md) y el flujo colaborativo en [CONTRIBUTING.md](../../../CONTRIBUTING.md).

Referencia académica principal: [consigna oficial de Unidad 7](../consignas/BDII_Unidad7_TP_FoodStore_NoSQL.pdf), leída el 2026-10-28. Según lo informado por los integrantes, la migración de Amanda fue ejecutada manualmente el 2026-10-28 a partir de su extracción y sus capturas. Posteriormente, Mateo realizó un trabajo independiente el 2026-10-29 con otra extracción y sus propias evidencias. No deben presentarse como una única ejecución; ambos aportes se integran en la entrega grupal. El [modelo documental](modelo_documental.md) fue aprobado por el equipo con el informe final.

### Precisiones de la consigna oficial frente a los documentos iniciales

- No se detectaron requisitos incompatibles de modelo o entrega. La consigna 2 exige un mínimo de cinco pedidos aunque el alcance introductorio lo presenta como recomendación.
- El PDF permite agregar pedidos de prueba si faltan registros. El equipo informó cinco y mantiene el acuerdo más restrictivo de conservar PostgreSQL sin modificaciones; no es necesario incorporar datos.
- La consigna 6 exige que la consulta a IA mencione el modelo actual, el acceso frecuente a pedidos completos y la coherencia de cantidades y precios. Esto deberá contemplarse al completar esa etapa.
- La consigna 7 exige una conclusión de hasta 200 palabras sustentada en al menos dos criterios técnicos, evaluando PostgreSQL, MongoDB para el subconjunto o combinación.
- El PDF final debe incluir evidencias legibles y código con instrucciones efectivamente ejecutadas; excluye imágenes decorativas, transcripciones extensas y datos personales reales. Las plantillas actuales aún no constituyen esa entrega.
- La página 3 aclara que los nombres teóricos son ilustrativos: se emplean las tablas y columnas reales aportadas por Amanda. El requisito de datos esenciales del cliente no precisa atributos mínimos; la suficiencia de ID más alias queda pendiente de confirmación docente.

## Responsabilidades acordadas

| Integrante | Consignas | Trabajo |
|---|---|---|
| Amanda | 1, 2 y 3 | Modelo documental, migración y reglas de integridad |
| Mateo | 4 y 5 | Consultas y comparación entre motores |
| Lucas | 6 y 7 | Consulta a IA, contraste y borrador de conclusión |

El equipo completo revisa la conclusión y el informe final. Cada integrante trabaja en su rama y presenta un pull request.

## Secuencia y estado de avance

1. **Realizado:** preparación de estructura, reglas y plantillas.
2. **Redactado e implementado:** diseño de consignas 1 y 3, con correspondencia, tipos BSON, ejemplo e integridad. Aprobado por el equipo con el informe final (2026-11-01), según [decisiones.md](decisiones.md). **Pendiente:** confirmación docente de la suficiencia de ID más alias.
3. **Realizado:** extracción y código de migración con detección de IDs existentes, sin reemplazos silenciosos. La aprobación documental no autoriza nuevas ejecuciones.
4. **Realizado por Amanda:** ejecución manual de su extracción y migración el 2026-10-28, con conservación de datos y cantidades verificada según las evidencias del [resultado](resultado_migracion.md). No repetir esa inserción.
5. **Realizado (Mateo, con reejecución de Amanda):** ejecución informada por Mateo; prueba local independiente del 2026-10-29, con `extraccion_20261029_102959.json` conservada como anexo (mismo arreglo `extraccion` que la fuente oficial), sus evidencias y las consultas de MongoDB y PostgreSQL de las consignas 4–5. No reemplaza la migración de Amanda; la fuente oficial sigue siendo `extraccion_20261028_170446.json`. El 2026-11-01 Amanda reejecutó los mismos scripts y completó las evidencias MongoDB de c) y d), con resultados coincidentes; aporte en [aporte_mateo.md](../informe/aporte_mateo.md), con OK de Mateo del 2026-11-01.
6. **Aportado (Lucas, consignas 6–7):** consulta a Gemini, contraste de dos afirmaciones con documentación oficial y laboratorio, y borrador de conclusión en [contraste_ia.md](contraste_ia.md) y [aporte_lucas.md](../informe/aporte_lucas.md). La conversación con Gemini está respaldada por las capturas [1](../evidencias/gemini_lucas_1.jpeg), [2](../evidencias/gemini_lucas_2.jpeg), [3](../evidencias/gemini_lucas_3.jpeg), [4](../evidencias/gemini_lucas_4.jpeg) y [5](../evidencias/gemini_lucas_5.jpeg), aportadas por Lucas.
7. **Realizado (equipo):** informe final en [informe/](../informe/README.md), aprobado por el equipo (OK de Mateo y Lucas del 2026-11-01) y listo para entregar.

## Estado real

Registro de preparación: 2026-10-28. Las siguientes comprobaciones fueron aportadas por el equipo y no se repitieron en esta sesión:

- Windows 11; cliente psql 17.11 usado desde Git Bash.
- MongoDB Server en ejecución; Compass conectado; ping con resultado `ok: 1`.
- Base de origen `foodstore_dev`: cinco pedidos, siete líneas de detalle; todos los pedidos en estado `ENTREGADO`.
- Producto ID 1 presente en pedidos 1, 3 y 5.
- Precios históricos en `detalle_pedido.precio_unitario`.
- Estructura observada: `pedido` (id, id_cliente, fecha_hora timestamptz, forma_pago, estado, observaciones); `detalle_pedido` (id_pedido, id_producto, cantidad, precio_unitario, subtotal generado como cantidad × precio_unitario); `cliente` (id, nombre_completo, email, telefono, direccion, created_at); `producto` (id, id_categoria, nombre, descripcion, precio_lista, stock, activo, created_at).
- Clave primaria de detalle: (id_pedido, id_producto); cantidad > 0 y precio_unitario >= 0.

Ampliación de datos aportada por Amanda en el pedido de diseño: `precio_unitario` es `numeric(10,2)`; se conocen fechas, formas de pago, clientes por ID y las siete líneas. Sus totales calculados esperados, sin ejecución de motores, se documentan en el modelo: pedidos 1–5, respectivamente 2800.00, 1500.00, 3150.00, 6200.00 y 1050.00. No se conocen observaciones ni datos personales; no se completan por suposición.

Estado de la preparación documental:

- [x] Estructura, reglas de colaboración y plantillas creadas.
- [x] Consigna oficial leída y precisiones académicas registradas.
- [x] Diseño de consignas 1 y 3 redactado, con fuentes oficiales y ejemplo no ejecutado; [aporte de Amanda para consignas 1–3](../informe/aporte_amanda.md) redactado e integrado al informe aprobado.
- [x] [Script de extracción](../postgresql/extraccion_pedidos.sql) preparado y revisado estáticamente, sin conexión a motores.
- [x] Amanda informó que ejecutó manualmente la extracción; el asistente no la ejecutó.
- [x] Archivo de extracción comprobado localmente: JSON UTF-8, contexto, controles, cinco pedidos, siete líneas y fórmulas.
- [x] Versión PostgreSQL 17.11 registrada según el contexto de la extracción de Amanda.
- [x] Versiones de MongoDB y Compass registradas: Amanda informó MongoDB Server 9.0.4 y Compass 1.53.2, con mongosh integrado 2.9.2.
- [x] Destino, tipos BSON, tratamiento del cliente y método de migración implementados, documentados y aprobados por el equipo con el informe final.
- [ ] Modelo y reglas de integridad revisados y aprobados por el equipo.
- [ ] Suficiencia de cliente con ID más alias confirmada con equipo/docente.
- [x] Tipos/rangos y precisión de fecha del lote comprobados según la extracción y los controles documentados; tipos BSON verificados según las evidencias de migración.
- [x] Código de migración preparado desde el archivo real de Amanda, con instrucciones y verificaciones posteriores; el script actual vuelve a usar esa fuente oficial y su SHA-256, después de una revisión intermedia del historial configurada con la extracción del anexo de Mateo.
- [x] Amanda informó la ejecución manual de su migración en Compass; se inspeccionaron sus capturas de inserción y verificación.
- [x] Migración de Amanda de cinco pedidos y siete líneas ejecutada el 2026-10-28 y verificada según sus evidencias inspeccionadas.
- [x] Consignas 4–5: consultas y comparación aportadas, con ejecución informada por Mateo.
- [x] Consignas 4–5: evidencias MongoDB de c) y d) completadas por la reejecución de Amanda del 2026-11-01.
- [x] Consignas 6–7: consulta a IA, contraste de dos afirmaciones y borrador de conclusión aportados (Lucas).
- [x] Informe final integrado (PDF) y conclusión aprobados por el equipo: OK de Mateo y Lucas del 2026-11-01. Listo para entregar.
- [ ] Confirmación docente del cliente con ID más alias.
- [ ] Corrección de la cátedra.

## Entregables

### Extracción preparada y ejecución manual documentada mediante archivo

El archivo [postgresql/extraccion_pedidos.sql](../postgresql/extraccion_pedidos.sql) usa una transacción `REPEATABLE READ, READ ONLY` con `ROLLBACK` final sobre `foodstore_dev`, esquema `public`, pedidos 1–5. Comprueba base y muestra versión del servidor en el informe. Conserva pedidos o líneas faltantes mediante `LEFT JOIN` y `FULL JOIN`, informa existencia de referencias, duplicados, cantidades, importes y fórmulas. Las referencias de cinco pedidos y siete detalles proceden de Amanda, no de una ejecución del asistente.

La salida es un informe JSON con controles y un arreglo `extraccion` ordenado por pedido y producto. IDs e importes se serializan como texto; los totales se obtienen mediante aritmética `NUMERIC`. Las fechas se muestran en ISO 8601 UTC con seis cifras fraccionarias para no ocultar microsegundos. Una anomalía bloquea la extracción (`null`), incluidas fechas submilisegundo o referencias previas que ya no coincidan; los controles permanecen visibles para revisión. No genera BSON ni instrucciones de inserción.

La base de diseño indicada por Amanda para preparar este script es `foodstore_unidad7.pedidos`, cliente con ID y alias sintético, Long para IDs, Int32 para cantidades, Date para fechas y Decimal128 para importes. Esto no se registra como aprobación del diseño por el equipo. **Se excluyen todas las observaciones del subconjunto**, además de nombres y contactos personales del cliente: no son necesarios para esta extracción y pueden contener información sensible. El nombre del producto es descriptivo y actual; el precio se toma del detalle histórico.

Revisión documental: los enlaces relativos de los tres documentos de diseño resuelven a sus archivos y no se encontraron escapes Markdown incorrectos en los textos guardados; no se alteraron modelo ni decisiones. No se modificaron los archivos de consultas de Mateo.

Documentación oficial usada para la revisión estática inicial (consulta: 2026-10-28): [BEGIN](https://www.postgresql.org/docs/17/sql-begin.html), [JSON](https://www.postgresql.org/docs/17/functions-json.html), [fechas y date_trunc](https://www.postgresql.org/docs/17/functions-datetime.html), [formato de fechas](https://www.postgresql.org/docs/17/functions-formatting.html) y [psql](https://www.postgresql.org/docs/17/app-psql.html). En esa preparación no se conectó a un servidor. La ejecución posterior fue realizada manualmente por Amanda y su archivo se comprobó como se detalla a continuación.

### Extracción comprobada y migración preparada — 2026-10-28

Al listar `evidencias/extraccion_*.json` solo se encontró [extraccion_20261028_170446.json](../evidencias/extraccion_20261028_170446.json); por nombre es la más reciente disponible. Aunque Amanda mencionó una nueva ejecución, no se encontró un segundo archivo y no se presume su contenido. SHA-256 del original: `3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`.

Comprobaciones locales sobre el archivo: JSON UTF-8 válido, sin claves duplicadas; contexto `foodstore_dev.public`, `repeatable read`, `solo_lectura: on`; controles generales verdaderos incluido `extraer`; cinco pedidos con IDs 1–5 y siete líneas. Los controles detallados informan referencias existentes, tipos bigint/integer y ausencia de submilisegundos; se comprobaron además cantidades, productos sin duplicados, fórmulas y totales mediante aritmética decimal exacta sobre los valores del archivo. El contexto registra servidor PostgreSQL 17.11 y fecha UTC `2026-10-28T20:04:47.783674Z`. Son comprobaciones de una evidencia de Amanda, no una nueva ejecución del asistente en PostgreSQL.

Se preparó [mongodb/migracion_pedidos.js](../mongodb/migracion_pedidos.js), que lee el archivo real y comprueba su hash antes de generar documentos BSON. Valida el lote completo, calcula con BigInt en centavos, bloquea pérdida de precisión temporal y comprueba todos los IDs destino antes de insertar ordenadamente. Incluye modo local `validar`, modo `insertar` y modo de lectura `verificar`. Se exige conexión con `retryWrites=false`; una inserción ordenada puede dejar una carga parcial y no hay recuperación automática.

Las [instrucciones de MongoDB](../mongodb/README.md) explican ejecución manual desde Compass y alternativa externa si la shell integrada restringe archivos o módulos; no se supone mongosh externo instalado. La comprobación posterior incluye cinco documentos, siete líneas, tipos BSON evaluados en servidor y correspondencia campo por campo con el lote fuente. La preparación inicial fue seguida por la ejecución manual de Amanda, documentada a continuación. No se cambia el estado de aprobación grupal ni se modifican evidencias originales o consultas de Mateo.

### Migración ejecutada por Amanda y revisión documental — 2026-10-28

Se inspeccionaron visualmente [migracion_insercion.png](../evidencias/migracion_insercion.png) y [migracion_verificacion_amanda.png](../evidencias/migracion_verificacion_amanda.png). La primera muestra destino `foodstore_unidad7.pedidos`, validación local satisfactoria, `insercionConfirmada: true` e IDs `Long` 1–5. La segunda muestra `verificacion: satisfactoria`, cinco pedidos, siete líneas, `tiposBSON: correctos` y correspondencia con todos los campos del lote fuente. Ambas refieren a `extraccion_20261028_170446.json` y al SHA-256 consignado arriba, que se comprobó nuevamente sobre el archivo local.

El [resultado de migración](resultado_migracion.md) registra procedimiento, resultados y límites. Amanda realizó la ejecución en Compass; el asistente revisó archivos y capturas, sin conectarse a motores. Para Compass fue necesaria la importación explícita de `Buffer` mediante `require("buffer")`, sin cambiar la evidencia ni su hash. La hora exacta de migración, las versiones de MongoDB/Compass y la configuración efectiva de `retryWrites` no se acreditan en las imágenes; Amanda informó después las versiones (MongoDB Server 9.0.4, Compass 1.53.2, mongosh integrado 2.9.2).

Las verificaciones de migración no completan por sí solas las consignas 4–5 ni 6–7. Las consignas 4–5 se documentan en la sección siguiente y las 6–7 en [contraste_ia.md](contraste_ia.md); el diseño fue aprobado por el equipo con el informe final.

### Consultas 4–5: ejecución informada por Mateo — 2026-10-29

Mateo informó la ejecución de las cuatro consultas MongoDB y las equivalentes PostgreSQL de b) y c) en su entorno local, así como la validación e inserción de su lote. La captura de verificación muestra cinco pedidos, siete líneas, tipos BSON correctos y correspondencia con la extracción del 29/10; no acredita por sí sola la inserción previa. MongoDB Server 9.0.4 y mongosh 2.14.0 son versiones informadas, no comprobadas en las capturas disponibles. PostgreSQL 17.10 consta en el contexto del JSON del 29/10; el uso de psql se ve en la captura SQL.

El 2026-11-01 Amanda reejecutó manualmente los mismos scripts en su computadora (PostgreSQL con `psql`, MongoDB en la shell de Compass) y obtuvo los mismos resultados, con salidas completas de a)–d) en sus capturas.

Resultados aportados por Mateo y confirmados por la reejecución de Amanda:

- MongoDB y PostgreSQL devolvieron los IDs 1–5 para el estado `ENTREGADO`.
- Ambos motores devolvieron los IDs 1, 3 y 5 para el producto ID 1.
- Las cantidades y precios históricos coincidieron: (1, 2, 1000.00),
  (3, 3, 1050.00) y (5, 1, 1050.00).
- MongoDB devolvió los pedidos 3 y 4 para totales mayores que 3000.00.

La comparación completa está en [comparacion_resultados.md](comparacion_resultados.md).
Las capturas de las salidas de `mongosh` y `psql` deben conservarse como
evidencias legibles junto con el informe; no deben incluir contraseñas.

### Entrega académica prevista

- PDF de hasta cinco páginas, sin contar código adjunto, con conclusión de hasta 200 palabras.
- [consultas_mongodb.js](../mongodb/consultas_mongodb.js) y [consultas_postgresql.sql](../postgresql/consultas_postgresql.sql): consultas ejecutables de las consignas 4–5.
- Modelo, comparación y contraste en los documentos de `docs/`; evidencias según [su guía](../evidencias/README.md).
- Esquema y requisitos del informe en [informe/README.md](../informe/README.md).

Esta documentación no autoriza nuevas conexiones ni ejecuciones en motores. El diseño fue aprobado por el equipo con el informe final; la extracción local de Mateo, la migración y las consultas de las consignas 4–5 quedan documentadas con sus resultados y límites. Las evidencias de 4–5 quedaron completas con la reejecución de Amanda y el contraste de IA fue aportado por Lucas. El informe final fue aprobado por el equipo (OK de Mateo y Lucas del 2026-11-01) y está listo para entregar; Lucas aportó las capturas de la conversación con Gemini (ver el paso 6). Solo quedan pendientes la confirmación docente del cliente con ID más alias y la corrección de la cátedra.
