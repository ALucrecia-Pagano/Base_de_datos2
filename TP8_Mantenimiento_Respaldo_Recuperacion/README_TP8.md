# TP8 — Mantenimiento, respaldo y recuperación

Trabajo práctico de la Unidad 6. Este archivo es el índice de la entrega.

- [Especificación y objetivos](SPEC_U6.md).
- [Informe post-incidente en PDF](informe_u6.pdf) y [versión editable](informe_u6.md).
- [Evidencias de los ensayos](evidencias/LEEME.md).
- [Validación de scripts](script_validation.md).
- [Revisión de cierre anterior](docs/cierre_revision_20261024.md), conservada como antecedente: sus pendientes se resolvieron en la validación final del 24/10.
- [Registro de esta integración](docs/integracion_20261024.md).
- [Especificación inicial conservada](docs/antecedentes/SPEC_U6_previo_20261023.md).

Los respaldos completos permanecen fuera del repositorio. Toda ejecución sobre PostgreSQL requiere autorización previa, según el protocolo de seguridad del repositorio.

## Qué abrir primero

No hace falta ejecutar scripts para revisar la entrega.

El 24/10, entre las 23:04 y las 23:09, se respaldaron y restauraron ambas bases con los scripts finales (PASS), y se ejecutaron el diagnóstico y el mantenimiento. Las 14 pruebas simuladas también pasaron. Evidencias en `evidencias/validacion_final_20261024/`. Los ensayos de las 00:32 a las 00:44 se conservan como antecedente.

| Archivo o carpeta | Para qué sirve |
|---|---|
| `LEEME_ENTREGA.md` | Manual de entrega: alcance, requisitos e instrucciones de uso. |
| `informe_u6.pdf` | Informe post-incidente: evidencias, RPO/RTO, simulacro y mejora propuesta. |
| `informe_u6.md` | Versión editable del mismo informe. |
| `SPEC_U6.md` | Especificación: objetivos, frecuencias, criterios de éxito y seguridad. |
| `backup_foodstore.ps1`, `restore_test.ps1`, `health_check.sql`, `maintenance.sql` | Scripts de respaldo, restauración, diagnóstico y mantenimiento; revisarlos antes de cualquier ejecución autorizada. |
| `pg_common.ps1` | Funciones compartidas utilizadas por los scripts PowerShell. |
| `evidencias/` | Resultados y registros que respaldan lo informado. |
| `evidencias/validacion_final_20261024/` | Respaldo, restauración, diagnóstico y mantenimiento ejecutados con los scripts finales. |
| `docs/` | Antecedentes del cierre anterior y de la integración, conservados intactos. Sus pendientes se resolvieron en la validación final del 24/10. |
| `pruebas/test_delivery.ps1` | 14 pruebas con herramientas simuladas; la restauración real está en `evidencias/validacion_final_20261024/`. |
| `script_validation.md` | Explica qué validaciones se hicieron y sus límites. |
| `MANIFEST_SHA256.txt` | Lista de huellas digitales para comprobar la integridad de los archivos. |
| `TPUnidad_6_Mantenimiento_FoodStore (1).pdf` | Consigna original del trabajo. |
