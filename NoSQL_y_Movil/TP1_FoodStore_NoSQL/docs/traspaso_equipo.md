# Traspaso al equipo — FoodStore, Unidad 7

Las atribuciones de ejecución a Amanda y Mateo y las referencias a sus máquinas corresponden a lo informado por los integrantes; Git y los JSON no demuestran por sí solos autoría ni máquina de ejecución. No deben presentarse como una única ejecución; ambos aportes se integran en la entrega grupal.

Las consultas y la comparación de las consignas 4–5 fueron aportadas, con ejecución informada por Mateo. Su captura MongoDB no mostraba completas c) ni d); la reejecución de Amanda del 2026-11-01, con los mismos scripts, completa esa evidencia con resultados coincidentes. Los resultados de Mateo se conservan.

Registro: 2026-10-28. Aplicar [AGENTS.md](../../AGENTS.md), [CLAUDE.md](../../../CLAUDE.md) y la [guía de colaboración](../../../CONTRIBUTING.md). Referencia académica principal: [consigna oficial](../consignas/BDII_Unidad7_TP_FoodStore_NoSQL.pdf). Este documento organizó el reparto de tareas; no registra nuevas ejecuciones ni autoriza operaciones en motores.

## Estado recibido y modelo implementado

Amanda ejecutó manualmente la migración en Compass. Las [capturas de inserción](../evidencias/migracion_insercion.png) y [verificación](../evidencias/migracion_verificacion_amanda.png), inspeccionadas en la revisión documental, muestran inserción confirmada de los IDs Long 1–5, cinco pedidos, siete líneas, tipos BSON correctos y correspondencia con todos los campos del lote fuente. Ver [resultado y límites](resultado_migracion.md). El diseño fue aprobado por el equipo con el informe final; la verificación de migración no completa por sí sola las consignas 4–7.

La migración de Amanda del 2026-10-28 y el trabajo independiente de Mateo del
2026-10-29, según lo informado por los integrantes, se realizaron en sus respectivas
máquinas. No deben presentarse como una única ejecución; ambos aportes se integran en la entrega grupal. La extracción, el hash y las evidencias de Amanda no se
sustituyen por la extracción ni por las evidencias de Mateo. La captura de
verificación de Amanda fue renombrada a
`migracion_verificacion_amanda.png`; ese renombrado no representa una nueva
ejecución.

Destino implementado: `foodstore_unidad7.pedidos`. Cada pedido contiene `_id`, `fecha_hora`, `forma_pago`, `estado`, objeto `cliente`, arreglo `lineas` y `total`.

| Campo | Tipo BSON | Significado |
|---|---|---|
| `_id`, `cliente.id`, `lineas[].id_producto` | Long (`long`) | IDs conservados del origen |
| `cliente.alias` | String | `Cliente <id>` sintético, no nombre real |
| `fecha_hora` | Date (`date`) | Mismo instante expresado en UTC; se comprobó que el lote no pierde precisión a milisegundos |
| `lineas[].cantidad` | Int32 (`int`) | Entero positivo |
| `lineas[].precio_unitario`, `lineas[].subtotal`, `total` | Decimal128 (`decimal`) | Precio histórico del detalle y valores derivados con aritmética exacta |
| `estado`, `forma_pago`, `lineas[].nombre_producto` | String | Valores del origen; nombre del producto descriptivo actual, no histórico acreditado |

Se excluyeron observaciones y nombres/contactos personales del cliente. El alias no garantiza anonimización irreversible de los IDs. Las dos reglas principales son cantidad positiva e importes no negativos; y subtotal igual a cantidad por precio histórico, con total igual a suma de subtotales. No hay validadores permanentes instalados.

## Archivos de referencia

| Archivo | Uso |
|---|---|
| [modelo_documental.md](modelo_documental.md) y [decisiones.md](decisiones.md) | Diseño inicial, implementación documentada y aprobación del equipo con el informe final |
| [extraccion_pedidos.sql](../postgresql/extraccion_pedidos.sql) | Extracción PostgreSQL de solo lectura del subconjunto 1–5 |
| [extraccion_20261028_170446.json](../evidencias/extraccion_20261028_170446.json) | Fuente real e inmutable de la migración de Amanda; controles y datos de intercambio |
| [extraccion_20261029_102959.json](../evidencias/extraccion_20261029_102959.json) | Anexo de la prueba local independiente de Mateo; mismo arreglo `extraccion` que la fuente oficial. No es fuente operativa del script |
| [migracion_pedidos.js](../mongodb/migracion_pedidos.js) y [guía MongoDB](../mongodb/README.md) | Conversión, comprobación de IDs, inserción y verificación; modos separados |
| [resultado_migracion.md](resultado_migracion.md) | Ejecución manual de Amanda y evidencia de resultados |
| [aporte_amanda.md](../informe/aporte_amanda.md) | Texto breve para integrar al PDF grupal |

