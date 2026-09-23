# Informe de mediciones — TP5 (Índices)

**Base:** `foodstore_tp3_carga` · **Motor:** PostgreSQL

## Caso 1 — Q5: Ranking de clientes por gasto total

**Consulta:**
```sql
SELECT c.nombre_completo, SUM(dp.subtotal) AS total_gastado,
       DENSE_RANK() OVER (ORDER BY SUM(dp.subtotal) DESC) AS puesto
FROM cliente c
JOIN pedido p ON p.id_cliente = c.id AND p.estado <> 'CANCELADO'
JOIN detalle_pedido dp ON dp.id_pedido = p.id
GROUP BY c.id, c.nombre_completo
ORDER BY puesto;
```

**Plan "antes" (baseline, sin cambios):** `plan_q5_antes.txt`. Execution
Time inicial: 527.637 ms. Nodo relevante: `Finalize HashAggregate` con
`Batches: 5, Disk Usage: 1568kB` (spill a disco), y `Parallel Seq Scan
on pedido` con `Filter: estado <> 'CANCELADO'`, descartando ~25% de las
filas (selectividad real ~75%, no el ~83% que había estimado la IA antes de medir — la estimación inicial de Kiro se corrigió tras medir la selectividad real con `pg_stats`).

### Candidato propuesto 1 — `idx_pedido_no_cancelado_cliente (id_cliente) WHERE estado <> 'CANCELADO'`

Propuesto por Kiro a partir de `specs/spec_01_pedido_estado_detalle_join.md`.

**Control de ruido:** 3 escenarios (Baseline / Índice A / `work_mem`),
3 rondas en orden intercalado (9 corridas totales), cada una dentro de
`BEGIN...ROLLBACK` para no dejar nada aplicado durante la prueba.

| Corrida | Escenario | Execution Time | Plan |
|---|---|---|---|
| 1 | Baseline | 615.794 ms | Parallel Seq Scan, 5 batches a disco |
| 2 | Índice A | 612.803 ms | Índice ignorado, mismo plan que baseline |
| 3 | work_mem | 610.424 ms | 1 batch, sin spill |
| 4 | Baseline | 528.812 ms | Parallel Seq Scan, 5 batches a disco |
| 5 | Índice A | 482.216 ms | Índice ignorado, mismo plan que baseline |
| 6 | work_mem | 377.322 ms | 1 batch, sin spill |
| 7 | Baseline | 434.925 ms | Parallel Seq Scan, 5 batches a disco |
| 8 | Índice A | 455.060 ms | Índice ignorado, mismo plan que baseline |
| 9 | work_mem | 353.851 ms | 1 batch, sin spill |

**Promedios:**

| Escenario | Promedio | Dif. vs. baseline |
|---|---|---|
| Baseline | 526.5 ms | — |
| Índice A | 516.7 ms | −1.8% (dentro del ruido) |
| `work_mem = 16MB` | 447.2 ms | −15.1% |

### Decisión — Índice A: **DESCARTADO**

El plan confirma "Índice ignorado" en las 9 de 9 corridas, sin
excepción — no es un efecto de ruido, es una decisión estructural del
optimizador. Causa: la condición `estado <> 'CANCELADO'` retiene ~75%
de la tabla `pedido`, una selectividad demasiado baja para que un
índice parcial sobre esa condición compita con un `Seq Scan` paralelo.
Documentado como el caso de descarte explícito por sobreindexación de
la Parte A (columna/condición de baja selectividad).

### Decisión — `SET LOCAL work_mem = '16MB'`: **ACEPTADO**

Elimina el spill a disco del `HashAggregate` final en las 3 rondas sin
excepción (`Batches: 5 → 1`, `Disk Usage → 0`). La mejora de tiempo
varía por ronda (más marcada en las rondas 2 y 3, con caché más
caliente), pero el cambio estructural en el plan es consistente. No
requiere ningún índice ni cambio de esquema — se aplica por sesión.

