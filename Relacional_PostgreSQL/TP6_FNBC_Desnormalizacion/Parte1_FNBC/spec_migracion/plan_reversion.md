# Plan de reversión — Migración FNBC de control_lote_almacen

## Punto de restauración

Antes de cualquier ejecución DDL o DML en la base de datos, se debe generar un respaldo completo e independiente de `foodstore_copia_trabajo` mediante `pg_dump` (en formato custom `.dump` o SQL plano).
Para este fin, se remite a los scripts desarrollados en la Unidad 6 (`../../../TP8_Mantenimiento_Respaldo_Recuperacion/backup_foodstore.ps1` y `restore_test.ps1`), los cuales constituyen el método estandarizado y probado para la generación de copias de seguridad fechadas fuera del repositorio y la verificación de su restaurabilidad.

Respaldo tomado antes del ensayo del 2026-11-10: `foodstore_copia_trabajo_antes_reversion_20261110_165440.dump` (`pg_dump -Fc`, 7,3 MB), guardado fuera del repositorio. Su restauración no se ensayó en este objetivo; el procedimiento de restauración está probado en la Unidad 6.

## Escenarios

| Escenario | Cómo se detecta | Cómo se revierte | Dónde está probado |
|---|---|---|---|
| **E1** Falla antes del COMMIT | Error con `ON_ERROR_STOP` | La transacción se deshace sola (`ROLLBACK`) | Mecanismo de PostgreSQL (`BEGIN` + `ON_ERROR_STOP`), usado por ambos scripts. No se forzó un fallo: la evidencia del TP6 muestra el cierre con `ROLLBACK`, no un error. |
| **E2** Después del COMMIT, con la tabla original todavía presente (convivencia) | La verificación de equivalencia falla o se decide volver atrás | `DROP` de la vista y de las dos tablas nuevas en orden | `ensayo_migracion_reversion.sql` (pasos de retiro). |
| **E3** Después del COMMIT y del retiro de la tabla original | Se decide volver atrás | Script de reversión: validar LD → C, recrear la tabla, poblarla por JOIN, verificar y retirar lo nuevo | `ensayo_migracion_reversion.sql`. |
| **E4** Último recurso: datos nuevos corruptos o que violan LD → C | La reversión E3 aborta en su paso 1 (validación de LD → C) o la verificación detecta datos inconsistentes | Restaurar el respaldo del punto de restauración con `pg_restore` | Unidad 6: `restore_test.ps1` y simulacro de desastre con RTO medido. |

## Criterio para volver atrás

Se activará la reversión ante cualquiera de las siguientes condiciones:
- Falla la verificación de equivalencia (`EXCEPT` devuelve diferencias entre la relación original y la reconstruida).
- Los conteos de filas (`COUNT(*)`) no coinciden entre relaciones correspondientes.
- Aparece una violación de la dependencia funcional LD → C en los datos de las tablas nuevas.
- Una consulta o funcionalidad de la aplicación deja de funcionar tras el corte.

## Limitación

La reversión E3 recupera los datos vigentes en las tablas nuevas; los cambios que violen LD → C no se pueden volver a la forma original sin una decisión humana sobre cuál responsable conservar.
