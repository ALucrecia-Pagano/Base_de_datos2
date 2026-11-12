# Consigna 3.c — Anexo: scripts agregados después del code review

**Herramienta:** Claude Code (extensión de VS Code, modelo Claude Opus 5.5), en modo de solo lectura. Los dos scripts `.ps1` y el prompt del ensayo `.sql` se redactaron con asistencia de Claude (chat); esta revisión se hizo en una sesión nueva de Claude Code, sin ese contexto, leyendo el código desde cero. Fecha: 12/11/2026.
**Motivo:** el code review original cubrió los 75 scripts existentes al 04/11/2026. Después se agregaron 3 scripts para la segunda entrega del TPI; con este anexo quedan revisados los 78 scripts del repositorio.
**Alcance:**
- `Relacional_PostgreSQL/TP6_FNBC_Desnormalizacion/Parte1_FNBC/ensayo_migracion_reversion.sql`
- `Relacional_PostgreSQL/TP8_Mantenimiento_Respaldo_Recuperacion/programacion/registrar_respaldo_programado.ps1`
- `Relacional_PostgreSQL/TP8_Mantenimiento_Respaldo_Recuperacion/programacion/quitar_respaldo_programado.ps1`

Como contexto se leyeron, sin modificarlos, `tp_fnbc_control_lote.sql`, `spec_migracion/`, `evidencias/evidencia_reversion_20261110_165503.txt`, `backup_foodstore.ps1`, `pg_common.ps1`, `README_programacion.md` y `evidencias_20261110/`. No se ejecutó ningún script ni hubo conexión a las bases.
**Criterio de decisión:** el mismo de [consigna_3c.md](consigna_3c.md).

## Tabla de hallazgos

| ID | Ubicación | Hallazgo (resumido) | Decisión | Motivo |
|---|---|---|---|---|
| F25 | TP6 · `ensayo_migracion_reversion.sql`, línea 17 | El comentario dice "secciones 1 a 8", pero se copiaron sin cambios las secciones 1 a 9. La DUIA de la spec registra esta corrección como hecha, pero el script no la tiene. | Corregido | Correcto, comprobado con `diff`. Se corrigió la línea 17 a "secciones 1 a 9"; como se reemplaza una línea por otra, los números de línea citados en la evidencia no cambian. |
| F26 | TP6 · `ensayo_migracion_reversion.sql`, línea 341 y secciones 13 a 16 (líneas 405 a 551) | La reversión se prueba dentro de la misma transacción de la migración, contra una foto `ON COMMIT DROP`. En el escenario E3 real (después del `COMMIT`), esa foto no existe y no hay un script de reversión independiente. | Corregido (documentación) | Correcto. Se aclaró en `plan_reversion.md` el alcance del ensayo y cómo se verifica un E3 real. Un script de reversión independiente queda como mejora. |
| F27 | TP8 · `registrar_respaldo_programado.ps1`, línea 25 | La tarea guarda la ruta absoluta de la copia de trabajo. Si el repositorio se mueve, la tarea falla antes de correr `backup_foodstore.ps1` y no queda ningún `metadata.json` con `FAIL`, contra lo que dice el README. | Corregido (documentación) | Correcto por lectura del código y de la definición XML exportada. Se agregó la limitación en `README_programacion.md`, junto con el control de `LastTaskResult`. |
| F28 | TP8 · `registrar_respaldo_programado.ps1`, línea 25 | `powershell.exe` corre en la sesión interactiva sin ventana oculta: a las 23:00 se abre una consola, y cerrarla corta el respaldo y puede impedir que se escriba el `metadata.json`. | Aceptado | Riesgo bajo en una máquina personal y con un respaldo de unos 2 s. Queda como mejora (`-WindowStyle Hidden`); no se cambió el script para no tener que volver a registrar la tarea y desalinear la evidencia ya tomada. |
| F29 | TP8 · `quitar_respaldo_programado.ps1`, línea 10 | No comprueba que la tarea exista ni que sea la que creó el script de registro: si no existe, corta con un error genérico; con `-TaskName` borra cualquier tarea del usuario con ese nombre. | Aceptado | Riesgo bajo; asimetría con la línea 21 del script de registro, que sí controla la existencia. Queda como mejora. |

