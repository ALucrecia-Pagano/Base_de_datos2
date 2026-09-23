# DUIA — TP5 (Unidad 3, Semana 5: Índices, vistas y vistas materializadas)

**Materia:** Base de Datos II
**Proyecto:** Food Store — continúa el esquema de TP1/TP3/TP4
**Base de trabajo:** `foodstore_tp3_carga`
**Herramientas obligatorias:** Kiro (especificación) + un agente de generación y ejecución de código (OpenCode en Parte A y B; GitHub Copilot en Parte C, según la herramienta de cada integrante) + Git

Esta bitácora registra, para cada pieza del trabajo, qué herramienta se
usó, con qué propósito, el spec/prompt entregado, qué propuso la IA, y
qué se aceptó/modificó/descartó con su justificación técnica.

**Paso 4 del flujo obligatorio (commits descriptivos):** el historial
contiene commits descriptivos por caso y por parte. La auditoria detecto
que algunos commits historicos agrupan mas de una pieza, por ejemplo las
vistas y la vista materializada; los nuevos cambios deben conservarse en
commits separados por pieza, sin afirmar retrospectivamente que el
historial anterior ya cumplia esa separacion. El historial completo es
verificable con `git log --oneline -- TP5_Indices_Vistas/`.

---

## Sesión de auditoría y corrección — Claude Code (2026-09-23)

**Herramienta:** Claude Code (no OpenCode ni Kiro — se declara así para
no atribuirle a OpenCode nada que no generó). **Propósito:** auditar
TP5 contra el texto literal de la consigna, corregir lo que no
verificaba correctamente, y resolver contradicciones detectadas en una
auditoría previa dentro de la misma conversación.

**Prompt literal recibido (tal como se entregó, incluye las reglas no
negociables y las ocho tareas):**

> Contexto: estoy en el repo Base_de_datos2, materia Base de Datos II (UTN FRM). Trabajamos en
> TP5_Indices_Vistas (índices, vistas y vista materializada sobre Food Store, PostgreSQL).
> La base de trabajo es foodstore_tp3_carga (psql -U postgres). La consigna está resumida abajo;
> el TP se evalúa en una defensa oral y el historial de commits es parte de la entrega.
>
> REGLAS (no negociables):
> 1. No inventes mediciones. Todo número que aparezca en el informe tiene que salir de una ejecución
>    real, y la salida completa se archiva en un .txt dentro de la carpeta de la parte correspondiente.
>    Si un resultado contradice lo que ya está escrito, se corrige el texto; no se ajusta el número.
> 2. Antes de cualquier prueba que escriba en la base, hacé un respaldo con pg_dump. Probá índices y
>    cargas dentro de BEGIN...ROLLBACK siempre que se pueda.
> 3. No toques Parte_C_Vista_Materializada/. No reescribas el historial de Git (nada de rebase, amend
>    ni force push). No hagas push: solo commits locales.
> 4. Hacé un commit separado y descriptivo por cada punto de abajo (un commit por pieza).
> 5. No modifiques schema.sql ni las tablas heredadas.
> 6. Antes de hacer git add, fijate si hay dumps .sql de más de 50 MB sin commitear. Si hay, agregalos
>    al .gitignore y avisame; no los subas.
> 7. Antes de empezar, leé todo TP5_Indices_Vistas y mostrame un plan breve. Esperá mi OK.
>
> TAREAS (en este orden):
> 1. GRANT roto — restaurar mv_resumen_ventas_categoria_mes junto a v_pedido_usuario en el GRANT
>    SELECT de seguridad_roles.sql, verificar con SET ROLE y archivar la evidencia.
> 2. Usuarios de prueba — usuario estaba casi vacía; crear usuarios_datos.sql con 5 filas (3 que
>    matcheen con clientes reales, 1 sin cliente asociado, 1 eliminada), sumarlas a views.sql y
>    re-verificar sobre foodstore_tp3_carga.
> 3. Equivalencia exacta — agregar a verificacion_equivalencia.sql una comparación de count(*) por
>    vista, además del EXCEPT, que también haga fallar el script si no coincide.
> 4. Contradicción en Q4 — remedir idx_pedido_fecha_hora_btree con 3 rondas archivadas y actualizar
>    todos los documentos según el resultado real (aceptar o descartar).
> 5. Índice redundante con la PK — corregir spec_01 (sin borrar el error) y documentar
>    idx_detalle_pedido_id_pedido como segundo descarte por sobreindexación, demostrado con
>    EXPLAIN ANALYZE real de Q5.
> 6. Costo de escritura con los índices reales — medir el costo de escritura sobre los índices
>    realmente aceptados en firme, no sobre un índice de control ajeno al TP.
> 7. Tercera consulta con cambio de plan real — evaluar Q1 y Q3, proponer índice solo si hace falta.
> 8. DUIA y README — una entrada por cada tarea, con el prompt literal, declarando la herramienta
>    con honestidad.
>
> AL FINAL mostrame: una tabla con cada punto, su estado, los archivos tocados y el hash del commit;
> cualquier resultado que haya contradicho lo que estaba documentado; la salida de git status y
> git log --oneline -12.