### Segundo descarte por sobreindexación — Candidato B: `idx_detalle_pedido_id_pedido`

`specs/spec_01_pedido_estado_detalle_join.md` (spec original de Kiro,
Caso 1) proponía este índice afirmando que `detalle_pedido` no tenía
ningún índice sobre `id_pedido`. Esa afirmación es **falsa**: la PK de
`detalle_pedido` es `PRIMARY KEY (id_pedido, id_producto)`, y al ser
`id_pedido` su primera columna, `pk_detalle_pedido` ya funciona como
índice utilizable para filtros y joins por `id_pedido` solo (el mismo
principio por el que un índice compuesto `(a, b)` sirve para filtrar
por `a` solo). Verificado con:

```sql
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'detalle_pedido';
-- pk_detalle_pedido: PRIMARY KEY (id_pedido, id_producto)
```

**Demostración con EXPLAIN ANALYZE de Q5** (`Parte_A_Indices/medir_indice_redundante_q5.sql`,
salida completa en `plan_q5_indice_redundante.txt`), dentro de
`BEGIN...ROLLBACK`:

| Escenario | Nodo sobre `detalle_pedido` | Execution Time |
|---|---|---|
| Con el candidato creado | `Parallel Seq Scan on detalle_pedido` | 615.608 ms |
| Sin el candidato (solo PK) | `Parallel Seq Scan on detalle_pedido` | 612.285 ms |

El plan es **idéntico** con y sin el candidato — el optimizador ni
siquiera considera un acceso por índice a `detalle_pedido` para este
patrón (la consulta necesita la mayoría de las filas de todas formas,
así que `Hash Join` + `Seq Scan` paralelo es más barato que cualquier
acceso indexado). La diferencia de tiempo (615.6 vs. 612.3 ms) está
dentro del margen de ruido.

**Decisión: DESCARTADO por sobreindexación (índice redundante con la
PK).** Es el segundo descarte explícito por sobreindexación de la
Parte A, además del `idx_pedido_no_cancelado_cliente` del Caso 1.

---

*(Siguientes casos se agregan a continuación a medida que se resuelven
las Partes A, B y C.)*

## Caso 2 — Q6: Productos con precio superior al promedio de su categoría

**Consulta:**
```sql
SELECT p.nombre, p.precio_lista
FROM producto p
JOIN categoria cat ON cat.id = p.id_categoria AND cat.activo = TRUE
WHERE p.activo = TRUE
  AND p.precio_lista > (
      SELECT AVG(p2.precio_lista)
      FROM producto p2
      WHERE p2.activo = TRUE AND p2.id_categoria = p.id_categoria
  )
ORDER BY cat.id, p.precio_lista DESC;
```

**Plan "antes":** `plan_q6_antes.txt`. Execution Time: **271.205 s** (271205.318 ms según `plan_q6_antes.txt`)
(~4.5 minutos). Nodo relevante: `Nested Loop` con `SubPlan 1` ejecutado
**50.003 veces** (una por producto), cada una con `Bitmap Heap Scan`
sobre `producto` filtrando por `id_categoria` — patrón O(n²).

### Candidato — `idx_producto_categoria_precio_activo (id_categoria, precio_lista DESC) WHERE activo = TRUE`

Propuesto por Kiro (`specs/spec_02_producto_categoria_precio.md`),
probado con OpenCode dentro de `BEGIN...ROLLBACK`.

**Resultado:** Execution Time con índice: **220.899 s**. Mejora: ~19%.

