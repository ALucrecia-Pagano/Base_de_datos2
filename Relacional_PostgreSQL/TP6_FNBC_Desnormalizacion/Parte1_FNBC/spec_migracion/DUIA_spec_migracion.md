# DUIA — Spec y plan de reversión de la migración FNBC (objetivo 2 del TPI)

| Herramienta | Finalidad | Fecha | Prompt |
|---|---|---|---|
| Antigravity (Gemini Flash High) | Redactar la spec, el plan de reversión y el ensayo de reversión a partir del TP6 Parte 1 | 2026-11-10 | Prompt único con requisitos, archivos de entrada y estructura de salida (resumen en esta tabla) |
| Claude (chat) | Armar el prompt para Antigravity y revisar línea por línea el script y la spec contra el TP6 (diff de las secciones 1 a 9 y del DDL recreado) | 2026-11-10 | Revisión en conversación; correcciones aplicadas a mano |

## Verificación realizada

- El script `ensayo_migracion_reversion.sql` se leyó línea por línea antes de ejecutarlo. Las secciones 1 a 9 se compararon con `diff` contra `tp_fnbc_control_lote.sql`: son idénticas salvo un comentario agregado. El DDL recreado en la sección 14 es idéntico al de la sección 3 del original.
- Ejecución: 2026-11-10, base `foodstore_copia_trabajo` (PostgreSQL 17, local), con `psql -X`, `ON_ERROR_STOP` y `PGCLIENTENCODING=UTF8`. Código de salida 0.
- Respaldo previo: `foodstore_copia_trabajo_antes_reversion_20261110_165440.dump`, fuera del repositorio.
- Evidencia: [evidencia_reversion_20261110_165503.txt](../evidencias/evidencia_reversion_20261110_165503.txt). Contiene los cinco avisos (ida verificada, corte aplicado, paso 1 de reversión, reversión verificada y estructura retirada), la diferencia contra la foto con 0 filas, las 3 filas restituidas y el cierre con `ROLLBACK`.
- Un primer intento falló por conexión (el servidor PostgreSQL estaba detenido); su salida y su respaldo vacío se descartaron y no forman parte de la entrega.

## Correcciones aplicadas a la propuesta de IA

| Archivo | Problema detectado | Corrección |
|---|---|---|
| `ensayo_migracion_reversion.sql` | El comentario decía "secciones 1 a 8", pero también se copió la sección 9 (vista). | Se corrigió a "secciones 1 a 9". |
| `plan_reversion.md` | En la fila E4 las columnas estaban corridas: la acción de restaurar figuraba como forma de detección. | Se reordenó la fila: detección, reversión con `pg_restore` y prueba en la Unidad 6. |
| `plan_reversion.md` | La fila E1 afirmaba que el fallo estaba probado, pero la evidencia del TP6 muestra un cierre normal con `ROLLBACK`, no un error. | Se aclaró que es un mecanismo de PostgreSQL y que no se forzó un fallo. |
| `design.md` | Decía "JOIN natural", pero el script usa `JOIN ... ON` explícito (`NATURAL JOIN` es otra operación). | Se corrigió la redacción. |
| `DUIA_spec_migracion.md` | No declaraba el uso de Claude para armar el prompt y revisar. | Se agregó la fila correspondiente. |

## Limitación asumida

La guarda que detiene la reversión si los datos nuevos violan (lote_id, deposito_id) → responsable_control_id está razonada y se ejecutó en el camino válido, pero no se probó con un caso negativo que la haga fallar.

## Decisión humana

Acepté el ensayo de ida y vuelta porque es la forma más directa de mostrar que la reversión funciona: hace la migración completa, retira la tabla original, la vuelve a armar desde las tablas nuevas y la compara con una foto tomada antes, todo dentro de una transacción que termina en ROLLBACK. Antes de correrlo comparé la parte copiada con el script del TP6 para asegurarme de que no tuviera cambios. Corregí la tabla de escenarios porque daba por probado un fallo que nunca forcé, y prefiero que el plan diga solo lo que la evidencia muestra. La falta de un caso negativo para la validación de LD → C la dejo registrada como limitación; para este objetivo me alcanzó con verificar el camino válido.