**Aclaraciones y tareas adicionales recibidas durante la misma sesión
(mensajes intercalados mientras se trabajaba, atendidos en el momento y
resumidos acá para que la DUIA quede completa):**

> Aclaración antes de seguir: la Parte C la hizo mi compañero y no quiero pisar su trabajo. No
> modifiques nada dentro de Parte_C_Vista_Materializada/. En duia.md e informe_mediciones.md NO
> edites las secciones de la Parte C. No toques la línea \ir de vista_materializada.sql en
> views.sql. No ejecutes CREATE, DROP ni REFRESH sobre mv_resumen_ventas_categoria_mes. Si algún
> punto necesita cambiar algo de la Parte C, pará y avisame.
>
> Dos ajustes al punto 2: (1) versionar las 2 filas que ya existían en usuario (Admin y Vero) en
> usuarios_datos.sql; (2) hacer que usuarios_datos.sql sea idempotente con ON CONFLICT (mail) DO
> NOTHING. Y de acá en adelante alcanza con un solo respaldo por sesión, no un pg_dump por punto.
>
> Tres agregados antes del punto 8: (A) el DROP de idx_pedido_fecha_hora_btree lo ejecuta el
> usuario, documentarlo como aplicado. (B) Nuevo caso Q2 (productos de categoría 1, precio
> 1000-3000) con el flujo completo: medir plan actual, spec si hace Seq Scan, proponer índice
> explicando por qué los parciales existentes no sirven (Q2 no filtra por activo), 3 rondas
> intercaladas, aceptar o descartar en un commit propio. (C) En el punto 8, actualizar también la
> sección TP5 de Informe_General.md y del README.md de la raíz (cantidad de índices, cantidad de
> vistas, decisión de Q4), sin tocar el párrafo de la Parte C.

**Qué propuso / qué se hizo (resumen; el detalle completo de cada
punto está en las secciones de Caso 1-5 y Punto 5-7 de este archivo, y
en `informe_mediciones.md`):**

| Punto | Qué se encontró | Qué se aceptó / hizo |
|---|---|---|
| 1 | `v_pedido_usuario` nunca se había aplicado en `foodstore_tp3_carga` (solo en `foodstore_copia_trabajo`); el GRANT tampoco incluía la vista materializada | Se creó la vista en firme, se corrigió el GRANT (ambas), se verificó con `SET ROLE` y se archivó la evidencia |
| 2 | `usuario` no estaba vacía (2 filas administrativas preexistentes, no versionadas), y ninguna coincidía con un cliente | `usuarios_datos.sql`: 7 filas (2 preexistentes + 5 de prueba), idempotente con `ON CONFLICT (mail) DO NOTHING` |
| 3 | `EXCEPT` no detecta diferencias de cantidad de filas duplicadas; además el bloque de `v_pedido_cliente` tenía un bug de precedencia (faltaban paréntesis) que lo volvía unidireccional | Se agregó `count(*)` por vista al chequeo, y se corrigieron los paréntesis faltantes |
| 4 | El informe afirmaba +8.9% para `idx_pedido_fecha_hora_btree` sin archivo de salida real, contradicho por `plan_q4_antes/despues.txt` | Remedición con 3 rondas archivadas: dirección inconsistente, promedio final peor. **Descartado**, `DROP INDEX` ejecutado por el usuario y verificado |
| 5 | `spec_01` afirmaba que `detalle_pedido` no tenía índice sobre `id_pedido`; es falso, la PK compuesta ya lo cubre | Spec corregido (con nota, sin borrar el error); candidato demostrado como redundante con EXPLAIN ANALYZE real; segundo descarte por sobreindexación |
| 6 | La medición de costo de escritura usaba un índice temporal ajeno al TP, sobre `detalle_pedido` | Nueva medición sobre `producto`, el único índice real aceptado en ese momento; conclusión honesta pese a un valor atípico en la Ronda 1 |
| 7 | Q1 ya resuelta por un índice de TP3; Q3 parecía resuelta pero por el índice que el Punto 4 descartó (y de hecho la perjudicaba, 2.24x) | No se crea índice nuevo para ninguna; se documenta con planes reales, incluida la medición de Q3 sin el índice |
| Q2 (agregado durante la sesión) | Seq Scan real; los índices parciales existentes no aplican (no filtra por `activo`) | `idx_producto_categoria_precio` — remedido con 3 rondas, aceptado (a diferencia de un intento similar en TP3), aplicado en firme |

