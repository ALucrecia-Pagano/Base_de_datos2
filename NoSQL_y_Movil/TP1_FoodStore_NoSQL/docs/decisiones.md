# Registro de decisiones

Fecha del registro: 2026-10-28. Estados admitidos: propuesta, acordada o reemplazada. Fuente de los acuerdos siguientes: pedidos explícitos del equipo adjuntos a esta preparación; no son decisiones inferidas de nuevas ejecuciones.

| Estado | Decisión y motivo | Fuente o comprobación | Consecuencias o pendientes |
|---|---|---|---|
| Acordada | Preparar únicamente estructura y documentación de la Unidad 7 NoSQL para organizar el TP. | Pedidos del equipo; README existente leído. | Conservar README; no implementar consultas, validadores ni migración ni generar PDF en esta etapa. |
| Acordada | Amanda cubre 1–3, Mateo 4–5 y Lucas 6–7 para distribuir el trabajo. | Distribución expresada por el equipo y README. | Conclusión e informe con revisión grupal. |
| Acordada | Trabajar en ramas y revisar mediante pull request para coordinar la integración. | Acuerdo expresado por el equipo. | Comprobar configuración de GitHub; no se acreditó protección de main ni revisión obligatoria. Amanda realiza commits y pushes salvo nuevo pedido explícito. |
| Acordada | Conservar PostgreSQL sin modificaciones para preservar el origen. | Acuerdo del equipo para preservar el origen. | Autorizar por separado conexiones y ejecuciones por etapa y destino. Guardar un script no autoriza ejecutarlo. |
| Acordada | Conservar IDs, instantes, estados, cantidades y precios históricos; usar detalle_pedido.precio_unitario. | Requisitos aportados y estructura de origen informada por el equipo. | Justificar representación BSON antes de implementar; no usar precios de lista actuales para sustituir históricos. |
| Acordada | No publicar datos personales reales ni secretos; conservar originales y publicar evidencias anonimizadas. | Requisitos explícitos de privacidad y evidencias. | Resolver tratamiento de datos esenciales del cliente antes de migrar. |

## Decisiones pendientes — registro inicial

- Nombre de la base y colección MongoDB.
- Tipos BSON para identificadores, fechas e importes y justificación de precisión.
- Tratamiento de los datos esenciales del cliente.
- Método de migración y manejo de conflictos de IDs, sin reemplazos silenciosos.

Los acuerdos de la preparación inicial se conservan como antecedentes de esa etapa. El pedido posterior autoriza redactar el diseño de las consignas 1 y 3, sin aprobarlo ni implementar la migración. Las alternativas siguientes se proponen para revisión; no reemplazan decisiones acordadas.

## Propuestas de diseño — registro inicial 2026-10-28