**Nota de trazabilidad:** los 220.899 s de arriba son la medición hecha
dentro de `BEGIN...ROLLBACK` al probar el candidato por primera vez (ya
con `Index Only Scan`, `Heap Fetches: 0`). La medición final, sobre el
índice ya aplicado en firme, quedó en `Parte_A_Indices/plan_q6_despues.txt`:
**158.728 s**, capturada después de correr `VACUUM ANALYZE producto;`
(ver Caso 3, Punto 5, donde el mapa de visibilidad se había desactualizado
por los INSERT de prueba y forzaba temporalmente un `Index Scan` con
fetches al heap). Ese último número —no el 220.899 s— es el que refleja
el estado real de la base entregada: mejora de **271.205 s → 158.728 s
(~41%)**, mayor a la estimada inicialmente en esta sección.
El plan confirma `Index Only Scan` con `Heap Fetches: 0` — el índice
sí se usa y resuelve el `AVG` sin volver al heap.

### Decisión: **ACEPTADO, con salvedad importante**

El índice funciona correctamente pero **no resuelve el problema real**
de esta consulta: la subconsulta correlacionada sigue ejecutándose
50.003 veces, sin importar cuánto más rápido sea cada ejecución
individual. El cuello de botella es la *cantidad de ejecuciones* del
`SubPlan`, no el costo de cada una — ningún índice puede corregir eso
por sí solo.

La solución real ya existe: en **TP4-Parte 3** (`consulta_b_subconsulta.sql`,
versión V2) se reescribió esta misma consulta reemplazando la
subconsulta correlacionada por una tabla derivada que pre-agrega el
promedio una sola vez por categoría (JOIN en vez de subconsulta por
fila), resolviendo en segundos en vez de minutos — mismo resultado,
verificado por equivalencia con `EXCEPT` en aquel momento.

Se acepta el índice de todas formas porque:
- No es redundante con `idx_productos_categoria_activo` (ese no
  incluye `precio_lista`, no sirve para el `ORDER BY` ni el `AVG`).
- Aporta una mejora real: ~19% en la medicion provisional, ~41%
en la medicion final aplicada en firme (ver Nota de trazabilidad
arriba).
- Sirve para acelerar cualquier consulta futura que ordene productos
  activos por precio dentro de una categoría — no es un índice de un
  solo uso.

**Lección para la defensa oral:** un índice puede funcionar
perfectamente (usarse, evitar ir al heap) y aun así no ser la
herramienta correcta para el problema — cuando el cuello de botella es
la *estructura* de la consulta (ejecutar algo N veces en vez de una),
hay que reescribir, no indexar.

## Caso 3 — Q4: Top 3 productos por facturación dentro de cada categoría

**Consulta:** ver `queries.sql` (Q4) — join de 4 tablas + funciones de
ventana, ya trabajada en TP4-Parte4 pero nunca desde el ángulo de
índices.

**Plan "antes" de referencia:** `plan_q4_antes.txt` (378.669 ms, una
corrida individual — el número oficial de comparación es el promedio
de 3 rondas de control, ver más abajo). Mismo patrón que en TP4:
`Sort ... external merge Disk` (spill a disco), y filtro
`estado <> 'CANCELADO' AND fecha_hora >= now() - interval '6 months'`
sobre `pedido`, reteniendo ~35-47% de las filas según la corrida.

**Nota metodológica:** esta consulta se midió varias veces a lo largo
de la sesión de trabajo (658, 910, 365, 384, 378 ms en distintos
momentos, siempre sin ningún índice nuevo aplicado), con variación
significativa por el estado del caché de PostgreSQL/SO durante una
sesión larga. Esto llevó a que la primera comparación contra el B-tree
(un solo baseline vs. una sola corrida con índice) diera una
conclusión que después se revirtió con control de ruido — ver abajo.

### Candidato 1 — BRIN sobre `fecha_hora`

`specs/spec_03_pedido_fecha_brin.md`. Antes de crearlo, se verificó la
correlación física de la columna:
```sql
SELECT correlation FROM pg_stats WHERE tablename = 'pedido' AND attname = 'fecha_hora';
-- resultado real: 0.013024098
```

**Prueba adicional con BRIN:** se creó el índice dentro de
`BEGIN...ROLLBACK` y se ejecutó la Q4 completa con `EXPLAIN ANALYZE`.
El plan mantuvo `Seq Scan` sobre `pedido`, no utilizó el BRIN y terminó
en **571.123 ms**. La salida completa está archivada en
`Parte_A_Indices/plan_q4_brin.txt`; el script reproducible está en
`Parte_A_Indices/medir_brin_q4.sql`.

