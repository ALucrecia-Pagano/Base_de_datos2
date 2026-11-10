# Validación de scripts

| Validación | Fecha (24/10) | Cómo | Resultado | Evidencia |
|---|---|---|---|---|
| Ensayo previo | 00:32 a 00:44 | Procedimiento ejecutado por Codex antes de consolidar los scripts finales: respaldo, restauración real de ambas bases, diagnóstico y ANALYZE. | Conteos idénticos y 9 indicadores en 0. RTO de 2,9817064 s y 8,1943358 s. | `results.json`, `foodstore_dev/`, `foodstore_tp3_carga/`, `salud_mantenimiento/` |
| Primera ejecución de los scripts | 00:50 a 00:51 | `backup_foodstore.ps1` sobre ambas bases, con el validador de 4 controles de ese momento; `restore_test.ps1` con el destino existente. | Respaldos PASS. La guarda abortó sin borrar el destino. | `validacion_scripts_nuevos/` |
| Pruebas simuladas | 23:18:58 a 23:19:02 | `pruebas/test_delivery.ps1` con herramientas falsas: fallos de `pg_dump` y `pg_restore`, destino existente, conteo distinto, fila inválida, huérfano, orden de claves JSON, dump adulterado y nombre del dump. | 14/14 PASS. Una ejecución anterior, antes de las 23:04, dio el mismo resultado sin guardar la salida. | `validacion_final_20261024/pruebas_simuladas.log` |
| Validación final | 23:04 a 23:09 | Ciclo completo con los scripts entregados: respaldo y restauración de ambas bases, diagnóstico y mantenimiento sobre la copia de carga. | Todo PASS, con los 9 controles en 0. RTO de 2,5788433 s y 9,1510594 s. | `validacion_final_20261024/` |
| Sintaxis | — | Parser de PowerShell sobre los cuatro `.ps1`, sin ejecutarlos. | 0 errores. | — |

Las rutas de evidencia son relativas a `evidencias/`.

## Límites

- Las pruebas simuladas comprueban la lógica de los scripts, no el SQL contra una base real; eso lo cubre la validación final.
- La validación compara conteos y 9 indicadores, no fila por fila, y la restauración no incluye roles ni permisos.
- Cada medición se hizo una vez, en un equipo local y sin escrituras concurrentes. No hay programación periódica instalada.
- La antigüedad del respaldo aproxima el RPO, pero no mide datos perdidos.
- Sin implementar: exigir que `-OutputDirectory` quede fuera del repositorio, rechazar colisiones de carpeta y registrar cada etapa por separado.