Referencia académica principal: [consigna oficial](../consignas/BDII_Unidad7_TP_FoodStore_NoSQL.pdf), páginas 1–3. Detalles y fuentes técnicas S1–S8: [modelo documental](modelo_documental.md#8-fuentes-oficiales-consultadas-y-dudas). Sintaxis contrastada con documentación oficial; sin ejecución en motores.

| Estado | Decisión propuesta y motivo | Fuente o comprobación | Consecuencias o pendientes |
|---|---|---|---|
| Propuesta | Base `foodstore_unidad7`, colección `pedidos`, un documento por pedido con cliente y líneas embebidos para consultar el pedido completo. | Consignas 1–3; MongoDB Embedded Data (S3). | Aprobar nombres y estructura; no se crearon base ni colección. Las copias descriptivas no se sincronizan automáticamente. |
| Propuesta | Conservar `pedido.id` en `_id`; claves bigint como Long, cantidad como Int32, fecha como Date e importes como Decimal128. | Datos aportados; MongoDB Data Types y BSON Types (S1–S2). | Confirmar tipos y rangos reales, versiones y precisión de fechas. Rechazar pérdida submilisegundo; no usar Double para importes o IDs. |
| Propuesta | Cliente mínimo con ID y alias determinista `Cliente <id>`, excluyendo nombres y contactos reales. | Prohibición de datos personales en consigna oficial; pedido de Amanda. | El alias es transformación sintética. Confirmar con equipo/docente que satisface datos esenciales; no implica anonimización irreversible. |
| Propuesta | Incorporar nombre actual de producto como descripción; conservar exclusivamente el precio histórico del detalle. | Estructura y valores aportados por Amanda. | No afirmar historia de nombres. Observaciones desconocidas: omitir del ejemplo y revisar privacidad antes de incorporar valores reales. |
| Propuesta | Subtotales y total Decimal128 derivados con cálculo decimal exacto y comparación con el origen; futuras modificaciones conjuntas de líneas y total. | Reglas de consigna 3; S6 y S8. | Sin recálculo automático del motor. Requiere procedimiento correcto y validación adicional para garantizar reglas ante cualquier escritura. |
| Propuesta | Controlar positividad/no negatividad, fórmulas, IDs, productos únicos por pedido y existencia de referencias al extraer; verificar nuevamente tras cargar. | Consigna 3; PK compuesta informada; límites multikey (S4) y validación (S5). | No se instalaron validadores ni se verificaron estas condiciones en motores. |
| Propuesta | Extracción de solo lectura de los cinco pedidos y posterior archivo mongosh revisable con inserción ordenada; comprobar todos los IDs destino antes de escribir y detenerse ante conflictos. | Consigna 2 permite insertMany o equivalente; S7. | Aprobar método y autorizar etapas/destinos antes de implementar o ejecutar. Una inserción ordenada puede quedar parcial; no borrar, reemplazar o reintentar automáticamente. |

En el registro inicial estas elecciones estaban pendientes. La tabla anterior se conserva como trazabilidad de propuestas, no como descripción del estado de ejecución actual. No se registra aprobación grupal por el hecho de que una alternativa haya sido implementada. Para registros futuros indicar fecha real, estado, decisión, motivo, fuente o comprobación y consecuencias o pendientes; si una decisión se reemplaza, conservar su trazabilidad.

## Implementación documentada — 2026-10-28; aprobada por el equipo el 2026-11-01

Las filas siguientes registran hechos de implementación, no cambian las propuestas a estado «acordada». Fuente: pedidos posteriores de Amanda, [extracción original](../evidencias/extraccion_20261028_170446.json), [script de migración](../mongodb/migracion_pedidos.js) y [resultado con capturas inspeccionadas](resultado_migracion.md). El asistente realizó revisión documental, sin ejecutar motores.

| Propuesta inicial | Implementación documentada y motivo | Comprobación | Estado de aprobación y pendientes |
|---|---|---|---|
| Destino y embebido | Se utilizó `foodstore_unidad7.pedidos`, un documento por pedido con cliente y líneas embebidos, para leer pedidos completos. | Capturas de inserción/verificación y script. | Implementada; aprobada por el equipo con el informe final. |
| Identificadores y tipos | `_id` conserva `pedido.id`; IDs Long, cantidades Int32, fechas Date e importes Decimal128. | Extracción con tipos de origen y verificación BSON satisfactoria del lote. | Implementada, verificada según evidencias y aprobada por el equipo con el informe final. Versiones informadas por Amanda: MongoDB Server 9.0.4, Compass 1.53.2 y mongosh integrado 2.9.2. |
| Cliente, productos y observaciones | Se usaron ID y alias sintético del cliente, nombre actual de producto y precio histórico del detalle. Se excluyeron **todas** las observaciones y nombres/contactos personales, concretando la opción inicial de omitir o revisar observaciones. | Archivo fuente y campos que construye el script. | Tratamiento implementado y aprobado por el equipo; confirmación docente de la suficiencia del cliente pendiente. No hay historia de nombres acreditada. |
| Integridad y totales | Controles previos del lote, cálculo BigInt en centavos, detección de duplicados e IDs existentes, y comparación posterior completa con tipos BSON. | Script y salida de verificación satisfactoria: cinco pedidos y siete líneas. | Procedimiento ejecutado, sin validadores permanentes; las garantías no se extienden a futuras escrituras. |
| Método | Amanda extrajo con SQL de solo lectura y migró el JSON real con `insertMany` ordenado en Compass; se importó Buffer explícitamente para ese entorno. | Fuente y SHA-256 coincidentes con capturas; incidencia documentada en la guía MongoDB. | Ejecutado manualmente por Amanda. No es transacción del lote; no se ensayaron ni acreditaron recuperaciones automáticas. |

El archivo fuente conserva SHA-256 `3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`. Para compartirlo sin normalizar sus CRLF se añadió una regla `-text` para esa ruta exacta en [.gitattributes](../../../.gitattributes), autorizada en este pedido; el [traspaso](traspaso_equipo.md#conservación-del-hash-al-compartir) documenta la comprobación sin escribir objetos Git ni modificar evidencia.

El equipo aprobó estas elecciones con el informe final (OK de Mateo y Lucas del 2026-11-01), y las consignas 4–7 quedaron documentadas con sus resultados propios. Sigue pendiente la confirmación docente de ID más alias. Las versiones ya fueron informadas por Amanda: MongoDB Server 9.0.4, Compass 1.53.2 y mongosh integrado 2.9.2. La configuración efectiva de `retryWrites` y la hora exacta de migración no se deducen de las capturas. No se modifica el registro histórico ni se declara reemplazada una decisión grupal sin ese acuerdo.