**Decisión: DESCARTADO.** La correlación física es 0.013024098 y la
medición confirma que el BRIN no mejora el plan ni el tiempo. Se conserva
como evidencia de descarte por sobreindexación, no como índice aplicado.

### Candidato 2 — B-tree simple sobre `fecha_hora`

```sql
-- DESCARTADO (ver decision final abajo)
CREATE INDEX idx_pedido_fecha_hora_btree ON pedido (fecha_hora DESC);
```

**Primera medición (corrida única, luego revertida):** una comparación
aislada de una corrida de cada lado sugirió que el índice empeoraba el
tiempo (~658 ms sin índice → ~921 ms con índice), aparentemente por
pérdida de paralelismo — el mismo patrón que en TP3-Q3. Con ese único
dato, el índice se había descartado.

**Corrección previa con control de ruido (3 rondas, sin archivar):** al
re-auditar, se reportó una mejora consistente de ~8.9% (371.5 → 338.5
ms, 3 de 3 rondas a favor) y el índice pasó a **ACEPTADO Y APLICADO EN
FIRME**. Esa tabla de 3 rondas nunca quedó respaldada por un archivo de
salida real — solo el resumen en este informe.

**Auditoría externa (2026-09-23) — contradicción detectada:** ni
`plan_q4_antes.txt` (378 ms, corrida única) ni `plan_q4_despues.txt`
(414 ms, corrida única) eran compatibles con los 371.5/338.5 ms
citados arriba, y sin la salida de las 3 rondas archivada no había
forma de confirmar cuál medición (si alguna) era la real.

**Remedición reproducible (`Parte_A_Indices/medir_q4_rondas.sql`,
salida completa en `plan_q4_rondas_salida.txt`):** el índice ya estaba
aplicado en firme, así que "antes" se midió haciendo `DROP INDEX`
dentro de una transacción, `ANALYZE pedido`, y `EXPLAIN (ANALYZE,
BUFFERS)`; "después" recreando el índice de la misma forma. 3 rondas
intercaladas:

| Ronda | Antes (ms) | Después (ms) | Diferencia |
|---|---|---|---|
| 1 | 767.525 | 729.226 | mejora ~5.0% |
| 2 | 704.008 | 688.866 | mejora ~2.2% |
| 3 | 628.264 | 706.615 | **empeora ~12.5%** |
| **Promedio** | **699.9** | **708.2** | **empeora ~1.2%** |

La dirección es **inconsistente** (2 de 3 rondas mejoran levemente, 1
de 3 empeora bastante más de lo que las otras dos mejoran), y en
promedio el índice **empeora** el tiempo. El plan confirma la causa:
con el índice, el nodo sobre `pedido` pasa de `Parallel Seq Scan` (3
workers, `loops=3`) a `Bitmap Heap Scan` **sin paralelismo**
(`loops=1`) — la pérdida de paralelismo compensa o supera la ganancia
de evitar el `Seq Scan`. Es exactamente el riesgo que ya se había
anticipado en `spec_03` y que se había confirmado en TP3-Q3; en la
medición de 3 rondas anterior (no archivada) no se había concretado,
pero en esta remedición sí.

**Por qué los tiempos absolutos no coinciden entre mediciones:** ni
`plan_q4_antes.txt`/`plan_q4_despues.txt` (378/414 ms), ni la tabla
371.5/338.5 ms citada anteriormente, ni esta remedición (~700 ms)
coinciden en magnitud absoluta entre sí. No hay un entorno de
benchmark aislado — es una máquina de desarrollo compartida con otros
procesos — y ya dentro de esta misma remedición el "antes" varía entre
628 y 768 ms (~20% de rango) solo por estado de cache/carga del
sistema entre rondas. Por eso la comparación válida es siempre relativa
y dentro de la misma sesión (antes vs. después, intercalado), nunca
magnitudes absolutas entre sesiones distintas.