SHA-256 obligatorio de la extracción original, configurado en `FUENTE` y `SHA` del script:

```text
3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243
```

## Reproducir en otra computadora

**GitHub comparte archivos del repositorio, no la base MongoDB local de Amanda.** Descargar el repositorio no crea `foodstore_unidad7.pedidos` ni sincroniza un servidor. Cada integrante necesita su propio entorno o una conexión expresamente acordada; no se distribuyen credenciales ni respaldos completos.

Solo para una reproducción futura autorizada en otra computadora:

1. Obtener los archivos del repositorio, incluida `.gitattributes`, sin editar ni reformatear el JSON. Verificar sus bytes con `sha256sum TP1_FoodStore_NoSQL/evidencias/extraccion_20261028_170446.json` en Git Bash; debe coincidir con el hash anterior. Si difiere, detenerse; no cambiar el hash del script para ocultar la diferencia.
2. Comprobar la conexión y versión MongoDB de esa computadora. Usar el destino `foodstore_unidad7.pedidos` y conexión con `retryWrites=false`, como indica la guía; no apuntar accidentalmente al entorno de Amanda. Compass fue el entorno usado por Amanda; mongosh externo no se supone instalado.
3. Establecer `globalThis.FOODSTORE_RAIZ` con la ruta absoluta del repositorio **en esa computadora**, usando `/` en Windows, y `globalThis.FOODSTORE_MODO = "validar"`. Ejecutar manualmente el script completo según la [guía](../mongodb/README.md). Este modo solo valida el archivo local y el lote BSON; no consulta el destino.
4. Solo si la validación y la autorización son satisfactorias, seleccionar `foodstore_unidad7`, establecer `FOODSTORE_MODO = "insertar"` y ejecutar el script. Antes de escribir, el script busca **todos** los IDs del lote en el destino. Deben estar ausentes: si existe cualquiera, se detiene sin insertar. No borrar, reemplazar, actualizar ni recrear la colección para forzar la carga.
5. La inserción ordenada se acompaña de verificación posterior. Conservar salida y evidencias nuevas del equipo. Si hay error, puede existir carga parcial: detenerse sin reintentos ni recuperación automática. Para una revisión posterior autorizada usar el modo `verificar`, que solo lee; no volver a insertar.

No es necesario volver a consultar PostgreSQL para reconstruir desde esta extracción ya guardada. Sí se necesita acceso al origen equivalente y autorización de lectura cuando se realicen las comparaciones de la consigna 5. Esta entrega documental no ejecuta ninguna reproducción ni repite la carga existente.

## Mateo — consignas 4 y 5

Archivos asignados: [consultas_mongodb.js](../mongodb/consultas_mongodb.js), [consultas_postgresql.sql](../postgresql/consultas_postgresql.sql) y [comparacion_resultados.md](comparacion_resultados.md). Las consultas y la comparación fueron aportadas por Mateo, quien informó su ejecución el 2026-10-29. Las evidencias MongoDB de c) y d) se completaron con la reejecución de Amanda del 2026-11-01; las capturas legibles están integradas al informe final. Aporte: [aporte_mateo.md](../informe/aporte_mateo.md), con OK de Mateo del 2026-11-01.

Consigna 4: registrar las cuatro consultas MongoDB y sus resultados: a) todos los pedidos con identificador y estado; b) estado existente; c) producto en el arreglo de líneas; d) total superior a un umbral elegido y justificado. Usar los nombres de campos implementados e importes Decimal128 desde texto; no convertir dinero a Number.

Consigna 5: ejecutar los equivalentes PostgreSQL de b) y c). **Usar exactamente el subconjunto migrado en ambos motores: pedidos 1, 2, 3, 4 y 5**, aun cuando las bases contengan otros pedidos. Usar el mismo estado y el mismo ID de producto; contar pedidos distintos, no líneas del join. Conservar cantidades, precios y estados del origen sin modificarlos para obtener coincidencias.

Criterios de aceptación:

