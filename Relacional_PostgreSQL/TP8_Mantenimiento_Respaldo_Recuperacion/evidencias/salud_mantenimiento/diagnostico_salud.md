# Chequeo de salud — Unidad 6

Ejecutado el 24/10/2026 entre 00:43:22 y 00:43:26 (UTC-03:00). Motor: PostgreSQL 17.11. Las tres ejecuciones finalizaron con código 0; sus salidas y códigos están en esta carpeta. El script utiliza current_database(), transacción READ ONLY, psql -X -w y ON_ERROR_STOP. No contiene contraseñas ni registra texto SQL de otras sesiones.

| Base | Tamaño observado | Conexiones | Otras consultas activas | Deadlocks acumulados |
|---|---:|---:|---:|---:|
| foodstore_dev | 8.959.667 bytes (8750 kB) | 1, propio chequeo | 0 | 0 |
| foodstore_tp3_carga | 101.512.883 bytes (97 MB) | 1, propio chequeo | 0 | 0 |
| foodstore_restore_test | 97.760.947 bytes (93 MB) | 1, propio chequeo | 0 | 0 |

Son observaciones de un instante; no demuestran ausencia histórica de bloqueos o problemas. Los contadores pg_stat_database son acumulados. El tamaño físico menor de la restaurada no implica pérdida de filas: la validación de conteos del ensayo anterior fue correcta, y una restauración reconstruye objetos físicos.

Autovacuum y track_counts están activados; no hay opciones particulares de autovacuum en las seis tablas de aplicación. Umbral de autoanalyze: 50 + 0,1 × filas estimadas; vacuum: 50 + 0,2 × filas estimadas.

En la restaurada, cliente, producto, pedido y detalle_pedido ya recibieron autovacuum y autoanalyze entre 00:37:30 y 00:37:35, después de la restauración. Sus estimaciones vivas son respectivamente 20.003, 50.003, 200.005 y 499.571; las cuatro reportan cero tuplas muertas y cero modificaciones desde analyze. No existe evidencia aquí para requerir VACUUM FULL, REINDEX ni otro mantenimiento invasivo.

Categoria, usuario y la vista materializada mv_resumen_ventas_categoria_mes reportan 2, 3 y 26 tuplas vivas estimadas, sin ANALYZE registrado. Son relaciones pequeñas, por debajo del umbral automático; NULL no constituye una anomalía por sí solo. Como mantenimiento posterior a la restauración y demostración reproducible para la consigna, se propone ANALYZE VERBOSE en esas tres relaciones, exclusivamente en foodstore_restore_test, seguido del mismo chequeo. La acción actualiza estadísticas del planificador y metadatos de mantenimiento, sin cambiar filas de aplicación. Esta recomendación corresponde al chequeo inicial; la ejecución posterior se documenta al final.

En ambas fuentes, las estadísticas de tablas reportan cero y fechas NULL aun cuando las verificaciones previas muestran datos. Son estimaciones/contadores, no COUNT(*) exactos: no deben presentarse como tablas vacías ni atribuirse a una causa no comprobada. Se conservaron las fuentes sin mantenimiento.

Documentación: PostgreSQL 17 pg_dump advierte que el respaldo no contiene estadísticas del optimizador y recomienda ANALYZE tras restaurar: https://www.postgresql.org/docs/17/app-pgdump.html .

No se modificaron el repositorio de Mateo, el ZIP ni datos de las bases. Durante el chequeo inicial solo se escribieron archivos de evidencia; el mantenimiento posterior actualizó estadísticas exclusivamente en el destino restaurado. Las consultas de observación naturalmente generan actividad estadística del propio chequeo.

## Mantenimiento ejecutado posteriormente

A las 00:44:37 (UTC-03:00), después de comprobar pg_stats, se ejecutó ANALYZE VERBOSE exclusivamente sobre categoria, usuario y mv_resumen_ventas_categoria_mes de foodstore_restore_test. Antes tenían cero columnas con estadísticas del optimizador; después tienen respectivamente 5, 9 y 6. Se preservaron los conteos exactos 2, 3 y 26. maintenance.sql incluye guardia de nombre de base, timeout de bloqueo de 5 segundos y de sentencia de 60 segundos. maintenance_execution.json y health_after_execution.json registran código 0; maintenance.log, maintenance.stderr.log y foodstore_restore_test_after_maintenance.log conservan la evidencia. Los logs originales del chequeo anterior permanecen intactos. No se aplicó mantenimiento a las fuentes ni se cambió configuración.