---

## Parte A — Plan de indexado asistido por IA

### Lectura línea por línea antes de ejecutar (consigna, punto 3 del flujo obligatorio)

Antes de aplicar cualquier `CREATE INDEX` generado por OpenCode —tanto
dentro de `BEGIN...ROLLBACK` para pruebas como al aplicar en firme— se
leyó el SQL propuesto y se verificó explícitamente:

- Que el tipo de índice (B-tree, parcial, covering, BRIN) coincidiera
  con lo que pedía la spec correspondiente.
- Que las columnas y su orden fueran las que participan del filtro,
  join u `ORDER BY` real de la consulta (no genéricas).
- Que ningún `CREATE INDEX` tocara el modelo de datos ni agregara
  restricciones no pedidas.
- En los casos con condición parcial (`WHERE activo = TRUE`,
  `WHERE estado <> 'CANCELADO'`), que la condición coincidiera
  exactamente con el filtro de la consulta que se buscaba optimizar.

Ningún índice se ejecutó "a ciegas": los que no se entendían del todo
al proponerse (por ejemplo, el `pages_per_range` del candidato BRIN)
se investigaron antes de decidir, no se aplicaron ni se descartaron
sin comprender el mecanismo (ver Caso 3 más abajo, donde el
`pages_per_range = 32` propuesto por Kiro se justificó explícitamente
antes de decidir no crear el índice).

### Caso 1 — Q5: Ranking de clientes por gasto total

| Campo | Detalle |
|---|---|
| Herramienta | Kiro |
| Propósito | Especificar y proponer índice a partir de `specs/spec_01_pedido_estado_detalle_join.md` |
| Spec entregado | Ver `specs/spec_01_pedido_estado_detalle_join.md` — consulta con filtro `estado <> 'CANCELADO'` y join a `detalle_pedido` sin índice sobre `id_pedido` |
| Qué propuso | Dos candidatos: (A) `idx_pedido_no_cancelado_cliente (id_cliente) WHERE estado <> 'CANCELADO'`, (B) `idx_detalle_pedido_id_pedido (id_pedido)` — recomendó probar A primero |
| Herramienta | OpenCode |
| Propósito | Generar y ejecutar el `CREATE INDEX` candidato A, y una alternativa de `work_mem`, dentro de `BEGIN...ROLLBACK` |
| Qué se aceptó | `SET LOCAL work_mem = '16MB'` — control de ruido con 9 corridas intercaladas (3 escenarios x 3 rondas): promedio 526.5 ms (baseline) → 447.2 ms (work_mem), −15.1% |
| Qué se descartó y por qué | Candidato A: el planificador lo ignoró en las 9/9 corridas (`Índice ignorado` en el plan, siempre). Causa: `estado <> 'CANCELADO'` retiene ~75% de la tabla `pedido` — selectividad demasiado baja para que un índice parcial compita con `Seq Scan` paralelo. **Este es el primer caso de descarte por sobreindexación exigido por la consigna** (columna con condición parcial de baja selectividad) |

### Caso 4 — Q5: segundo descarte por sobreindexación (Candidato B, corrección de spec_01)

| Campo | Detalle |
|---|---|
| Herramienta | Claude Code |
| Propósito | Auditoría (2026-09-23): la spec original de Kiro (`spec_01`) afirmaba que `detalle_pedido` no tenía ningún índice sobre `id_pedido` para justificar el Candidato B (`idx_detalle_pedido_id_pedido`). Esa afirmación es falsa: `pk_detalle_pedido` es `PRIMARY KEY (id_pedido, id_producto)`, y al ser `id_pedido` su primera columna, ya sirve como índice utilizable por esa columna sola |
| Qué se hizo | Se corrigió `spec_01` con una nota de corrección (sin borrar el error original) y se demostró la redundancia con `EXPLAIN (ANALYZE, BUFFERS)` de Q5 dentro de `BEGIN...ROLLBACK` (`medir_indice_redundante_q5.sql`, salida en `plan_q5_indice_redundante.txt`) |
| Qué se descartó y por qué | Candidato B (`idx_detalle_pedido_id_pedido`): el plan es **idéntico** con y sin el candidato (`Parallel Seq Scan on detalle_pedido` en ambos casos, 615.6 ms vs. 612.3 ms — dentro del ruido). El optimizador no usa ni la PK ni el candidato para este patrón de acceso. **Segundo caso de descarte por sobreindexación** (índice redundante con otro ya existente, el ejemplo específico que menciona la consigna) |

