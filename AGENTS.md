# Instrucciones para asistentes de IA

## Contexto académico

FoodStore — Unidad 7: NoSQL. Bases de Datos II, Tecnicatura Universitaria en Programación, Universidad Tecnológica Nacional, Facultad Regional Mendoza. Comisión 4; profesor: Neira Sergio. Integrantes: Liendo Mateo, Ávila Lucas y Pagano Amanda.

- Repositorio actual: https://github.com/ALucrecia-Pagano/Bases-de-datos-II-NoSQL
- Antecedente relacional: https://github.com/ALucrecia-Pagano/Base_de_datos2

Este proyecto continúa FoodStore. El TP8 anterior corresponde a la Unidad 6; este trabajo corresponde a la Unidad 7 NoSQL y no al TP7 anterior de Administración y Seguridad. No asumir que los archivos del repositorio anterior describen el estado actual de las bases ni modificar ese repositorio.

Leer [README.md](README.md), [CONTRIBUTING.md](CONTRIBUTING.md) y el [plan de trabajo](TP1_FoodStore_NoSQL/docs/plan_trabajo.md). Las reglas comunes para asistentes se mantienen en este archivo.

## Organización del repositorio

Los trabajos se organizan en carpetas. El actual es [TP1 — FoodStore NoSQL, Unidad 7](TP1_FoodStore_NoSQL/README.md). TP1 es la numeración organizativa de este repositorio, no una denominación atribuida a la consigna oficial. Las secciones específicas de FoodStore se aplican a ese trabajo.

## Alcance y entregables

- Modelar pedidos con detalles y datos esenciales del cliente.
- Migrar al menos cinco pedidos de PostgreSQL a MongoDB conservando IDs, instantes de fecha, estados, cantidades y precios históricos.
- Consultar MongoDB: a) listar identificador y estado; b) filtrar por un estado existente; c) buscar pedidos que contengan un producto; d) buscar pedidos con total superior a un umbral justificado.
- Comparar b) y c) en ambos motores, incluyendo cantidades e identificadores de pedidos.
- Consultar una IA y contrastar dos afirmaciones con documentación oficial o resultados reproducibles del laboratorio.
- Entregar un PDF de hasta cinco páginas, sin contar código adjunto, con conclusión de hasta 200 palabras; adjuntar `TP1_FoodStore_NoSQL/mongodb/consultas_mongodb.js` y `TP1_FoodStore_NoSQL/postgresql/consultas_postgresql.sql`, o equivalentes.

## Antecedente: preparación inicial

La etapa inicial se limitó a preparar estructura, reglas y plantillas, sin resolver consignas, implementar validadores o consultas, migrar datos ni generar el PDF. En esa preparación se conservó el README de Amanda y solo se propusieron correcciones o enlaces. Estas limitaciones describen esa etapa histórica; las reglas permanentes de autorización, ejecución, protección de datos y Git se mantienen en las secciones siguientes.

## Estado documentado actual

Amanda ejecutó manualmente la extracción y la migración a `foodstore_unidad7.pedidos`: cinco pedidos y siete líneas, con verificación documentada. El destino, los tipos BSON (IDs Long, cantidades Int32, fechas Date e importes Decimal128), el cliente con ID y alias sintético y el método de extracción de solo lectura e inserción ordenada ya están implementados y documentados. El asistente revisó archivos y evidencias; no ejecutó los motores.

Consultar el [resultado de la migración](TP1_FoodStore_NoSQL/docs/resultado_migracion.md) para las evidencias y sus límites, y el [plan vigente](TP1_FoodStore_NoSQL/docs/plan_trabajo.md) para los pendientes. El diseño fue aprobado por el equipo con el informe final. Las consultas y la comparación de las consignas 4–5 fueron aportadas, con ejecución informada por Mateo. La captura MongoDB de Mateo no mostraba completas c) ni d); el 2026-11-01 Amanda reejecutó los mismos scripts de solo lectura y sus capturas completan esa evidencia, con resultados coincidentes. Ver [comparación y límites](TP1_FoodStore_NoSQL/docs/comparacion_resultados.md). Las consignas 6–7 fueron aportadas por Lucas en [contraste_ia.md](TP1_FoodStore_NoSQL/docs/contraste_ia.md). Lucas aportó cinco capturas de la conversación con Gemini (`evidencias/gemini_lucas_1.jpeg` a `gemini_lucas_5.jpeg`), enlazadas desde `contraste_ia.md`. El informe final (`TP1_FoodStore_NoSQL/informe/`) fue aprobado por el equipo (OK de Mateo y Lucas del 2026-11-01) y está listo para entregar. Solo siguen pendientes la confirmación docente del cliente con ID más alias y la corrección de la cátedra.

