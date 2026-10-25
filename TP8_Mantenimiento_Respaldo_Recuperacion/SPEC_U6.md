# SPEC_U6 — Operación y recuperación

## Alcance y frecuencia

`foodstore_dev` representa la base original local `foodstore`; `foodstore_tp3_carga` agrega una comparación de volumen. Cada origen tiene su respaldo y línea base. El único destino es `foodstore_restore_test`. Las bases de origen permanecen intactas.

| Frecuencia | Acción | Evidencia de éxito |
|---|---|---|
| Diaria | Respaldo de ambos orígenes | Dump custom fechado, no vacío, código 0 y logs. |
| Diaria | Chequeo de salud | Diagnóstico fechado de tamaños, actividad, estadísticas y autovacuum. |
| Semanal | Revisión y mantenimiento justificado | Estadísticas previas, decisión y validación posterior. |
| Semanal | Restauración de ambos respaldos, sucesivamente | Conteos e integridad coincidentes, logs y tiempos. |

## Seguridad

Revisar manualmente scripts; toda ejecución requiere autorización específica. Usar autenticación sin contraseñas en scripts ni evidencias. Registrar fecha, base, resultado y errores; ante fallos, salir con código distinto de cero. Si el destino existe, detenerse: nunca borrarlo automáticamente. Toda recreación necesita decisión explícita del operador. Guardar respaldos fechados fuera del repositorio sin sobrescribir anteriores; revisar espacio y retención. Las evidencias pueden incorporarse al repositorio. Se aplica además el protocolo de seguridad del repositorio (`protocolo_seguridad.md`). El diagnóstico es de lectura; el mantenimiento exige la copia de prueba. Revisar estadísticas antes del ANALYZE puntual y confirmar conteos preservados; no usar VACUUM FULL periódicamente.

## Validación y objetivos

Acordar ventana sin escrituras; comparar conteos exactos previos y posteriores de `categoria`, `cliente`, `producto`, `pedido` y `detalle_pedido`. Verificar `precio_lista`, stock y precio unitario no negativos, cantidades positivas, subtotales y referencias sin huérfanos. Distinguir conteos de estimaciones.

Metas de laboratorio, fijadas el 23/10 antes de los ensayos: RPO ≤ 24 h (respaldo diario) y RTO ≤ 15 min. El RTO se mide desde antes de crear el destino hasta terminar las validaciones. La antigüedad del respaldo al iniciar la restauración se usa como aproximación al RPO. Los valores observados están en el informe.

El PASS de `restore_test.ps1` confirma la restauración y las validaciones; la comparación del RTO y de la antigüedad con las metas se hace en el informe.

## Revisión

La SPEC inicial se redactó con asistencia de IA, y los scripts los generó Codex (la cátedra admite agentes en lugar de OpenCode). Cada operación sobre las bases requirió autorización humana individual, y los scripts finales se revisaron con Claude Code antes de la entrega. Ver `informe_u6.md`.