### Caso 2 — Q6: Productos con precio superior al promedio de su categoría

| Campo | Detalle |
|---|---|
| Herramienta | Kiro |
| Propósito | Proponer índice a partir de `specs/spec_02_producto_categoria_precio.md` |
| Qué propuso | `idx_producto_categoria_precio_activo (id_categoria, precio_lista DESC) WHERE activo = TRUE` — covering index parcial |
| Herramienta | OpenCode |
| Propósito | Ejecutar el índice dentro de `BEGIN...ROLLBACK` y medir contra el baseline de 271.205 s |
| Qué se aceptó | El índice: **APLICADO EN FIRME**. Medición inicial (dentro de BEGIN...ROLLBACK): 271.2s -> 220.9s (~19%). Medición final, tras aplicar el indice en firme y VACUUM ANALYZE (ver plan_q6_despues.txt): 271.2s -> 158.7s (~41%), confirmado `Index Only Scan` con `Heap Fetches: 0` |
| Modificación / salvedad | Se aceptó con la salvedad de que **no resuelve el problema real** (patrón O(n²) de la subconsulta correlacionada, ejecutada 50.003 veces). La solución real ya existe en TP4-Parte3 (reescritura con tabla derivada pre-agregada). Se acepta el índice igual porque no es redundante con el existente y aporta mejora real, aunque modesta |

### Caso 3 — Q4: Top 3 productos por facturación por categoría

| Campo | Detalle |
|---|---|
| Herramienta | Kiro |
| Propósito | Proponer índice a partir de `specs/spec_03_pedido_fecha_brin.md`, comparando explícitamente B-tree vs. BRIN |
| Qué propuso | (1) B-tree `idx_pedido_fecha_hora_btree (fecha_hora DESC)`, (2) BRIN `idx_pedido_fecha_hora_brin (fecha_hora) WITH (pages_per_range=32)` — con advertencia propia de que ambos corren riesgo real, y recomendación de verificar `pg_stats.correlation` antes de crear el BRIN |
| Verificación previa | `SELECT correlation FROM pg_stats WHERE tablename='pedido' AND attname='fecha_hora'` → `0.013` (prácticamente nula) |
| Qué se descartó y por qué (BRIN) | **Descartado tras medirlo.** La correlación fue 0.013 y el plan real mantuvo `Seq Scan`, no utilizó el BRIN y terminó en 571.123 ms; ver `medir_brin_q4.sql` y `plan_q4_brin.txt` |
| Herramienta | OpenCode |
| Propósito | Ejecutar y medir el B-tree dentro de `BEGIN...ROLLBACK` (no descartable solo con estadística) |
| Primera medición (revertida) | Una corrida única sugirió que el índice empeoraba (658 ms → 921 ms). Con ese único dato se había descartado |
| Corrección con control de ruido (sin archivar) | Re-auditoría anterior reportó 3 rondas intercaladas con Baseline promedio 371.5 ms, B-tree promedio 338.5 ms — el índice ganó en 3/3 rondas, dirección consistente. Esa salida nunca se archivó en un .txt |
| Herramienta | Claude Code |
| Propósito | Auditoría externa (2026-09-23): detectar que 371.5/338.5 ms no coincidía con `plan_q4_antes.txt` (378 ms) ni `plan_q4_despues.txt` (414 ms), y remedir con salida archivada (`Parte_A_Indices/medir_q4_rondas.sql`, `plan_q4_rondas_salida.txt`) |
| Qué se descartó y por qué (B-tree, decisión final) | **`idx_pedido_fecha_hora_btree`: DESCARTADO**, revirtiendo la aceptación anterior. Remedición con `DROP`/`CREATE` real dentro de transacciones, 3 rondas: antes 767.5/704.0/628.3 ms (prom. 699.9), después 729.2/688.9/706.6 ms (prom. 708.2) — dirección **inconsistente** (2 rondas mejoran, 1 empeora más de lo que las otras mejoran), promedio final **peor** con el índice. El plan confirma perdida de paralelismo (`Parallel Seq Scan` → `Bitmap Heap Scan` sin workers). Índice comentado en `indices.sql`. El harness bloqueó el `DROP INDEX` en firme cuando lo intentó Claude Code (acción irreversible detectada automáticamente, pese al respaldo pg_dump previo); el usuario ejecutó el `DROP INDEX idx_pedido_fecha_hora_btree` y el `ANALYZE pedido` por su cuenta. Verificado con `SELECT indexname FROM pg_indexes WHERE indexname='idx_pedido_fecha_hora_btree'` → 0 filas: **eliminado en firme** |
| Intervención complementaria | `SET LOCAL work_mem = '16MB'` — ya confirmado en TP4-Parte4 sobre esta misma consulta (ataca el spill del `HashAggregate`, distinto del filtro de fecha que ataca el índice de arriba). No remedido el efecto combinado |

