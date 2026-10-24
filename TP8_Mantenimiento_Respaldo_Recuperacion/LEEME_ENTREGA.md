# TP8 — Guía de entrega y reproducción

## Alcance y archivos

`foodstore_dev` es la base original local correspondiente a `foodstore` de la consigna. `foodstore_tp3_carga` se usa como comparación adicional. No se modificó el repositorio de Mateo. Los scripts y documentos de esta carpeta constituyen una preparación independiente para la entrega; no son los mismos scripts que produjeron los ensayos históricos. Los resultados históricos no prueban por sí solos una ejecución en vivo de estos scripts nuevos; consultar su validación separada.

Archivos de la entrega:

- `SPEC_U6.md`: alcance, cronograma propuesto, objetivos, seguridad y validación.
- `backup_foodstore.ps1`: respaldo custom, línea base y registros.
- `restore_test.ps1`: restauración y validación en destino aislado.
- `pg_common.ps1`: funciones compartidas; debe permanecer junto a ambos scripts.
- `health_check.sql`: diagnóstico de solo lectura, copia íntegra del usado en el ensayo.
- `maintenance.sql`: ANALYZE acotado, copia íntegra del usado en el ensayo.
- Informe final en PDF: síntesis de una página.
- `evidencias/`: resultados, conteos antes/después, tiempos de carga, registros de salud/mantenimiento e historial de la SPEC inicial; sin dumps.

Los respaldos históricos y sus registros completos se conservan aparte en la carpeta de trabajo original `ensayos_tp8_20261024_003237`, fuera de este paquete; esa ubicación no es una dependencia portable de la entrega. Sus dos dumps son evidencia de los ensayos; no se incluyen por defecto en el paquete de entrega, para evitar exponer datos e incrementar el tamaño sin necesidad. Si la cátedra exige los archivos de respaldo, seleccionar expresamente cuáles adjuntar.

La consigna admite omitir el dump si el aula limita su tamaño. Confirmar esa condición o la aceptación de la cátedra antes de entregar sin respaldos; no se da por acreditada aquí. Los logs vacíos no prueban por sí solos código cero. La selección de evidencias no permite reconstruir todos los comandos históricos.

Ubicación local completa de los ensayos y sus dos respaldos: `C:\Users\hp\Documents\Codex\2026-10-24\referenced-chatgpt-conversation-this-is-an\outputs\ensayos_tp8_20261024_003237`. Los nuevos respaldos generados con los scripts integrados se guardan por defecto en `C:\Users\hp\TP8_Backups`, en subcarpetas únicas; no reemplazan `foodstore_origen.dump`.

## Requisitos

Windows PowerShell y herramientas cliente de PostgreSQL disponibles. Revisar manualmente cada script y contar con autorización específica para ejecutarlo; al integrar la entrega en el repositorio, aplicar también sus AGENTS y el protocolo de seguridad correspondiente. Ajustar `-PgBin`, host, puerto y usuario a la instalación real. Autenticación configurada localmente, sin escribir contraseñas en scripts ni compartir archivos de credenciales. No ejecutar con políticas de seguridad deshabilitadas globalmente.

## Ejecución manual

**Estado de cierre:** los comandos siguientes son referencias para futuras operaciones autorizadas, no instrucciones para ejecutar durante esta revisión. El baseline actual quedó bloqueado por la política; por indicación del usuario se conservó el comportamiento de scripts y pruebas. Las correcciones están propuestas, sin aplicar, en [la revisión de cierre](docs/cierre_revision_20261024.md).

El código actual fecha el directorio, pero no el nombre del dump; permite `OutputDirectory` sin imponer que sea externo y crea directorios de ejecución con `-Force`. El operador debe revisar estos límites y no considerar implementadas las guardias propuestas. `health_check.sql` aún termina con COMMIT en READ ONLY: el cambio futuro a ROLLBACK está pendiente; los logs históricos se conservan intactos. El validador actual no verifica subtotales ni huérfanos pese a que la SPEC los exige.

Desde esta carpeta, respaldar cada origen por separado:

```powershell
.\backup_foodstore.ps1 -SourceDatabase foodstore_dev
.\backup_foodstore.ps1 -SourceDatabase foodstore_tp3_carga
```

Cada respaldo queda por defecto fuera del repositorio en `C:/Users/hp/TP8_Backups/<base>_<fecha_identificador>/`, con dump, `metadata.json` y logs. Puede elegirse otra carpeta externa mediante `-OutputDirectory`. Conservar la ruta `metadata.json` devuelta por cada ejecución. Para restaurar un respaldo, reemplazar la ruta de ejemplo por la real:

```powershell
.\restore_test.ps1 -MetadataPath 'C:\Users\hp\TP8_Backups\CARPETA_REAL\metadata.json'
```

Destino fijo: `foodstore_restore_test`. El script se detiene si ya existe. Actualmente conserva la restauración histórica de carga; no ejecutar esperando que se sobrescriba. El operador debe decidir y autorizar aparte cualquier eliminación/recreación de esa copia descartable antes de repetir el ensayo. Nunca usar una base original como destino.

Ambos scripts admiten `-PgBin 'RUTA_CLIENTES_POSTGRESQL' -DbHost localhost -Port 5432 -DbUser postgres` y `-OutputDirectory`. La restauración admite `-DumpPath` si se movió el dump. Sus registros quedan por defecto en `restore_results/<fecha_identificador>/`.

Diagnóstico (repetir cambiando la base si corresponde):

```powershell
psql -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=1 -f .\health_check.sql
```

Revisar el diagnóstico antes de considerar mantenimiento. El siguiente comando modifica estadísticas exclusivamente de la copia de prueba y debe usarse solo con justificación:

```powershell
psql -X -w -h localhost -p 5432 -U postgres -d foodstore_restore_test -v ON_ERROR_STOP=1 -f .\maintenance.sql
```

Guardar también salida estándar, errores y código de salida al reproducir esos comandos. No interpretar estimaciones del catálogo como conteos exactos.

## Cronograma y revisión antes de entregar

Diariamente: respaldo y diagnóstico. Semanalmente: revisión de mantenimiento y ensayo de restauración de cada origen. La SPEC inicial, creada el 23/10 antes de los ensayos, ya establecía RPO ≤24 h y RTO ≤15 min. Se conserva íntegra en `evidencias/historial/spec_inicial_20261023.md`. Los ensayos observados quedan dentro de esas metas del laboratorio; no hay un programador instalado ni evidencia de cumplimiento periódico. Los tiempos históricos son observaciones del laboratorio, no una garantía futura. La frescura del respaldo es un proxy, no pérdida de datos demostrada.

Un PASS operativo no evalúa automáticamente estos objetivos. Las marcas históricas dan intervalos de 2,9865544 s y 8,2566120 s, distintos de los cronómetros 2,9817064 s y 8,1943358 s. No se acreditó la causa exacta de esas diferencias; no se corrigieron los registros para hacerlos coincidir.

El estudiante debe revisar el contenido y completar sus datos personales donde corresponda. No se afirma una revisión humana exhaustiva ya realizada. Se utilizó Codex; según confirmación del usuario, la cátedra acepta esta alternativa a OpenCode. No se afirma haber ejecutado OpenCode.