## Detalle

### F25 — Comentario desactualizado sobre las secciones copiadas (TP6)

**Qué se encontró.** La línea 17 dice `-- Copiado sin cambios de tp_fnbc_control_lote.sql (secciones 1 a 8).` La comparación con `diff` de las primeras 330 líneas de ambos archivos solo muestra diferencias en el encabezado (líneas 1 y 4) y en ese comentario agregado. Es decir, la sección 9 (vista `v_control_lote_almacen`, líneas 321 a 335) también es idéntica a la del original. Además, `spec_migracion/DUIA_spec_migracion.md`, línea 20, registra: *"El comentario decía 'secciones 1 a 8' […] Se corrigió a 'secciones 1 a 9'"*, pero el archivo versionado conserva el texto anterior.

**Por qué importa.** El script contradice a su propia DUIA, que afirma una corrección que no está en el repositorio. Quien lea el script puede suponer que la sección 9 difiere del original.

**Qué cambiaría.** La línea 17 por `(secciones 1 a 9)`, o bien la línea 20 de la DUIA para que no declare la corrección como hecha. Los números de línea de la evidencia (`:378`, `:399`, `:422`, `:529`, `:551`) no cambian, porque se reemplaza una línea por otra.

### F26 — La reversión E3 solo está probada dentro de la misma transacción (TP6)

**Qué se encontró.** La foto de referencia se crea en la línea 341 como `CREATE TEMP TABLE ref_control_lote_almacen ON COMMIT DROP`. Las secciones 13 a 16 (validar LD → C, recrear, poblar, verificar contra la foto y retirar lo nuevo) corren en la misma transacción que la migración, sin escrituras intermedias, y todo termina en `ROLLBACK` (línea 578). Sin embargo, `spec_migracion/plan_reversion.md`, línea 16, describe E3 como *"Después del COMMIT y del retiro de la tabla original"*, con un *"Script de reversión"* probado en `ensayo_migracion_reversion.sql`.

**Por qué importa.** En un E3 real la reversión corre en otra sesión, después del `COMMIT`. La foto ya no existe, así que las verificaciones de las líneas 470 a 529 fallarían con "la relación ref_control_lote_almacen no existe", y no hay un script de reversión separado para ejecutar. El ensayo prueba que la secuencia de pasos es correcta, pero no reproduce las condiciones de E3. Además, en un E3 real los datos pueden haber cambiado después del corte, y compararlos con la foto previa ya no tendría sentido. La sección "Limitación" del plan lo insinúa, pero no lo dice.

**Qué cambiaría.** Una de estas dos opciones: (a) extraer las secciones 13, 14 y 16 a un `revertir_migracion.sql` independiente, con su propio `BEGIN … COMMIT`, que verifique LD → C y la igualdad de conteos entre la vista por JOIN y la tabla recreada, en lugar de compararla con la foto; o (b) aclarar en `plan_reversion.md` que la prueba de E3 es un ensayo en la misma transacción.

### F27 — Ruta absoluta en la tarea y fallas que no dejan `FAIL` (TP8)

**Qué se encontró.** En la línea 25, el argumento de la tarea lleva la ruta absoluta resuelta en la línea 16. La definición exportada (`evidencias_20261110/tarea_definicion.xml`) muestra `-File "C:\Users\hp\Practicos\Relacional_PostgreSQL\…\backup_foodstore.ps1"`. Si el repositorio se mueve, se renombra o se vuelve a clonar en otra carpeta, `powershell.exe` no encuentra el archivo y la tarea termina con un `LastTaskResult` distinto de 0, sin que `backup_foodstore.ps1` llegue a correr.

**Por qué importa.** `README_programacion.md`, línea 41, dice que si el respaldo falla *"queda registrado como `FAIL` en `metadata.json`"*, y la línea 51 agrega que *"no pasa desapercibido"*. Eso solo vale para las fallas dentro del `try` de `backup_foodstore.ps1` (líneas 16 a 26), por ejemplo con el servicio detenido. No vale para una ruta rota, ni para las fallas anteriores al `try` (líneas 8, 12 y 13 de ese script), que no escriben ningún `metadata.json`. En ningún caso hay un aviso activo: hay que entrar a mirar la carpeta o el Programador de tareas.