### Punto 5 — Costo de los índices sobre la escritura

| Campo | Detalle |
|---|---|
| Herramienta | Ninguna (medición directa con `psql` + `time`) |
| Hallazgo intermedio | El primer intento de generar 500 `INSERT` de prueba usó subconsultas escalares no correlacionadas (mismo bug de TP3: Postgres las resuelve una sola vez, no por fila). Resultado: `INSERT 0 1` en vez de `INSERT 0 500`. Corregido con la técnica de array + índice aleatorio por fila ya usada en TP3 |
| Medición | Prueba 1 (sobre `detalle_pedido`, tabla sin índices nuevos): 1.036 s → 0.888 s, sin diferencia significativa — resultado trivial porque el índice de esa etapa vivía en `producto`, no en `detalle_pedido`. Prueba 2, corregida (sobre `producto`, la tabla donde vive el índice): `DROP INDEX` → medir sin índice (0.101 s) → recrear índice → medir con índice (0.267 s). **El costo de escritura sí aumenta con el índice presente** (~2.6x en este caso, aunque en términos absolutos ambos siguen siendo rápidos) |

### Punto 6 — Costo de escritura con los índices realmente aceptados en firme

| Campo | Detalle |
|---|---|
| Herramienta | Claude Code |
| Propósito | La medición previa (`medir_escritura_detalle.sql`) usaba un índice temporal sobre `detalle_pedido(cantidad)`, ajeno a este TP. Tras el Caso 3 (índice sobre `pedido` descartado), el único índice aceptado en firme vive en `producto`, así que se remidió específicamente ese |
| Qué se hizo | `Parte_A_Indices/medir_escritura_indices_reales.sql`: 3 rondas intercaladas de `INSERT` de 500 filas en `producto`, `DROP`/`CREATE` real de `idx_producto_categoria_precio_activo` dentro de transacciones, `\timing` (no `time` de consola). Salida completa en `medicion_escritura_indices_reales_salida.txt` |
| Resultado | Antes: 64.763 / 11.103 / 11.700 ms. Después: 20.595 / 19.132 / 16.920 ms. La Ronda 1 "antes" es un valor atípico (primer `INSERT` de la sesión sobre `producto`, costo de arranque); las Rondas 2 y 3 muestran la dirección esperada y consistente con la Prueba 2 original: el índice aumenta el costo de escritura (~45–72%, siempre por debajo de 20 ms absolutos) |
| Qué se aceptó | Se documenta el resultado completo con la Ronda 1 explicada, no descartada. La medición sobre `cantidad` se conserva como prueba complementaria de control, aclarada como índice ajeno al TP |

### Punto 7 — Tercera consulta con cambio de plan real (Q1 y Q3)

| Campo | Detalle |
|---|---|
| Herramienta | Claude Code |
| Propósito | Buscar una tercera consulta con Seq Scan real, ya que Q6 (Caso 2) es la única con índice aceptado tras el descarte del Caso 3. Se evaluaron Q1 y Q3 de `queries.sql` |
| Qué se hizo | `Parte_A_Indices/medir_q1_q3_actual.sql` para medir el plan actual de ambas; salida en `plan_q1_q3_actual.txt`. Para Q3, medición adicional sin `idx_pedido_fecha_hora_btree` dentro de `BEGIN...DROP...ROLLBACK` (`plan_q3_sin_indice_btree.txt`) |
| Qué se encontró (Q1) | Ya usa `Index Scan using idx_pedido_estado_fecha` (3.248 ms) — índice creado en **TP3**, no en este TP. No hace falta ningún índice nuevo |
| Qué se encontró (Q3) | Con `idx_pedido_fecha_hora_btree` presente: `Bitmap Heap Scan` sin paralelismo, 807.912 ms. Sin ese índice: `Parallel Seq Scan` con 2 workers, 359.951 ms — **2.24x más rápida sin el índice**. Coincide con lo que TP3 ya había documentado para un índice similar sobre esta misma consulta (empeoró por pérdida de paralelismo) |
| Qué se aceptó | No se crea ningún índice nuevo para Q1 ni Q3. El hallazgo de Q3 se suma como evidencia adicional (no solo de Q4) de que descartar `idx_pedido_fecha_hora_btree` (Caso 3) es la decisión correcta |