Los planes "después" completos de cada punto quedaron archivados en `Parte_A_Indices/`:

- `plan_q4_despues.txt` — 414.220 ms, corrida única histórica, **superada por la remedición de 3 rondas de arriba**; se conserva como evidencia de que ya en su momento no coincidía con el promedio de 3 rondas citado entonces.
- `plan_q4_rondas_salida.txt` — salida completa de las 6 corridas (3 antes + 3 después) que sostienen la decisión final.
- `plan_q5_despues_workmem.txt` — 336.877 ms con `SET LOCAL work_mem = '16MB'`: el `HashAggregate` pasa de `Batches: 5` con `Disk Usage` a `Batches: 1` sin volcado a disco.
- `plan_q5_despues_indice_descartado.txt` — 301.954 ms: se probó (dentro de `BEGIN...ROLLBACK`) un índice parcial `idx_pedido_no_cancelado_cliente ON pedido (id_cliente) WHERE estado <> 'CANCELADO'`. El planner **no lo usó** — siguió eligiendo `Seq Scan` sobre `pedido`, porque el filtro `estado <> 'CANCELADO'` descarta muy pocas filas (16.620 de ~66.668, ~25%) y no es lo suficientemente selectivo para justificar el índice. Se documenta como índice evaluado y descartado, no aplicado en la base final.
- `plan_q6_despues.txt` — 158.728 s (158728.129 ms según `plan_q6_despues.txt`), confirmado `Index Only Scan` con `Heap Fetches: 0` tras ejecutar `VACUUM ANALYZE producto;` (el mapa de visibilidad estaba desactualizado por los INSERT de prueba del punto anterior, lo que inicialmente forzaba `Index Scan` con fetches al heap).

**Decisión final: DESCARTADO**, revirtiendo la aceptación anterior. Se
documenta el historial completo de idas y vueltas (descartado → aceptado
→ descartado de nuevo) porque es la evidencia de que sin un archivo de
salida real por cada medición, ninguna conclusión puede darse por firme
— exactamente lo que esta auditoría vino a corregir. `idx_pedido_fecha_hora_btree`
queda comentado en `indices.sql`; su eliminación de la base de trabajo
quedó pendiente de tu confirmación (ver el resumen final de esta sesión).

### Intervención complementaria — `SET LOCAL work_mem = '16MB'`

Confirmada en TP4-Parte 4 sobre esta misma consulta: elimina el spill
a disco del `HashAggregate`. Es una intervención distinta y compatible
con el índice de arriba (uno ataca el filtro de fecha, el otro el
spill del agregado) — no se remidió el efecto combinado en este TP,
queda como posible mejora adicional a futuro.

**Cierre del Caso 3:** dos candidatos de índice descartados (BRIN por
estadística y medición; B-tree por medición reproducible final, tras
un historial de idas y vueltas por mediciones no archivadas), y una
intervención complementaria ya confirmada en otro TP (`work_mem`).
Buen ejemplo de
que el proceso de medición importa tanto como el resultado.

## Punto 5 — Costo de los índices sobre la escritura

**Prueba 1 (inicial, sobre `detalle_pedido`):** insertar 500 filas en
`detalle_pedido` dentro de una transacción con `ROLLBACK`, midiendo el
tiempo total con `time` sobre el comando `psql`.

**Hallazgo previo a la medición:** el primer intento de generar las
500 filas usó subconsultas escalares no correlacionadas
(`(SELECT id FROM pedido ORDER BY random() LIMIT 1)`), el mismo bug ya
documentado en TP3 — PostgreSQL las resuelve una sola vez para toda la
sentencia, no una vez por fila. Resultado: `INSERT 0 1` en vez de
`INSERT 0 500`. Corregido con la misma técnica de TP3 (array_agg +
índice de array aleatorio por fila), confirmando `INSERT 0 500` antes
de medir el tiempo real.

