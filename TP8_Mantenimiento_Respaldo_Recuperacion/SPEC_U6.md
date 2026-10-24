# SPEC_U6 — Operación y recuperación

## Alcance y frecuencia

`foodstore_dev` representa la base original local `foodstore`; `foodstore_tp3_carga` agrega una comparación de volumen. Cada origen tiene su respaldo y línea base. El único destino es `foodstore_restore_test`. Las fuentes y el material de Mateo permanecen intactos.

| Frecuencia | Acción | Evidencia de éxito |
|---|---|---|
| Diaria | Respaldo de ambos orígenes | Dump custom fechado, no vacío, código 0 y logs. |
| Diaria | Chequeo de salud | Diagnóstico fechado de tamaños, actividad, estadísticas y autovacuum. |
| Semanal | Revisión y mantenimiento justificado | Estadísticas previas, decisión y validación posterior. |
| Semanal | Restauración de ambos respaldos, sucesivamente | Conteos e integridad coincidentes, logs y tiempos. |

## Seguridad

Revisar manualmente scripts; toda ejecución requiere autorización específica. Usar autenticación sin contraseñas en scripts ni evidencias. Registrar fecha, base, resultado y errores; ante fallos, salir con código distinto de cero. Si el destino existe, detenerse: nunca borrarlo automáticamente. Toda recreación necesita decisión explícita del operador. Guardar respaldos fechados fuera del repositorio sin sobrescribir anteriores; revisar espacio y retención. Las evidencias pueden incorporarse al repositorio. Al integrar, aplicar también sus AGENTS y protocolo de seguridad. El diagnóstico es de lectura; el mantenimiento exige la copia de prueba. Revisar estadísticas antes del ANALYZE puntual y confirmar conteos preservados; no usar VACUUM FULL periódicamente.

## Validación y objetivos

Acordar ventana sin escrituras; comparar conteos exactos previos y posteriores de `categoria`, `cliente`, `producto`, `pedido` y `detalle_pedido`. Verificar `precio_lista`, stock y precio unitario no negativos, cantidades positivas, subtotales y referencias sin huérfanos. Distinguir conteos de estimaciones.

Requisitos conservados, implementación parcial: el validador actual aún tiene cuatro indicadores; faltan subtotal y cuatro referencias. La revisión de cierre dejó las correcciones propuestas sin aplicar por bloqueo del baseline, según indicación del usuario. Ver `docs/cierre_revision_20261024.md`; no interpretar esta SPEC como prueba de cumplimiento del código actual.

La SPEC inicial del 23/10 ya fijaba RPO ≤24 horas y RTO ≤15 minutos. Los ensayos observados quedan dentro de esos objetivos de laboratorio; no prueban cumplimiento periódico ni garantizan producción. Medir RTO desde antes de crear el destino hasta terminar validaciones. La antigüedad del respaldo aproxima frescura (proxy de RPO), no pérdida medida. No se instaló programación periódica.

El éxito operativo y el cumplimiento de objetivos se evalúan por separado: un PASS del script actual no acredita por sí solo los umbrales. Conservar cronómetro e intervalo entre marcas como magnitudes distintas, sin atribuir una causa no comprobada a sus diferencias.

## Revisión

El estudiante debe revisar la entrega. Se utilizó Codex, alternativa aceptada por la cátedra según el usuario; no se atribuyen ejecuciones a OpenCode ni revisión humana exhaustiva realizada. Detalles en `LEEME_ENTREGA.md` e historial inicial conservado en evidencias.