### Caso 5 — Q2: productos de una categoría en un rango de precio

| Campo | Detalle |
|---|---|
| Herramienta | Claude Code |
| Propósito | Nuevo caso de indexado pedido por el usuario. Especificar en `specs/spec_06_producto_categoria_precio_sin_activo.md` a partir del plan real de Q2 (`Seq Scan`, `plan_q2_antes.txt`) |
| Qué propuso | `idx_producto_categoria_precio (id_categoria, precio_lista)`, **sin** condición parcial — los dos índices parciales existentes sobre `producto` tienen `WHERE activo = TRUE` y Q2 no filtra por esa columna, así que no son aplicables (usarlos daría un resultado incorrecto) |
| Verificación previa | En TP3 se había probado un candidato casi idéntico para esta misma consulta con resultado "ninguna mejora, dentro del ruido" (12.384 → 12.787 ms), no aplicado en su momento |
| Qué se hizo | 3 rondas intercaladas dentro de `BEGIN...ROLLBACK` (`medir_q2_rondas.sql`, salida en `plan_q2_rondas_salida.txt`) |
| Resultado | Antes: 30.757/24.997/26.580 ms (prom. 27.4). Después: 17.925/16.431/17.330 ms (prom. 17.2). Mejora consistente en 3/3 rondas (~34–42%, ~37% promedio), plan `Seq Scan` → `Bitmap Heap Scan` en las 3 |
| Qué se aceptó | **`idx_producto_categoria_precio`: ACEPTADO Y APLICADO EN FIRME**, a diferencia del resultado de TP3 sobre el mismo candidato — el dataset actual de `foodstore_tp3_carga` sí muestra una mejora real y consistente |


## Parte B — Vistas para los reportes del sistema

**Estado: implementada.**

### `usuarios.sql`

| Campo | Detalle |
|---|---|
| Herramienta | Kiro |
| Propósito | Especificar en `spec_04_vistas_reportes.md` la necesidad de una tabla de autenticación, ya que el esquema heredado no tenía ninguna |
| Herramienta | OpenCode |
| Propósito | Generar el DDL de `usuarios.sql` a partir de la especificación |
| Qué propuso | `CREATE TYPE rol_usuario` (enum) + `CREATE TABLE usuario` con `contrasena` como hash, sin modificar `cliente` ni ninguna tabla heredada |
| Qué se aceptó | Tal cual: tabla nueva e independiente (ver justificación de por qué esto no viola "no modificar el modelo de datos" más abajo) |

### `vistas.sql`

| Campo | Detalle |
|---|---|
| Herramienta | Kiro |
| Propósito | Especificar las 6 vistas en `spec_04_vistas_reportes.md` |
| Herramienta | OpenCode para las cinco vistas originales; correccion posterior documentada en el spec individual para `v_pedido_usuario` |
| Propósito | Generar el DDL de las vistas en `vistas.sql` |
| Qué propuso | `v_catalogo_productos`, `v_reporte_ventas_cliente`, `v_detalle_pedido_producto`, `v_usuario_publico`, `v_pedido_cliente` y, posteriormente, `v_pedido_usuario` |
| Qué se aceptó | Las 6, verificadas con `EXCEPT` bidireccional contra consultas manuales independientes; `verificacion_equivalencia.sql` falla si alguna diferencia es distinta de cero |

### `seguridad_roles.sql`

| Campo | Detalle |
|---|---|
| Herramienta | Kiro |
| Propósito | Especificar el rol de seguridad exigido por el punto 4 de la consigna |
| Herramienta | OpenCode |
| Propósito | Generar el rol y los `GRANT`/`REVOKE` en `seguridad_roles.sql` |
| Qué propuso | Rol `tp5_reportes` (`NOLOGIN`), `REVOKE ALL` sobre las tablas base, `GRANT SELECT` solo sobre las vistas (incluida la materializada de Parte C) |
| Qué se aceptó | Verificado con `SET ROLE` + intento fallido real sobre `usuario` (ver `evidencia_permiso_denegado.txt`) |

La consigna pide tres vistas (productos vigentes con categoría, pedidos
con datos del cliente, detalle de pedido con nombre de producto) más
una vista que aplique el criterio de seguridad visto en la teoría. El
esquema heredado de TP1-TP4 usa `cliente`, sin tabla de autenticación.
Se agregó una tabla
`usuario` nueva (con contraseña como hash y un enum de rol), sin
reemplazar `cliente` ni afectar las consultas ya existentes — así se
implementó en `usuarios.sql`.