## Forma de trabajo

- Antes de actuar, leer las instrucciones aplicables, revisar el directorio, la rama, el estado de Git y los archivos existentes.
- Trabajar exclusivamente dentro de este repositorio, por etapas y dentro de la tarea solicitada.
- Un pedido explícito autoriza las ediciones necesarias dentro de su alcance; no pedir confirmación por cada cambio rutinario. Consultar antes de ampliar el alcance, reemplazar decisiones acordadas o realizar acciones destructivas.
- No sobrescribir cambios ajenos ni descartar trabajo pendiente. Leer antes de editar e integrar contenido válido; informar conflictos antes de reemplazarlo.
- Mantener soluciones sencillas y adecuadas al nivel de la materia. No agregar herramientas, dependencias, automatizaciones ni archivos de herramientas innecesarios; no crear una licencia sin decisión expresa del equipo.

## Bases de datos y protección de datos

- PostgreSQL se conserva como origen de lectura y comparación, sin modificaciones para este TP.
- No conectarse a motores ni ejecutar consultas, SQL o JavaScript sin autorización para esa etapa y destino. Aprobar o guardar un script no autoriza ejecutarlo.
- Antes de una ejecución autorizada, identificar motor, conexión sin secretos, base, colección o tablas y efectos esperados. La autorización de una secuencia concreta permite completarla sin repetir la misma pregunta por cada sentencia.
- No borrar, restaurar, recrear ni sobrescribir bases o colecciones como solución automática ante un error.
- Diseñar la migración para detectar IDs existentes y detenerse ante conflictos, sin reemplazar documentos silenciosamente.
- Conservar IDs de origen, instantes de fecha, estados, cantidades y precios históricos. Tomar los precios de `detalle_pedido.precio_unitario`.
- Definir y justificar tipos BSON para identificadores, fechas e importes antes de implementar la migración, evitando pérdidas de precisión.
- Resolver explícitamente la representación de datos esenciales del cliente sin publicar información personal real. El destino, los tipos BSON, el tratamiento del cliente y el método están implementados y documentados según el estado actual indicado arriba; esto no implica aprobación grupal ni aceptación docente.

## Git y colaboración

- No ejecutar `git add`, `commit`, `push`, `merge`, `rebase`, `reset`, `clean`, `pull` ni otras operaciones que escriban en Git, ni modificar configuraciones Git, sin autorización expresa. Amanda realiza los commits y pushes salvo nuevo pedido explícito.
- No realizar force push ni configurar protecciones remotas en esta preparación.
- No agregar firmas, colaboradores ni líneas `Co-authored-by`.
- Amanda realizó la preparación inicial mientras trabajaba sola y autorizó publicaciones directas en `main` durante esa etapa. Al incorporarse el equipo, el flujo previsto es usar ramas de trabajo y revisión mediante pull request. Ese antecedente no autoriza publicaciones directas para cualquier cambio documental futuro ni acredita protección de `main`. No modificar la parte de otro integrante fuera del alcance autorizado; proponer los cambios necesarios para revisión.
- Responsabilidades acordadas: Amanda, consignas 1–3; Mateo, 4–5; Lucas, 6–7. El equipo completo revisa la conclusión y el informe final.
- Registrar la asistencia de IA de manera académica y verificable en la documentación correspondiente.

## Evidencias y comunicación

- Usar español claro, profesional, respetuoso y neutral. Describir responsabilidades y entregables sin valoraciones personales sobre integrantes.
- No inventar resultados, tiempos, versiones, pruebas ni fuentes. Distinguir propuesta, implementación, ejecución y verificación.
- Las comprobaciones previas aportadas por el equipo no son verificaciones nuevas del asistente. No marcar tareas completas sin evidencia suficiente.
- Conservar evidencias originales en resguardo local cuando contengan información sensible; generar versiones anonimizadas para publicar. No alterar originales ni publicar credenciales, cadenas de conexión con secretos, respaldos completos o datos personales reales.
- Verificar afirmaciones técnicas con documentación oficial o resultados reproducibles; registrar sus fuentes y contexto.
- Al terminar, revisar el diff y el alcance; informar cambios, comprobaciones realizadas, limitaciones, pendientes y siguiente paso. Detenerse al completar la etapa solicitada.