| Momento | Índices nuevos aplicados | Tiempo real (`INSERT` 500 filas en `detalle_pedido`) |
|---|---|---|
| Antes | Ninguno | 1.036 s |
| Después | `idx_producto_categoria_precio_activo` (sobre `producto`) | 0.888 s |

**Observación (detectada en re-auditoría con Kiro):** esta primera
prueba no mide el escenario más relevante — el único índice aplicado
en firme vive en `producto`, no en `detalle_pedido`, así que el
resultado "sin cambio significativo" es esperable pero trivial: no
prueba el costo real de mantener un índice en la tabla donde
efectivamente se escribe.

**Prueba 2 (corregida, sobre `producto`, la tabla donde vive el
índice):** insertar 500 filas en `producto` (misma técnica de
`array_agg`, sin el bug de aleatoriedad ya que solo depende de
`categoria`, con apenas 2 filas — impacto insignificante), midiendo
antes de crear el índice y después, sobre la misma sesión:

```bash
psql ... -c "DROP INDEX idx_producto_categoria_precio_activo;"
time psql ... -c "BEGIN; INSERT INTO producto (...) SELECT ... FROM generate_series(1,500)...; ROLLBACK;"
psql ... -c "CREATE INDEX idx_producto_categoria_precio_activo ...;"
```

| Momento | Índice sobre `producto` | Tiempo real (`INSERT` 500 filas en `producto`) |
|---|---|---|
| Antes | Sin `idx_producto_categoria_precio_activo` | 0.101 s |
| Después | Con `idx_producto_categoria_precio_activo` | 0.267 s |

**Conclusión real:** al medir sobre la tabla correcta, el costo de
escritura **sí aumenta** con el índice presente (~2.6x más lento en
este caso, aunque en términos absolutos sigue siendo rápido:
milisegundos, no segundos). Esto es exactamente el comportamiento
esperado y el que pide demostrar la consigna: cada índice que se
agrega tiene un costo real de mantenimiento en cada `INSERT`/`UPDATE`
sobre esa tabla, que hay que sopesar contra el beneficio de lectura
que aporta (en este caso, ~41% de mejora en la Q6 del Caso 2 — un
trade-off razonable dado que `producto` se escribe con mucha menos
frecuencia de la que se lee en reportes analíticos).

La Prueba 1 se conserva en el informe (no se borra) porque documenta
un hallazgo metodológico real: medir el costo de escritura en una
tabla sin índices nuevos da un resultado trivial y no debe confundirse
con "los índices no tienen costo de escritura".

## Parte C — Vista materializada (referencia)

La medición completa de la Parte C vive en
`Parte_C_Vista_Materializada/README.md`, y se resume acá para que el
entregable de la Sección 7 (medición en `informe_mediciones.md`) quede
también en este archivo, no solo en el README de la parte.

**Vista:** `mv_resumen_ventas_categoria_mes`, creada con `WITH DATA` e
índice único sobre `(id_categoria, mes)` que habilita, a futuro, un
`REFRESH CONCURRENTLY`.

**Medición (`EXPLAIN ANALYZE`, mismo motor, misma base
`foodstore_tp3_carga`):**

| Consulta | Tiempo real |
|---|---|
| Directa sobre las tablas base (4 `Hash Join` + `Seq Scan` sobre 499.571 filas de `detalle_pedido`, con `Sort` con spill a disco) | 618,156 ms |
| Sobre la vista materializada (`Seq Scan` sobre 26 filas, `quicksort` en memoria) | 0,073 ms |

Mejora: ~8468x.

**Frecuencia de refresh recomendada:** el reporte es mensual y no
necesita estar actualizado al segundo, así que se recomienda un
`REFRESH` diario (por ejemplo, por cron nocturno) en vez de por cada
`INSERT`/`UPDATE` de `pedido`/`detalle_pedido`. El costo del `REFRESH`
(~600 ms, equivalente a la consulta base) se paga una sola vez por día
y no impacta las lecturas del resto del día.