Esta adición es la única modificación al modelo de datos heredado, y
está acotada a un requisito puntual de la propia consigna: el punto 4
exige una vista de seguridad que oculte la columna `contrasena`, pero
ninguna tabla del esquema heredado (`cliente`, `pedido`, `producto`,
`categoria`, `detalle_pedido`) tiene una columna de autenticación con
ese propósito. Cumplir literalmente ese punto sin agregar una tabla
nueva es imposible: no hay contraseña que ocultar si no existe la
columna. La restricción de "no modificar el modelo de datos" se
interpretó, por lo tanto, como protección de las tablas y relaciones
ya existentes (no se modificó ninguna columna, tipo ni restricción de
`cliente`, `pedido`, `producto`, `categoria` ni `detalle_pedido`), y
no como una prohibición de agregar una tabla nueva e independiente
cuando la propia consigna exige, en otro punto, una funcionalidad que
solo esa tabla puede sostener.

Kiro especificó las vistas en `specs/spec_04_vistas_reportes.md`; OpenCode
generó las cinco vistas originales y sus scripts asociados. La vista
`v_pedido_usuario` se incorporó posteriormente con su spec individual y
debe conservarse como corrección separada y trazable.

`vistas.sql` define las seis vistas:

- `v_catalogo_productos`: productos vigentes con categoría.
- `v_reporte_ventas_cliente`: pedidos no cancelados agregados por cliente.
- `v_detalle_pedido_producto`: detalle con nombre del producto.
- `v_usuario_publico`: usuario sin la columna `contrasena`.
- `v_pedido_cliente`: pedidos con datos del cliente.
- `v_pedido_usuario`: pedidos con datos de usuario, vinculados por mail.

`seguridad_roles.sql` crea el rol grupal `tp5_reportes` (NOLOGIN),
revoca todo permiso sobre las tablas base y concede `SELECT`
únicamente sobre las vistas (incluida la vista materializada de la
Parte C). La verificación queda en `verificacion_vistas.sql`, con dos
partes: (1) se comprueban las columnas expuestas por
`v_usuario_publico`, se consultan las vistas con
`SET ROLE tp5_reportes`, y se confirma que la consulta directa sobre
`usuario` falla por falta de privilegios (evidencia real capturada en `Parte_B_Vistas/evidencia_permiso_denegado.txt`); (2) **verificación de
equivalencia (punto 3 de la consigna)**: `verificacion_equivalencia.sql`
compara cada una de las 6 vistas, con `EXCEPT` en ambos sentidos, contra
una consulta manual independiente y falla si alguna diferencia es
distinta de cero. La salida esperada son seis filas con `diferencias = 0`;
debe capturarse al ejecutar el script sobre la base de trabajo.

**Sobre la prueba reversible (punto 3 del flujo obligatorio):** a
diferencia de los índices de Parte A —que se probaron dentro de
`BEGIN...ROLLBACK` porque reconstruir un índice sobre una tabla de
cientos de miles de filas es costoso y su descarte debía quedar sin
rastro—, `usuarios.sql`, `vistas.sql` y `seguridad_roles.sql` son
operaciones no destructivas y de costo trivial: `CREATE VIEW`,
`CREATE TABLE` y `GRANT`/`REVOKE` no modifican datos existentes y se
deshacen al instante con `DROP VIEW`, `DROP TABLE` o revocando el rol,
sin necesidad de envolverlas en una transacción de prueba. La
  verificación de corrección se debe ejecutar antes de darlas por
  definitivas: cada vista se valida con el bloque `EXCEPT` bidireccional
  de `verificacion_equivalencia.sql`; la validación queda reproducible y
  la salida debe capturarse antes de considerar aplicadas las correcciones.

## Parte C — Vista materializada

**Estado: implementada y aplicada en firme.**

