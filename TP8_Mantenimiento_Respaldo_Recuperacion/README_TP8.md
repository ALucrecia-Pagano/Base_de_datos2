# TP8 — Mantenimiento, respaldo y recuperación

Trabajo integrado en esta carpeta del repositorio académico. Abrir primero la [guía de entrega](LEEME_ENTREGA.md).

- [Especificación y objetivos](SPEC_U6.md).
- [Informe de una página en PDF](informe_u6.pdf) y [versión editable](informe_u6.md).
- [Evidencias de los ensayos](evidencias/LEEME.md).
- [Validación de scripts](script_validation.md).
- [Revisión de cierre, pruebas bloqueadas y correcciones propuestas](docs/cierre_revision_20261024.md).
- [Registro de esta integración](docs/integracion_20261024.md).
- [Especificación inicial conservada](docs/antecedentes/SPEC_U6_previo_20261023.md).

Los respaldos completos permanecen fuera del repositorio. Los scripts no se ejecutan automáticamente al abrir la carpeta en Visual Studio Code. Toda ejecución real requiere revisar y autorizar su alcance según el protocolo del repositorio; la integración no repite operaciones sobre PostgreSQL.

## Qué abrir primero

Este archivo, `README_TP8.md`, es el índice principal del TP8. No hace falta ejecutar scripts para revisar la entrega.

El informe fue reorganizado para la defensa con nuestros datos. Los scripts y la suite conservan su comportamiento: el baseline actual fue bloqueado por la política y el usuario indicó dejar las correcciones de código como propuestas. No confundir los 12/12 históricos con pruebas actuales. Antes de entregar, revisar el PDF y los pendientes de `docs/cierre_revision_20261024.md`.

| Archivo o carpeta | Para qué sirve |
|---|---|
| `LEEME_ENTREGA.md` | Manual de entrega: alcance, requisitos e instrucciones de uso. |
| `informe_u6.pdf` | Informe de una página listo para revisar y entregar. |
| `informe_u6.md` | Versión editable del mismo informe. |
| `SPEC_U6.md` | Especificación: objetivos, frecuencias, criterios de éxito y seguridad. |
| `backup_foodstore.ps1`, `restore_test.ps1`, `health_check.sql`, `maintenance.sql` | Scripts de respaldo, restauración, diagnóstico y mantenimiento; revisarlos antes de cualquier ejecución autorizada. |
| `pg_common.ps1` | Funciones compartidas utilizadas por los scripts PowerShell. |
| `evidencias/` | Resultados y registros que respaldan lo informado. |
| `docs/` | Registro de integración y antecedentes históricos conservados. |
| `pruebas/test_delivery.ps1` | Pruebas aisladas con herramientas simuladas; no demuestran una restauración real sobre PostgreSQL. |
| `script_validation.md` | Explica qué validaciones se hicieron y sus límites. |
| `MANIFEST_SHA256.txt` | Lista de huellas digitales para comprobar la integridad de los archivos. |
| `TPUnidad_6_Mantenimiento_FoodStore (1).pdf` | Consigna original del trabajo. |
