# TP8 — Guía de entrega

## Contenido

| Archivo | Contenido |
|---|---|
| `SPEC_U6.md` | Plan: frecuencias, metas de RPO y RTO, seguridad y validación. |
| `backup_foodstore.ps1` | Respaldo custom con línea base (5 conteos y 9 controles), dump con fecha y hora, `metadata.json` y logs. |
| `restore_test.ps1` | Restauración en `foodstore_restore_test`, validación y medición de RTO y antigüedad del respaldo. |
| `pg_common.ps1` | Funciones compartidas; debe quedar junto a los dos scripts. |
| `health_check.sql` | Diagnóstico de solo lectura; termina con ROLLBACK. |
| `maintenance.sql` | Revisión de autovacuum/ANALYZE y ANALYZE puntual, solo en `foodstore_restore_test`. |
| `pruebas/test_delivery.ps1` | 14 pruebas con herramientas simuladas, sin conexión a PostgreSQL. |
| `informe_u6.pdf`, `informe_u6.md` | Informe post-incidente. |
| `evidencias/` | Ensayo previo y validación final; sin dumps. |

`foodstore_dev` representa la base `foodstore` de la consigna; `foodstore_tp3_carga` permite comparar con mayor volumen. El único destino de restauración es `foodstore_restore_test`.

Los `.dump` no se incluyen porque contienen los datos completos de las bases. Los de la validación final están en `C:\Users\hp\TP8_Backups`, y los del ensayo previo, en su carpeta de trabajo original (`ensayos_tp8_20261024_003237`). La consigna permite omitirlos si el aula limita el tamaño de los archivos; la evidencia de su creación, tamaño y restauración está en `evidencias/validacion_final_20261024/`.

## Requisitos

- Herramientas cliente de PostgreSQL 17 en `C:\Program Files\PostgreSQL\17\bin`, o la ruta que se indique con `-PgBin`.
- Autenticación configurada en `pgpass.conf`. Los scripts usan `-w`: nunca piden ni guardan contraseñas.
- Windows PowerShell. La política de ejecución se habilita solo para cada ejecución con `-ExecutionPolicy RemoteSigned`, sin cambiar la configuración del equipo.

## Ejecución

Desde la carpeta del TP8. Cada operación requiere autorización previa.

1. Pruebas simuladas (no se conectan a PostgreSQL). Resultado esperado: `PASS 14 checks`.

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\pruebas\test_delivery.ps1
   ```

2. Respaldo de cada base. El script imprime la ruta del `metadata.json`, que queda en `C:\Users\hp\TP8_Backups\<base>_<fecha_hora>_<id>\`. Cada respaldo registra su salida en `logs/` y el resultado (PASS o FAIL, tamaño, SHA256 y horarios) en `metadata.json`, dentro de la misma carpeta fechada.

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\backup_foodstore.ps1 -SourceDatabase foodstore_dev
   powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\backup_foodstore.ps1 -SourceDatabase foodstore_tp3_carga
   ```

3. Restauración. `foodstore_restore_test` no debe existir. Sin `-OutputDirectory`, los resultados quedan en `restore_results\` dentro de esta carpeta.

   ```powershell
   powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\restore_test.ps1 -MetadataPath 'C:\Users\hp\TP8_Backups\<carpeta>\metadata.json' -OutputDirectory '<carpeta de resultados>'
   ```

4. Diagnóstico, sobre cualquiera de las bases:

   ```powershell
   psql -X -w -h localhost -p 5432 -U postgres -d <base> -v ON_ERROR_STOP=1 -f .\health_check.sql
   ```

5. Mantenimiento, solo sobre la copia restaurada y después de revisar el diagnóstico:

   ```powershell
   psql -X -w -h localhost -p 5432 -U postgres -d foodstore_restore_test -v ON_ERROR_STOP=1 -f .\maintenance.sql
   ```

Los scripts PowerShell admiten `-PgBin`, `-DbHost`, `-Port`, `-DbUser` y `-OutputDirectory`; `restore_test.ps1` admite además `-DumpPath` si el dump se movió.

## Reglas de seguridad

- `foodstore_dev` y `foodstore_tp3_carga` solo se leen para respaldarlas; nunca son destino.
- `restore_test.ps1` aborta si el destino ya existe. Borrarlo es una decisión aparte, después de comprobar que no tiene conexiones.
- `maintenance.sql` aborta si la base no es `foodstore_restore_test`. No se usa VACUUM FULL como mantenimiento periódico.
- No hay contraseñas en scripts, logs ni evidencias.
- Los respaldos se guardan fuera del repositorio, sin sobrescribir los anteriores.
- No se usa Bypass ni se cambia la política de ejecución del equipo.
- Se aplica el [protocolo de seguridad](../protocolo_seguridad.md) del repositorio.
