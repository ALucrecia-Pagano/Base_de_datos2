# Prompt original — intervención documental de Codex (2026-10-15)

Procedencia: mensaje del usuario que inicia esta intervención en esta conversación de Codex.
Se transcribe su contenido íntegro debajo, sin los metadatos de la plataforma. No es una
transcripción recuperada de OpenCode ni de las sesiones históricas. La revisión humana del
resultado sigue pendiente.

```text
Actuá como auditor y editor técnico del TP7 Administración y Seguridad de Bases de Datos, proyecto FoodStore.

El profesor autorizó usar Codex para estas correcciones. Trabajá sobre el repositorio real:\
C:\Users\hp\Practicos

La consigna principal está en:\
TP7_Administracion_y_Seguridad/Trabajo Practico Unidad 5.pdf

El último commit publicado es 88675cc. Las correcciones SQL ya fueron aplicadas y validadas. Esta tarea es exclusivamente documental: no ejecutes SQL, no te conectes a PostgreSQL, no modifiques scripts ejecutables y no hagas commit, push ni merge.

Antes de editar, revisá rama y estado. Conservá cualquier cambio ajeno; si afecta los archivos que necesitás modificar, detenete y explicá el conflicto. No restaures ni descartes archivos.

Resolvé estos pendientes:

1. Enlace roto\
   En docs/kiro_roles_spec/verificacion_permisos.md, corregí el enlace a salida_psql_validacion_correccion_20261015_112125.txt: desde esa ubicación debe comenzar con ../evidencias/.
2. Estado de publicación\
   Contrastá el historial Git y actualizá las menciones actuales de “sin commit/push” en:

- BITACORA.md raíz.
- Informe_General.md.
- protocolo_seguridad.md.
- TP7_Administracion_y_Seguridad/docs/aplicacion_correccion_seguridad.md.

Registrá que las correcciones de seguridad fueron publicadas en 88675cc. Diferenciá ese hecho de los nuevos ajustes documentales, que quedarán sin publicar hasta su commit. Conservá los estados históricos de las filas de la bitácora, añadiendo una aclaración posterior cuando corresponda. No inventes un hash para este trabajo ni declares la entrega final.

3. Legibilidad de logs\
   Revisá:

- docs/log_auditoria_prueba.utf8.txt.
- docs/log_simulacro_anonimizado.utf8.txt.

Todavía contienen texto como “desconexiÃ³n”. Diagnosticá la codificación por fragmentos; no apliques una conversión global que estropee las líneas correctas.\
Corregí únicamente las copias de lectura y documentá exactamente la transformación. Conservá intactos los dos logs originales .txt y verificá sus hashes antes/después.\
No cambies fechas, usuarios, direcciones, sentencias, orden ni resultados. Si un fragmento resulta ambiguo, conservá su texto y declaralo; no lo reconstruyas por suposición.\
Actualizá la explicación de codificación en los informes: un round-trip correcto no demuestra por sí solo legibilidad.

4. Trazabilidad de prompts\
   La bitácora distingue resúmenes reconstruidos de transcripciones, pero el PDF pide registrar los prompts enviados.\
   Buscá transcripciones originales disponibles en el repositorio y en archivos adjuntos accesibles de esta conversación. Incorporá o enlazá solo textos cuya procedencia puedas comprobar.\
   No conviertas un resumen en una supuesta cita literal. Si no encontrás el original, conservá la etiqueta de resumen reconstruido y declaralo como limitación.\
   No alteres la respuesta íntegra original de la Parte C ni atribuyas a OpenCode interacciones realizadas con otra herramienta.\
   Agregá un registro de esta intervención de Codex manteniendo las tres columnas obligatorias. No atribuyas aprobación humana a cambios que todavía esperan revisión.
5. Revisión final\
   Comprobá:

- Enlaces relativos, decodificando correctamente rutas con %20.
- Tabla de BITACORA.md con exactamente tres columnas.
- Coherencia entre estados históricos, resultados ejecutados y publicación.
- Ausencia de contraseñas reales o hashes publicados en los cambios.
- Que las evidencias crudas y los scripts SQL permanezcan intactos.

README.md está reservado al compañero: no lo modifiques. Tampoco cambies AGENTS.md ni documentación de otros trabajos prácticos.

Entregá:

- Hallazgos resueltos y limitaciones pendientes.
- Archivos modificados.
- Verificaciones efectivamente realizadas.
- git diff --stat y git status --short --branch.

No declares pruebas de base de datos nuevas: esta intervención no debe ejecutar ninguna.
```
