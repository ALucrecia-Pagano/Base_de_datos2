# SPEC_U6 — Mantenimiento, respaldo y recuperación de FoodStore

## 1. Objetivo y alcance

Planificar respaldo, monitoreo, mantenimiento y recuperación de FoodStore en PostgreSQL 16 o superior. Origen requerido: `foodstore`; destino descartable: `foodstore_restore_test`. Existencia y esquema pendientes de comprobación autorizada; no se presume equivalencia con `foodstore_dev`.

## 2. Plan de mantenimiento

| Tarea | Frecuencia | Evidencia | Condición de éxito |
|---|---|---|---|
| Respaldo automatizable | Diaria | Custom `.dump` fechado y log | `pg_dump`: código 0; archivo no vacío y log generado. |
| Salud automatizable | Diaria | Salida de `health_check.sql` | Controles sin error; anomalías documentadas. |
| Revisión de mantenimiento | Semanal | Tuplas muertas, autovacuum y estadísticas | Diagnóstico y acción segura justificados. |
| Restauración de prueba | Semanal | Log, validaciones y tiempos | Destino recuperado; conteos iguales, cero inválidos. |

## 3. Seguridad

Prohibido eliminar, reemplazar o alterar `foodstore` durante el simulacro. No guardar contraseñas en scripts ni evidencias. Revisar manualmente cada script; toda ejecución requiere autorización específica. Pruebas destructivas únicamente en entornos descartables autorizados. Si el destino existe, detenerse sin sobrescribirlo ni borrarlo. No usar `VACUUM FULL` periódicamente. Guardar respaldos fuera del repositorio sin sobrescribir anteriores; preservar evidencias y aplicar el [protocolo de seguridad](../protocolo_seguridad.md).

## 4. Criterios de validación

Verificar resultado de `pg_dump`, respaldo y log; ante fallos, informar error. Su existencia no prueba restaurabilidad. Comparar conteos previos al respaldo de `categoria`, `cliente`, `producto`, `pedido` y `detalle_pedido` con los restaurados, acordando una ventana sin escrituras. Confirmar el esquema: se documenta `producto.precio_lista`, frente a `precio` del ejemplo. Exigir cero productos con precio/stock negativos y cero detalles con cantidad no positiva o precio unitario negativo. No inventar evidencias.

## 5. Objetivos RPO/RTO y medición

**Objetivos previstos, no medidos:** RPO ≤ 24 horas por respaldos diarios exitosos; RTO ≤ 15 minutos como hipótesis de recuperación local, sujeta a la carga real.

RPO observado: antigüedad del respaldo al iniciar el simulacro, sin inferir pérdida efectiva. RTO observado: desde antes de crear el destino hasta completar validaciones. Comparar con objetivos y explicar desvíos; mediciones pendientes.

Fuente principal: [consigna oficial, Parte 1](<TPUnidad_6_Mantenimiento_FoodStore (1).pdf>). Asistencia documental: Codex; revisión humana pendiente.
