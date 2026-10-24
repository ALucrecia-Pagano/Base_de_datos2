# TP8 | Mantenimiento, respaldo y recuperación

UTN FRM - Base de Datos II - FoodStore - Ensayos: 24/10/2026 (UTC-03:00)

## Objetivo y entorno

Evaluar la recuperación de FoodStore en un laboratorio Windows con PostgreSQL 17.11. Se utilizó `foodstore_dev` como adaptación local de `foodstore` de la consigna y `foodstore_tp3_carga` para contrastar volumen. El destino descartable fue `foodstore_restore_test`; no se sustituyeron las fuentes.

## Procedimiento y validaciones históricas

Se generaron respaldos custom con `pg_dump -Fc`; se creó el destino desde `template0` y se restauró con `pg_restore --exit-on-error --no-owner --no-privileges`. Cada origen se ensayó sucesivamente, con recreaciones del destino autorizadas por separado. Antes y después se registraron estos conteos exactos:

| Tabla | Dev antes | Dev restaurado | Carga antes | Carga restaurada |
|---|---:|---:|---:|---:|
| categoria | 2 | 2 | 2 | 2 |
| cliente | 3 | 3 | 20.003 | 20.003 |
| producto | 3 | 3 | 50.003 | 50.003 |
| pedido | 5 | 5 | 200.005 | 200.005 |
| detalle_pedido | 7 | 7 | 499.571 | 499.571 |

Los JSON históricos coinciden también en nueve indicadores en cero: precios no positivos, stock negativo, cantidades no positivas, subtotales incorrectos y cuatro referencias huérfanas. No es una comparación de todas las filas ni una recuperación de roles y permisos.

## Objetivos y resultados

Respaldos usados el 24/10: dev iniciado a las 00:32:38,094 (46.877 bytes); carga con referencia previa a `pg_dump` a las 00:32:43,629 (7.321.779 bytes), reutilizado en la repetición.

| Indicador | Objetivo inicial | Dev | Carga, repetición |
|---|---|---:|---:|
| RTO: cronómetro registrado | <=15 minutos | 2,9817064 s | 8,1943358 s |
| Intervalo entre marcas de inicio y fin | Contraste del registro | 2,9865544 s | 8,2566120 s |
| Antigüedad al iniciar, proxy de RPO | RPO <=24 horas | 0,7817533 s | Aprox. 272,6074609 s |

El RTO abarca creación, restauración y validación. Las pequeñas diferencias entre cronómetro y marcas no tienen causa exacta acreditada. La antigüedad aproxima frescura, no pérdida real medida; en carga falta el inicio exacto del respaldo. Los valores están dentro de las metas locales, sin demostrar cumplimiento periódico: no se instaló programación.

## Mantenimiento justificado

El diagnóstico registró cero consultas ajenas activas y cero deadlocks acumulados en ese instante. Tras observar autovacuum/autoanalyze en las tablas grandes, se aplicó ANALYZE solo a `categoria`, `usuario` y `mv_resumen_ventas_categoria_mes` del destino: conservaron 2/3/26 filas; sus columnas con estadísticas pasaron de 0 a 5/9/6. No se aplicó VACUUM FULL ni mantenimiento a las fuentes.

## Incidente, asistencia y conclusión

El incidente documentado fue una falsa diferencia por orden de claves JSON. Se corrigió la comparación semántica y se repitió carga; el RTO corresponde a esa repetición y excluye el diagnóstico anterior. Mejora: persistir tiempos aun ante fallos y probar claves reordenadas antes de repetir.

Codex asistió el procedimiento y la revisión documental; su aceptación docente fue informada por el usuario. Los ensayos reales históricos no validan los scripts finales: su restauración completa solo tiene pruebas simuladas históricas; el baseline actual quedó bloqueado por la política, sin Bypass. Las correcciones de código propuestas siguen pendientes. Se documenta recuperación local con conteos coincidentes, sin garantías de producción; resta revisión humana final.

Evidencia: `evidencias/results.json`, métricas antes/después, `repeticion/timing.json` y logs de `salud_mantenimiento/`. Dumps fuera del repositorio. Límites y propuestas: `script_validation.md` y `docs/cierre_revision_20261024.md`.