**Qué cambiaría.** Agregar a las Limitaciones del README que la tarea depende de la ubicación actual del repositorio, y que una falla fuera de `backup_foodstore.ps1` solo se ve en el `LastTaskResult` de la tarea. Como mejora, al registrar se podría imprimir la ruta que queda guardada en la acción. En el control diario de los respaldos, además de buscar un `metadata.json` con `FAIL`, convendría revisar `Get-ScheduledTaskInfo`.

### F28 — Consola visible durante el respaldo (TP8)

**Qué se encontró.** La línea 25 invoca `powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File …` sin `-WindowStyle Hidden`, y la línea 28 registra la tarea con `-LogonType Interactive`. La tarea corre en la sesión del usuario, así que a las 23:00 aparece una ventana de consola en el escritorio.

**Por qué importa.** Si el usuario cierra esa ventana durante el `pg_dump`, el proceso termina. El bloque `finally` de `backup_foodstore.ps1` (línea 27) puede no llegar a escribir el `metadata.json`, y queda un `.dump` parcial sin registro. Con la base actual la corrida dura unos 2 s (README, línea 23), por lo que el riesgo es bajo, pero crece con el tamaño de la base.

**Qué cambiaría.** Agregar `-WindowStyle Hidden` al argumento de la línea 25. La ventana igual puede aparecer un instante, pero ya no queda abierta durante el respaldo.

### F29 — Baja de la tarea sin controles (TP8)

**Qué se encontró.** La línea 10 ejecuta `Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false` directamente. Si la tarea no existe, con `$ErrorActionPreference = 'Stop'` (línea 9) el script corta con el error genérico del cmdlet. Tampoco se comprueba que la tarea sea la creada por `registrar_respaldo_programado.ps1` (por ejemplo, por su descripción o su acción), y `-Confirm:$false` elimina la confirmación.

**Por qué importa.** El script de registro sí controla la existencia (línea 21) y da un mensaje claro; el de baja no, y no es idempotente: correrlo dos veces da error la segunda vez. Como el parámetro `-TaskName` es libre, un nombre mal escrito podría borrar otra tarea del mismo usuario sin pedir confirmación. El riesgo es bajo, porque la tarea corre con `-RunLevel Limited` y un usuario sin privilegios no puede borrar tareas del sistema.

**Qué cambiaría.** Antes de la línea 10, obtener la tarea con `Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue`. Si no existe, informar "La tarea no existe; no hay nada que quitar" y salir sin error. Si existe y su descripción no empieza con `TPI BDII:`, detenerse.

### Sin otros hallazgos

En `ensayo_migracion_reversion.sql` se verificó, además, lo siguiente sin encontrar problemas: el control de base y de objetos previos (líneas 19 a 80), el `LOCK … NOWAIT` (líneas 86 y 87, que ya resuelve lo observado en F24), el uso de `OVERRIDING SYSTEM VALUE` sin tocar la secuencia, que el DDL recreado en la sección 14 coincide con el de la sección 3, y que los números de línea de la evidencia coinciden con el script actual. En `registrar_respaldo_programado.ps1` son correctos el control de existencia previa (línea 21), el `throw` si falta `backup_foodstore.ps1` (líneas 17 a 19) y que no se guarde ninguna contraseña (líneas 4 a 6 y 28). Un error no capturado en `backup_foodstore.ps1` hace que `powershell.exe -File` devuelva 1, así que el `LastTaskResult` refleja la falla.

## Decisión humana

Revisé los cinco hallazgos contra los archivos y los acepté todos, porque son correctos. El F25 era un descuido mío: había anotado en la DUIA una corrección que nunca llegué a guardar en el script, así que la apliqué. Los F26 y F27 no rompen nada, pero el plan de reversión y el README decían más de lo que se había probado. Preferí corregir la documentación antes que dejar afirmaciones de más. Para el F26 no escribí un script de reversión aparte, porque el ensayo ya muestra que la secuencia funciona; lo dejé como mejora y aclaré cómo se verificaría un E3 real. Los F28 y F29 son de riesgo bajo y los dejé como mejora: cambiar el script de registro me obligaba a registrar la tarea de nuevo, y la evidencia que tomé dejaría de coincidir con el código.
