# TP7 — Revisión documental del 2026-10-15 (Codex)

Alcance autorizado: documentación y dos copias de lectura. Sin SQL ejecutado, conexiones a
PostgreSQL, cambios de scripts, commit, push ni merge. Sin nuevas pruebas de base de datos.
Inicio: `main`, árbol limpio, `HEAD` y referencia local `origin/main` en `88675cc`.
El historial local confirma que ese commit incluye las correcciones de seguridad y sus evidencias;
la publicación se registra conforme al dato del usuario y la referencia local, sin consulta de red.
Los nuevos ajustes documentales quedan sin publicar hasta su commit y pendientes de revisión humana.
No se declara entrega final.

## Codificación: diagnóstico y transformación exacta

Antes de editar se calcularon SHA-256 de los originales. Las copias anteriores coincidían con
`original.decode("latin1").encode("utf-8")`. Esto prueba reversibilidad, pero no legibilidad:
los originales contienen tanto caracteres Latin-1 como secuencias de bytes UTF-8.
Una conversión global dañaría las primeras líneas correctas.

Se aplicó exclusivamente a las copias `.utf8.txt` una sustitución de cada secuencia Unicode
`U+00C3` seguida de `U+0080..U+00BF` efectivamente encontrada, mediante
`fragmento.encode("latin1").decode("utf-8", errors="strict")`. Una sola pasada; sin reemplazos
por inferencia lingüística, normalización Unicode ni cambios de saltos de línea. El resto de
los bytes de las copias se conservó. Se enumeran todas las sustituciones por puntos de código.

### `log_auditoria_prueba`

Copia: [log_auditoria_prueba.utf8.txt](log_auditoria_prueba.utf8.txt).
Líneas modificadas (desde 1): 24.

| Secuencia anterior | Resultado | Ocurrencias |
|---|---|---|
| U+00C3 U+00B3 | ó (`U+00F3`) | 3 |

Original [log_auditoria_prueba.txt](log_auditoria_prueba.txt), SHA-256 antes y después (idénticos):
`c750282475e230db9758f35fbd6ba95a2b29d9d176800d026d467ca70aab4693`.

### `log_simulacro_anonimizado`

Copia: [log_simulacro_anonimizado.utf8.txt](log_simulacro_anonimizado.utf8.txt).
Líneas modificadas (desde 1): 13, 28, 31, 43, 60, 68, 85, 93, 110, 118, 142, 146, 150, 159, 163, 177, 184, 189, 194, 201, 209.

| Secuencia anterior | Resultado | Ocurrencias |
|---|---|---|
| U+00C3 U+00A9 | é (`U+00E9`) | 6 |
| U+00C3 U+00AD | í (`U+00ED`) | 7 |
| U+00C3 U+00B1 | ñ (`U+00F1`) | 4 |
| U+00C3 U+00B3 | ó (`U+00F3`) | 14 |
| U+00C3 U+00BA | ú (`U+00FA`) | 2 |

Original [log_simulacro_anonimizado.txt](log_simulacro_anonimizado.txt), SHA-256 antes y después (idénticos):
`4c6025e0ffc06aaef82f3a7f8d5971d6c6bfec479543e2a2c7206fae10ff9541`.

No se detectaron secuencias ambiguas entre las sustituciones enumeradas: todas admiten
inversión UTF-8 estricta y corresponden a los fragmentos visibles afectados. No se reconstruyó
texto faltante. Se conservaron las líneas correctas y todo contenido fuera de esas secuencias,
incluidos fechas, usuarios, direcciones, sentencias, orden y resultados. Las sentencias citadas
en el log solo reciben corrección de representación; ningún script ejecutable se editó.
Los archivos siguen teniendo 24 y 209 líneas, respectivamente.

## Procedencia de prompts y limitaciones

La consigna PDF exige el prompt enviado, respuesta relevante y validación/corrección humana.
Se revisaron la bitácora raíz, la [bitácora histórica](../BITACORA.md), los documentos de TP7 y los
nombres de archivos de su historial Git. No se encontraron exportaciones originales independientes
de las conversaciones históricas. No hay archivos adjuntos accesibles en esta conversación.
Las bitácoras son antecedentes comprobables, pero no permiten certificar literalidad de sus prompts.
Los resúmenes reconstruidos y las transcripciones adaptadas conservan sus etiquetas; queda pendiente
que el equipo aporte las transcripciones originales si las conserva.

La [respuesta original de Parte C](respuesta_ia_incidente.md) se conserva íntegra.
El [prompt actual](prompt_codex_revision_20261015.md) se transcribe desde el mensaje del usuario
de esta conversación, no desde un resumen reconstruido. Esta intervención es de Codex, no de OpenCode.
La autorización de edición no se presenta como aprobación humana del resultado.

## Verificación documental

El enlace de verificación de permisos se corrigió a `../evidencias/…`. Se contrastaron los estados
de publicación con el historial, conservando las filas históricas de la bitácora y añadiendo una
aclaración posterior. Se comprobaron 95 enlaces relativos de la documentación revisada (incluida la
decodificación de %20), sin destinos inexistentes. La tabla raíz tiene 19 filas contando cabecera
y separador, todas de tres columnas; sus filas históricas se conservaron. Los SHA-256 de todos
los scripts SQL, evidencias crudas, originales de log y respuesta íntegra C coinciden con los
calculados antes de editar. La transformación exacta de ambas copias fue verificada byte a byte
contra la transformación documentada. Se revisó el diff y se ejecutó git diff --check. README, AGENTS, otros TP y evidencias crudas quedan fuera de edición.