**Implicancia para los usuarios:** entre un `REFRESH` y el siguiente,
el reporte puede mostrar datos de hasta 24 horas de antigüedad —
pedidos o cambios de categoría posteriores al último `REFRESH` no van
a reflejarse hasta la próxima ejecución. Para un reporte gerencial
mensual esto es aceptable; no lo sería para un dashboard operativo que
necesite ver ventas en tiempo real.

## Punto 5 (continuación) — Costo de escritura de `idx_pedido_fecha_hora_btree` (histórico, índice descartado)

**Nota de la auditoría (2026-09-23):** `idx_pedido_fecha_hora_btree`
fue descartado en el Caso 3 (ver arriba) tras la remedición de 3
rondas — no queda aplicado en la base final. Esta sección se conserva
sin modificar el número porque documenta una medición real que sí se
hizo en su momento, pero ya no describe el costo de escritura de un
índice vigente; ver el Punto 6 de esta auditoría
(`Parte_A_Indices/medir_escritura_detalle.sql` o su reemplazo) para la
medición de costo de escritura sobre los índices que sí quedaron
aplicados en firme.

La Prueba 2 del Punto 5 midió el costo de escritura del índice aplicado
sobre `producto`. Faltaba medir el del segundo índice, entonces
aplicado en firme, `idx_pedido_fecha_hora_btree` (sobre `pedido`).

**Prueba (sobre `pedido`):** insertar 500 filas dentro de una
transacción con `ROLLBACK`, con la misma técnica de `array_agg` para
evitar el bug de aleatorización no correlacionada. Con el error del
Caso 3 (Q4) todavía fresco, se midió directamente con **3 rondas
intercaladas** en vez de una sola corrida:

| Ronda | Sin índice | Con índice |
|---|---|---|
| 1 | 0.207 s | 0.202 s |
| 2 | 0.149 s | 0.197 s |
| 3 | 0.148 s | 0.153 s |
| **Promedio** | **0.168 s** | **0.184 s** |

**Conclusión:** el índice agrega ~9,5% de costo de escritura sobre
`pedido` (dirección consistente en 2 de 3 rondas; la primera ronda
está dentro del margen de ruido). Confirma el mismo comportamiento
esperado que en la Prueba 2 sobre `producto`: todo índice tiene un
costo real de mantenimiento en cada `INSERT`, que se sopesa contra la
mejora de lectura que aporta (en este caso, ~8,9% de mejora en Q4 —
ver Caso 3 — un trade-off razonable dado que `pedido` se lee con mucha
más frecuencia de la que se escribe en el flujo analítico de este TP).

## Punto 5 — Medición corregida sobre `detalle_pedido`

La consigna exige medir específicamente una carga de varios cientos de
`INSERT` en `detalle_pedido`. La prueba reproducible quedó en
`Parte_A_Indices/medir_escritura_detalle.sql`: construye 500 pares
válidos, ejecuta tres rondas intercaladas y revierte cada carga con
`ROLLBACK`. El índice usado para aislar el costo de mantenimiento es
temporal y se elimina al finalizar; no modifica los índices aceptados
del TP ni la Parte C.

| Ronda | Sin índice (ms) | Con índice temporal (ms) |
|---|---:|---:|
| 1 | 16.308 | 18.915 |
| 2 | 16.464 | 18.875 |
| 3 | 16.257 | 17.175 |
| **Promedio** | **16.343** | **18.322** |

El índice temporal aumentó el tiempo promedio de escritura en
aproximadamente **12,1%**. Las tres rondas confirmaron `INSERT 0 500`;
la salida completa se obtuvo sobre `foodstore_tp3_carga`, previamente
respaldada, y el índice temporal fue eliminado al terminar.

Salida archivada: `Parte_A_Indices/medicion_escritura_detalle_salida.txt`.