| Campo | Detalle |
|---|---|
| Herramienta | Kiro |
| Propósito | Elegir el reporte agregado costoso a materializar y especificar la vista a partir de `specs/spec_05_resumen_ventas_categoria_mes.md`: facturación, pedidos y unidades vendidas por categoría y mes |
| Herramienta | GitHub Copilot (agente de VS Code) |
| Propósito | Generar y ejecutar `vista_materializada.sql`: crear la vista, el índice único, y correr `REFRESH MATERIALIZED VIEW` |
| Qué propuso | `mv_resumen_ventas_categoria_mes`, creada con `WITH DATA` más un índice único sobre `(id_categoria, mes)` para habilitar a futuro `REFRESH MATERIALIZED VIEW CONCURRENTLY` |
| Qué se hizo | Se creó la vista con los datos cargados en el mismo `CREATE`, se creó el índice único, y se midió con `EXPLAIN ANALYZE` la consulta sobre las tablas base y sobre la vista materializada |
| Resultados | Consulta sobre tablas base: **618.156 ms** (4 Hash Join + Seq Scans sobre 499.571 filas de `detalle_pedido` + Sort con spill a disco). Consulta sobre la vista: **0.073 ms** (Seq Scan sobre 26 filas + quicksort en memoria). Mejora ~8468x |
| Frecuencia de refresh recomendada | El reporte es mensual y los datos no necesitan estar al segundo: se recomienda un `REFRESH` diario (por ejemplo, por cron nocturno) en vez de por cada `INSERT`/`UPDATE` de `pedido`/`detalle_pedido` — el costo del `REFRESH` (~600 ms, equivalente a la consulta base) se paga una sola vez y no impacta las lecturas del resto del día |
| Qué se aceptó | La vista queda **aplicada en firme** en `foodstore_tp3_carga`, con el índice único que habilita `REFRESH CONCURRENTLY` a futuro |
| Prueba reversible previa | Antes de aplicarse en firme, se validó como prueba de concepto: se creó la vista con `WITH NO DATA`, se cargó con `REFRESH MATERIALIZED VIEW`, se midió con `EXPLAIN ANALYZE`, y se eliminó con `DROP MATERIALIZED VIEW` sin dejar nada aplicado. Confirmado el resultado, se volvió a crear con `WITH DATA` para la aplicación en firme (equivalente al `BEGIN...ROLLBACK` de Parte A, adaptado a que un `REFRESH` de vista materializada no se prueba dentro de una transacción de forma útil) |
| Lectura previa | El SQL generado (`CREATE MATERIALIZED VIEW`, el índice único, el `REFRESH`) se revisó contra lo pedido en `specs/spec_05_resumen_ventas_categoria_mes.md` antes de ejecutarlo; la corrección del resultado se confirmó después con la medición `EXPLAIN ANALYZE` y con la prueba `WITH NO DATA`/`DROP` descrita arriba |

## Resumen de aceptado/descartado (Parte A)

| Pieza | Decisión | Motivo |
|---|---|---|
| `idx_pedido_no_cancelado_cliente` | Descartado | Ignorado por el planificador (baja selectividad, ~75%) |
| `idx_detalle_pedido_id_pedido` | Descartado (segundo caso) | Redundante con `pk_detalle_pedido (id_pedido, id_producto)`; plan idéntico con y sin el candidato |
| `SET LOCAL work_mem = '16MB'` (Q5) | Aceptado | −15.1% real, confirmado con 9 corridas |
| `idx_producto_categoria_precio_activo` | **Aceptado (aplicado en firme)** | Mejora real ~41% (271.2s -> 158.7s, medicion final tras VACUUM ANALYZE; ver informe_mediciones.md Caso 2), con salvedad de que no resuelve el O(n²) de fondo |
| `idx_pedido_fecha_hora_brin` | Descartado, medido igual | Correlación física ~0; medido dentro de BEGIN...ROLLBACK, confirmó Seq Scan sin usar el BRIN (571.1 ms) |
| `idx_pedido_fecha_hora_btree` | **Descartado (decisión final, 2026-09-23) — DROP ejecutado** | Historial completo: descartado por corrida única (658→921ms) → aceptado por 3 rondas no archivadas (+8.9%) → **descartado de nuevo** por remedición archivada con `DROP`/`CREATE` real: dirección inconsistente entre rondas, promedio final peor con el índice (~700 → ~708 ms), pérdida de paralelismo confirmada en el plan; además perjudicaba a Q3 (Punto 7, 2.24x más lenta). El `DROP INDEX idx_pedido_fecha_hora_btree` y el `ANALYZE pedido` posteriores se ejecutaron en firme sobre `foodstore_tp3_carga`; verificado con `pg_indexes` que ya no existe |
| `SET LOCAL work_mem = '16MB'` (Q4) | Aceptado (complementario) | Ya confirmado en TP4 sobre la misma consulta; ataca un cuello de botella distinto al del (descartado) índice |
| `idx_producto_categoria_precio` (Q2) | **Aceptado (aplicado en firme)** | Candidato similar ya probado sin éxito en TP3; remedido con 3 rondas sobre el dataset actual: mejora consistente ~37% (Seq Scan → Bitmap Heap Scan), 3/3 rondas a favor. Ver Caso 5 |