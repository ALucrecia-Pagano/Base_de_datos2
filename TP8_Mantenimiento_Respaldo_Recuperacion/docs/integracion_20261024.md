# Integración del TP8 — 24/10/2026

Se integró la entrega preparada en `C:/Users/hp/Practicos/TP8_Mantenimiento_Respaldo_Recuperacion`, con autorización explícita del usuario. Repositorio comprobado: `https://github.com/ALucrecia-Pagano/Base_de_datos2.git`; no es el repositorio de Mateo.

## Cambios

- Actualizado: `SPEC_U6.md`, conservando RPO ≤24 horas y RTO ≤15 minutos ya previstos en la versión inicial.
- Consigna PDF: conservada íntegra, sin sobrescribir.
- SPEC anterior: copia exacta conservada en `docs/antecedentes/SPEC_U6_previo_20261023.md` y en el historial de evidencias.
- Añadidos: scripts, documentos, informe PDF, evidencias y pruebas, detallados abajo.
- Respaldos completos: fuera del repositorio. El valor por defecto de nuevos respaldos es `C:/Users/hp/TP8_Backups`; cada ejecución crea un subdirectorio único. No se escribió en esa carpeta ni se alteró `foodstore_origen.dump` durante esta integración.

No se modificaron archivos de la raíz del repositorio, TP1–TP7, AGENTS, protocolo ni configuración. No se ejecutó SQL, conexión PostgreSQL, respaldo, restauración, borrado de base, git add, commit o push.

## Verificación

Nota de cierre posterior: los resultados de esta sección pertenecen a la integración original. El baseline de la revisión posterior fue bloqueado por política; los scripts y pruebas no se modificaron. Ver [revisión de cierre](cierre_revision_20261024.md). No atribuir los 12 controles históricos a esa revisión.

Pruebas de la copia integrada: `PASS 12 checks; isolated fake tools`. Se ejecutaron en PowerShell con herramientas PostgreSQL simuladas, sobre una carpeta temporal. No prueban una nueva restauración real. Los ensayos históricos reales y la validación separada de los scripts finales se describen en `script_validation.md`.

Estado git antes: `?? TP8_Mantenimiento_Respaldo_Recuperacion/`. Tras copiar: el mismo único directorio sin seguimiento; no se prepararon ni confirmaron cambios.

SHA256 de la consigna, antes y después:
`B91D68326D14F1012CB4ED680194FE49615C1E4772184919C5CBC51E2100C5E5`

SHA256 del SPEC original y su copia conservada:
`791715026C778F307E0B7F362AA20499BF594A255A968D9DD8FA0330E44AA423`

El manifiesto `MANIFEST_SHA256.txt` cubre todos los archivos finales de TP8 excepto el propio manifiesto.

## Uso desde Visual Studio Code

Actualizar el explorador y abrir `README_TP8.md`, luego `LEEME_ENTREGA.md`. No hace falta copiar el ZIP ni ejecutar los scripts para ver el trabajo integrado. Revisar el informe y datos del grupo antes de entregar; cualquier nueva operación real sobre las bases requiere revisión y autorización específica.

## Archivos añadidos

- `backup_foodstore.ps1`
- `docs/antecedentes/SPEC_U6_previo_20261023.md`
- `evidencias/foodstore_dev/backup.log`
- `evidencias/foodstore_dev/restored_after.json`
- `evidencias/foodstore_dev/result.json`
- `evidencias/foodstore_dev/source_before.json`
- `evidencias/foodstore_tp3_carga/backup.log`
- `evidencias/foodstore_tp3_carga/repeticion/createdb.log`
- `evidencias/foodstore_tp3_carga/repeticion/restore.log`
- `evidencias/foodstore_tp3_carga/repeticion/restored_after.json`
- `evidencias/foodstore_tp3_carga/repeticion/result.json`
- `evidencias/foodstore_tp3_carga/repeticion/source_after.json`
- `evidencias/foodstore_tp3_carga/repeticion/source_before.json`
- `evidencias/foodstore_tp3_carga/repeticion/timing.json`
- `evidencias/foodstore_tp3_carga/restored_after.json`
- `evidencias/foodstore_tp3_carga/result.json`
- `evidencias/foodstore_tp3_carga/source_before.json`
- `evidencias/historial/spec_inicial_20261023.md`
- `evidencias/LEEME.md`
- `evidencias/results.json`
- `evidencias/salud_mantenimiento/diagnostico_salud.md`
- `evidencias/salud_mantenimiento/execution_results.json`
- `evidencias/salud_mantenimiento/foodstore_dev.log`
- `evidencias/salud_mantenimiento/foodstore_dev.stderr.log`
- `evidencias/salud_mantenimiento/foodstore_restore_test_after_maintenance.log`
- `evidencias/salud_mantenimiento/foodstore_restore_test_after_maintenance.stderr.log`
- `evidencias/salud_mantenimiento/foodstore_restore_test.log`
- `evidencias/salud_mantenimiento/foodstore_restore_test.stderr.log`
- `evidencias/salud_mantenimiento/foodstore_tp3_carga.log`
- `evidencias/salud_mantenimiento/foodstore_tp3_carga.stderr.log`
- `evidencias/salud_mantenimiento/health_after_execution.json`
- `evidencias/salud_mantenimiento/maintenance_execution.json`
- `evidencias/salud_mantenimiento/maintenance.log`
- `evidencias/salud_mantenimiento/maintenance.stderr.log`
- `evidencias/summary.csv`
- `evidencias/validacion_scripts_nuevos/foodstore_dev_20261024_005058_595_da8460d6/baseline.json`
- `evidencias/validacion_scripts_nuevos/foodstore_dev_20261024_005058_595_da8460d6/logs/archive_contents.log`
- `evidencias/validacion_scripts_nuevos/foodstore_dev_20261024_005058_595_da8460d6/logs/pg_dump.log`
- `evidencias/validacion_scripts_nuevos/foodstore_dev_20261024_005058_595_da8460d6/metadata.json`
- `evidencias/validacion_scripts_nuevos/foodstore_tp3_carga_20261024_005059_629_7afe0b11/baseline.json`
- `evidencias/validacion_scripts_nuevos/foodstore_tp3_carga_20261024_005059_629_7afe0b11/logs/archive_contents.log`
- `evidencias/validacion_scripts_nuevos/foodstore_tp3_carga_20261024_005059_629_7afe0b11/logs/pg_dump.log`
- `evidencias/validacion_scripts_nuevos/foodstore_tp3_carga_20261024_005059_629_7afe0b11/metadata.json`
- `evidencias/validacion_scripts_nuevos/restore_20261024_005111_258_fd6c63e5/logs/destination_check.log`
- `evidencias/validacion_scripts_nuevos/restore_20261024_005111_258_fd6c63e5/result.json`
- `health_check.sql`
- `informe_u6.md`
- `informe_u6.pdf`
- `LEEME_ENTREGA.md`
- `maintenance.sql`
- `pg_common.ps1`
- `pruebas/test_delivery.ps1`
- `README_TP8.md` (nombre vigente del índice).
- `restore_test.ps1`
- `script_validation.md`

- `docs/integracion_20261024.md`: este registro.
- `MANIFEST_SHA256.txt`: huellas de integridad de la integración.