## Resolución de los cinco hallazgos confirmados

Intervención posterior de Codex del 2026-10-15, autorizada por el pedido del usuario.
Este apartado es un registro resumido, no una transcripción literal ni un reemplazo
de los prompts históricos faltantes. La revisión y aprobación humana del resultado
están pendientes. Se conservan los ajustes locales anteriores, sin commit/push/merge.

| Hallazgo | Cambio preparado | Estado de comprobación |
|---|---|---|
| Guardas de variables | Cinco ramas de variable ausente en instalar/preparar/simulacro usan DO + RAISE EXCEPTION; ON_ERROR_STOP permanece activo antes del BEGIN principal | Inspección estática; no ejecutadas, ni directamente ni mediante `\ir` |
| PUBLIC | Diseño §7.6 propone table_privileges para otorgamientos de tabla/vista regular del esquema public; aclaración junto al resultado histórico | Nueva consulta pendiente de ejecución; no se afirma cero filas ni cobertura de otros tipos de objetos |
| pg_monitor | Justificación, RF-06 y diseño precisan exposición posible del texto de consultas de otras sesiones | Cambio documental; pg_monitor y todos los permisos permanecen intactos |
| Representación | Dos membresías directas de lectura/escritura a app_web; acciones de postgres separadas; resumen §9 sin “+ catálogos” | Coherencia estática con roles.sql |
| Estados | Ejecución local y procedimiento identificados como antecedentes y enlazados a ejecución/contención; funciones corregidas distinguidas de instaladores modificados | Funciones aplicadas/validadas mediante corrector según evidencias previas; no nueva ejecución de instaladores completos ni prueba de guardas |

**Pendientes al cierre de esa intervención (resueltos después por las pruebas negativas documentadas
en [esta evidencia](evidencias/verificacion_guardas_public_20261015_124512.md)):** ejecutar las nuevas guardas, incluida su propagación mediante
`\ir`, y la consulta propuesta de PUBLIC requeriría una autorización posterior. No se
reinstaló el entorno ni se repitieron pruebas históricas. No se ejecutó SQL ni se conectó
a PostgreSQL. Las verificaciones de esta intervención son exclusivamente estáticas.

**Verificaciones estáticas realizadas en esta intervención:**

- Comparación con la huella previa: únicamente 10 archivos cambiaron en esta intervención;
  los otros 188 conservan sus SHA-256. Se preservaron los ajustes locales anteriores.
- En los tres SQL, comparación exacta con su contenido previo tras sustituir únicamente las
  cinco guardas autorizadas. El resto de bytes, ON_ERROR_STOP y cierres COMMIT/ROLLBACK
  permanecen intactos; no se incorporaron GUC auxiliares ni comparaciones SQL en \if.
- 133 enlaces locales con destino existente, incluidas cuatro rutas con %20; ancla nueva
  de este apartado cotejada. Bitácora raíz: 20 filas contando cabecera/separador, tres columnas.
  El conteo de 19 filas del apartado anterior corresponde a la intervención anterior.
- Evidencias crudas, logs originales y copias UTF-8 previas, respuesta íntegra C, roles.sql,
  funciones canónicas, corrector y validador sin cambios respecto del inicio de esta intervención.
  README, AGENTS, documentación de otros TP e informes generales también intactos.
- Diff revisado y git diff --check sin errores. Ninguna verificación ejecutó SQL ni abrió
  conexiones; la propagación real de los errores mediante \ir sigue pendiente de prueba.


## Verificación posterior autorizada de guardas y PUBLIC

El usuario autorizó exclusivamente diez casos negativos y la consulta §7.6, sin instalación,
simulacro completo ni cambios de permisos, configuración persistente o datos.
[Evidencia nueva fechada](evidencias/verificacion_guardas_public_20261015_124512.md) y
[salidas nuevas](evidencias/salida_guardas_public_20261015_124512.txt).

- Preparación: `foodstore_dev`, `postgres`, PostgreSQL 17.11; parámetros
  `default_transaction_read_only` y `transaction_read_only` en `on`. Uso de `psql -X -w`.
  Primer intento de autenticación sin contraseña disponible terminó con exit 2; luego se indicó
  el archivo de autenticación existente mediante PGPASSFILE, sin mostrar ni modificar credenciales.
- Cinco variables ausentes probadas directamente y mediante `\ir`: diez errores esperados,
  todos exit 3. Los cinco marcadores de los padres no aparecieron. Se eliminaron explícitamente
  las variables y nunca se suministraron todas las requeridas. No se alcanzaron los BEGIN principales.
- PUBLIC: consulta exacta de diseño §7.6 como postgres, una vez, **0 filas y exit 0**.
  Se limita a otorgamientos de tabla/vista regular del esquema public; no verifica esquemas,
  columnas, funciones, secuencias ni materializadas.
- Las referencias a comprobaciones pendientes en los apartados anteriores describen su estado
  histórico antes de esta autorización. Estas pruebas negativas no acreditan una nueva ejecución
  completa de los instaladores o del simulacro.
- Scripts, evidencias anteriores, logs originales, respuesta C y README no se modificaron.
  No se reconstruyeron transcripciones históricas faltantes. Sin commit/push/merge.
  Revisión y aprobación humana del resultado pendientes.