- Cuatro consultas MongoDB ejecutadas con parámetros explícitos y umbral fundamentado; no presentar una consulta escrita como si hubiera sido ejecutada.
- Equivalentes PostgreSQL b) y c) ejecutados en el mismo subconjunto y con parámetros equivalentes.
- Tabla con cantidades e IDs de pedidos en cada motor y explicación de coincidencias o diferencias; si el origen cambió respecto de la extracción, registrar la diferencia antes de sacar conclusiones. Las cantidades iguales no bastan si los IDs difieren.
- Archivos con las instrucciones efectivamente ejecutadas y evidencia legible por consulta, sin datos personales ni secretos. La captura interna de verificación de migración no sustituye esas evidencias.

### Resultados ejecutados de consultas 4–5

La ejecución registró que el estado `ENTREGADO` recupera los cinco IDs 1–5 y que
el producto ID 1 recupera los pedidos 1, 3 y 5 en ambos motores. Las cantidades
y precios históricos coincidieron. En MongoDB, el umbral `Decimal128("3000.00")`
recuperó los pedidos 3 y 4. La salida completa y los límites están en
[comparacion_resultados.md](comparacion_resultados.md); las capturas de `psql` y
`mongosh` deben adjuntarse como evidencia sin contraseñas.

## Lucas — consignas 6 y 7

Archivo de trabajo: [contraste_ia.md](contraste_ia.md). Lucas prepara la consulta a IA y su contraste; el equipo revisa la conclusión. El [aporte de Amanda](../informe/aporte_amanda.md) no reemplaza estas partes.

La consigna 6 requiere mencionar el modelo PostgreSQL real y la colección implementada, el acceso frecuente a pedidos completos y la necesidad de coherencia de cantidades y precios. Registrar herramienta/modelo si se conocen, fecha, pregunta exacta y respuesta pertinente, sin inventar versiones ni publicar transcripciones extensas.

Criterios de aceptación de la consigna 7:

- Seleccionar dos afirmaciones concretas de esa respuesta y contrastar cada una con documentación oficial identificable o resultados reproducibles del laboratorio. Distinguir la propuesta de IA de lo implementado, ejecutado y verificado.
- Registrar fuente/enlace y fecha de consulta o procedimiento y evidencia, junto con resultado y límites del contraste. Las [fuentes del modelo](modelo_documental.md#8-fuentes-oficiales-consultadas-y-dudas) y el [resultado de migración](resultado_migracion.md) son insumos, no un contraste ya completado.
- Conclusión de hasta 200 palabras sobre mantener PostgreSQL, usar MongoDB en el subconjunto o combinar tecnologías, sustentada en al menos dos criterios técnicos. Aprobada por el equipo con el informe final (2026-11-01).

## Evidencias e integración

Para cada ejecución futura autorizada registrar fecha, hora/zona, motor/base, versiones conocidas, consulta o archivo y parámetros, cantidades e IDs pertinentes, salida observada y limitaciones. Aplicar la [guía de evidencias](../evidencias/README.md); conservar originales y producir copias anonimizadas si se requieren. No atribuir al asistente ejecuciones hechas por integrantes.

El PDF grupal está en [informe/](../informe/README.md): integra el aporte de Amanda, las consultas y comparaciones de Mateo y el contraste y la conclusión de Lucas, en hasta cinco páginas sin contar código adjunto. Fue aprobado por el equipo (OK de Mateo y Lucas del 2026-11-01) y está listo para entregar. Usar ramas descriptivas y pull request; la protección remota de `main` no está comprobada.

## Conservación del hash al compartir

Se detectó `core.autocrlf=true` y 418 finales CRLF en la extracción original. Antes de protegerla, `git hash-object` con filtros y sin filtros produjo objetos diferentes; estos IDs de objetos Git no son el SHA-256 de la evidencia. Se incorporó en [.gitattributes](../../../.gitattributes) una regla para el archivo exacto (abajo se muestra su ubicación actual tras el traslado):

```gitattributes
/TP1_FoodStore_NoSQL/evidencias/extraccion_20261028_170446.json -text
```

`-text` desactiva la conversión de finales de línea por Git para esa ruta. No cambia la configuración global ni los bytes actuales. Tras aplicarla, ambos cálculos de objeto coinciden y el SHA-256 original se conserva. No extender la regla a todos los JSON ni volver a guardar la evidencia desde un editor. Después de descargarla en otra computadora, comprobar nuevamente `sha256sum`. Fuente: [documentación oficial de gitattributes](https://git-scm.com/docs/gitattributes).
