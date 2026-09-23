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

**Remedición con salida archivada (corrección posterior a la
devolución):** las 9 corridas de arriba no habían quedado guardadas.
Se repitieron con `Parte_A_Indices/medir_q5_rondas.sql`, con la salida
completa en `Parte_A_Indices/plan_q5_rondas_salida.txt` (mismo orden en
cada ronda: Baseline, Índice A y `work_mem`; el índice y el `work_mem`,
dentro de `BEGIN...ROLLBACK`):

| Ronda | Baseline (ms) | Índice A (ms) | `work_mem = 16MB` (ms) |
|---|---|---|---|
| 1 | 795.568 | 417.282 | 323.945 |
| 2 | 433.272 | 409.968 | 306.372 |
| 3 | 385.951 | 405.510 | 297.678 |

La ronda 1 del Baseline (795.568 ms) es la primera consulta de la
sesión y paga el arranque en frío, así que el promedio del Baseline con
las 3 rondas (538.3 ms) queda inflado y haría parecer que el Índice A
mejora. Comparando las rondas 2 y 3: Baseline 409.6 ms, Índice A
407.7 ms (gana una ronda y pierde la otra: sin efecto) y `work_mem`
302.0 ms (~26% menos; es el más rápido en las 3 rondas). En los 9
planes, el Índice A no aparece como nodo de lectura (el planificador lo
ignora), y `work_mem` baja el `HashAggregate` de `Batches: 5` a
`Batches: 1`. La remedición confirma las dos decisiones de abajo.

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

### Candidato propuesto 2 — `idx_detalle_pedido_id_pedido (id_pedido)`: **DESCARTADO por redundante**

Kiro lo propuso como segundo candidato para el join con
`detalle_pedido`. `spec_01` afirmaba que no había ningún índice sobre
`detalle_pedido.id_pedido`, pero es falso: la PK es compuesta,
`PRIMARY KEY (id_pedido, id_producto)`, y un B-tree compuesto sirve
para buscar por su primera columna sola. El candidato duplicaría lo que
ya hace `pk_detalle_pedido`.

**Evidencia:**
- `Parte_A_Indices/plan_detalle_por_id_pedido.txt`: una búsqueda
  `WHERE id_pedido = 100`, sin el candidato, usa
  `Index Scan using pk_detalle_pedido` (2.401 ms).
- `Parte_A_Indices/plan_q5_indice_redundante.txt` (script
  `medir_indice_redundante_q5.sql`, dentro de `BEGIN...ROLLBACK`): Q5
  con el candidato creado tarda 615.608 ms y sin él 612.285 ms. En los
  dos casos el planificador lee `detalle_pedido` con
  `Parallel Seq Scan` (Q5 recorre toda la tabla) y el candidato no se
  usa.

**Decisión: DESCARTADO.** Es el ejemplo literal de sobreindexación de
la consigna (un índice redundante con otro ya existente): tendría costo
de mantenimiento en cada `INSERT` de `detalle_pedido` sin aportar nada
que la PK no haga. El error de `spec_01` quedó corregido con una nota,
sin borrar la afirmación original.

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

**Resultado provisional (sin salida archivada):** Execution Time con índice: **220.899 s**. Mejora: ~19%. Este número no tiene archivo de respaldo; el valor que se toma es el de `plan_q6_despues.txt` (ver abajo).

**Nota de trazabilidad:** los 220.899 s de arriba son la medición hecha
dentro de `BEGIN...ROLLBACK` al probar el candidato por primera vez (ya
con `Index Only Scan`, `Heap Fetches: 0`). La medición final, sobre el
índice ya aplicado en firme, quedó en `Parte_A_Indices/plan_q6_despues.txt`:
**158.728 s**, capturada después de correr `VACUUM ANALYZE producto;`
(ver Punto 5, Prueba 3, donde el mapa de visibilidad se había desactualizado
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
- Aporta una mejora real: ~41% en la medición final archivada
  (`plan_q6_despues.txt`); la medición provisional de ~19% no quedó
  archivada (ver Nota de trazabilidad arriba).
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

**Decisión: DESCARTADO sin crearlo.** Un índice BRIN depende de que los
valores estén físicamente correlacionados con el orden de las páginas
en disco. Con correlación ~0 (el `seed_masivo.sql` genera `fecha_hora`
con `random()`, sin relación con el orden de inserción por `id`), cada
rango de páginas contiene fechas de todo el año mezcladas — el BRIN no
podría descartar casi ninguna.

### Candidato 2 — B-tree simple sobre `fecha_hora`

```sql
CREATE INDEX idx_pedido_fecha_hora_btree ON pedido (fecha_hora DESC);
```

**Primera medición (corrida única, luego revertida):** una comparación
aislada de una corrida de cada lado sugirió que el índice empeoraba el
tiempo (~658 ms sin índice → ~921 ms con índice), aparentemente por
pérdida de paralelismo — el mismo patrón que en TP3-Q3. Con ese único
dato, el índice se había descartado.

**Segunda medición (3 rondas intercaladas, sin salida archivada):** al
re-auditar, se detectó que esa conclusión salía de una sola corrida de
cada escenario — el mismo error metodológico ya evitado en el Caso 1.
Se repitió con 3 rondas intercaladas (Baseline-B-tree-Baseline-B-tree-
Baseline-B-tree), todas dentro de `BEGIN...ROLLBACK`:

| Ronda | Baseline (ms) | B-tree (ms) |
|---|---|---|
| 1 | 380.800 | 358.550 |
| 2 | 390.572 | 327.330 |
| 3 | 343.204 | 329.518 |
| **Promedio** | **371.5** | **338.5** |

El índice ganó en 3 de 3 rondas (~8.9%) y en ese momento se aceptó.
Pero esas rondas no quedaron archivadas, y la diferencia (33 ms) es
menor que la variación de la misma consulta sin ningún cambio (entre
365 y 910 ms, ver la Nota metodológica). Es exactamente lo que señaló
la devolución de la cátedra: una mejora con un margen cercano al ruido.

Los planes "después" completos de cada punto quedaron archivados en `Parte_A_Indices/`:

- `plan_q4_despues.txt` — 414.220 ms (uso de `idx_pedido_fecha_hora_btree`, `Bitmap Index Scan`). Es una corrida única y ya daba un tiempo **peor** que `plan_q4_antes.txt` (378.669 ms), lo que no coincidía con el promedio de la tabla de arriba.
- `plan_q5_despues_workmem.txt` — 336.877 ms con `SET LOCAL work_mem = '16MB'`: el `HashAggregate` pasa de `Batches: 5` con `Disk Usage` a `Batches: 1` sin volcado a disco.
- `plan_q5_despues_indice_descartado.txt` — 301.954 ms: se probó (dentro de `BEGIN...ROLLBACK`) un índice parcial `idx_pedido_no_cancelado_cliente ON pedido (id_cliente) WHERE estado <> 'CANCELADO'`. El planner **no lo usó** — siguió eligiendo `Seq Scan` sobre `pedido`, porque el filtro `estado <> 'CANCELADO'` descarta muy pocas filas (16.620 de ~66.668, ~25%) y no es lo suficientemente selectivo para justificar el índice. Se documenta como índice evaluado y descartado, no aplicado en la base final.
- `plan_q6_despues.txt` — 158.728 s (158728.129 ms según `plan_q6_despues.txt`), confirmado `Index Only Scan` con `Heap Fetches: 0` tras ejecutar `VACUUM ANALYZE producto;` (el mapa de visibilidad estaba desactualizado por los INSERT de prueba del punto anterior, lo que inicialmente forzaba `Index Scan` con fetches al heap).

**Tercera medición (3 rondas intercaladas, salida archivada):**
`Parte_A_Indices/medir_q4_rondas.sql`, con la salida completa en
`Parte_A_Indices/plan_q4_rondas_salida.txt` (`EXPLAIN (ANALYZE, BUFFERS)`
en cada ronda):

| Ronda | Sin índice (ms) | Con índice (ms) |
|---|---|---|
| 1 | 767.525 | 729.226 |
| 2 | 704.008 | 688.866 |
| 3 | 628.264 | 706.615 |
| **Promedio** | **699.9** | **708.2** |

La dirección es inconsistente: el índice mejora en las rondas 1 y 2 y
empeora ~12% en la 3, y en promedio queda levemente peor. El plan
explica por qué: sin índice, `pedido` se lee con `Parallel Seq Scan`
repartido en varios procesos (`loops=2` o `3`); con índice pasa a un
`Bitmap Heap Scan` que corre en un solo proceso (`loops=1`). Se gana en
el filtro de fecha, pero se pierde el paralelismo.

**Decisión final: DESCARTADO.** Una mejora que no supera el ruido no
justifica el costo de mantener el índice en cada `INSERT`/`UPDATE` de
`pedido`. El índice se eliminó de la base
(`DROP INDEX idx_pedido_fecha_hora_btree; ANALYZE pedido;`) y quedó
comentado en `indices.sql` con el historial completo.

### Intervención complementaria — `SET LOCAL work_mem = '16MB'`

Confirmada en TP4-Parte 4 sobre esta misma consulta: elimina el spill
a disco del `HashAggregate`. No depende de ningún índice (ataca el
spill del agregado, no el filtro de fecha), así que con el B-tree
descartado queda como la única intervención aplicable a Q4.

**Cierre del Caso 3:** dos candidatos descartados por motivos
distintos. El BRIN, por estadística (correlación ~0). El B-tree, por
medición: una mejora de ~8.9% en rondas sin archivar no se sostuvo al
remedir con la salida completa, y el plan mostró la pérdida de
paralelismo. La conclusión cambió dos veces, y cada cambio quedó
documentado: lo que se defiende es el proceso de medición, no un
resultado aislado.

## Caso 4 — Q2: Productos de una categoría en un rango de precio

*(Caso agregado en la corrección posterior a la devolución de la
cátedra: con el B-tree de Q4 descartado, la Parte A necesitaba otra
consulta con un cambio de plan real.)*

**Consulta:** Q2 de `queries.sql`:
```sql
SELECT id, nombre, precio_lista, stock
FROM producto
WHERE id_categoria = 1 AND precio_lista BETWEEN 1000 AND 3000
ORDER BY precio_lista;
```

**Plan "antes":** `plan_q2_antes.txt`. `Seq Scan on producto`: recorre
las 50.003 filas y descarta 38.955 (`Rows Removed by Filter`) para
quedarse con 11.048, más un `Sort` por `precio_lista`.

**Por qué no sirven los índices que ya existían sobre `producto`:**
`idx_productos_categoria_activo` e `idx_producto_categoria_precio_activo`
son **parciales** (`WHERE activo = TRUE`). Para usar un índice parcial,
la consulta tiene que garantizar esa condición en su propio `WHERE`.
Q2 no filtra por `activo`, así que usarlos dejaría afuera productos
inactivos que Q2 sí tiene que devolver.

### Candidato — `idx_producto_categoria_precio (id_categoria, precio_lista)`

Especificado en `specs/spec_06_producto_categoria_precio_sin_activo.md`.
Índice compuesto **no parcial**: `id_categoria` para la igualdad y
`precio_lista` para el rango.

**Medición (3 rondas intercaladas):** `Parte_A_Indices/medir_q2_rondas.sql`,
con la salida completa en `Parte_A_Indices/plan_q2_rondas_salida.txt`.
El candidato se creó dentro de `BEGIN...ROLLBACK` en cada ronda.

| Ronda | Sin índice (ms) | Con índice (ms) |
|---|---|---|
| 1 | 30.757 | 17.925 |
| 2 | 24.997 | 16.431 |
| 3 | 26.580 | 17.330 |
| **Promedio** | **27.4** | **17.2** |

El índice mejora en las 3 rondas (~37%), y los rangos no se superponen
(sin índice 25–31 ms, con índice 16–18 ms). El plan pasa de
`Seq Scan on producto` a `Bitmap Heap Scan` con `Bitmap Index Scan`
sobre `idx_producto_categoria_precio`, que lee solo las 11.048 filas
que cumplen el filtro. El `Sort` por `precio_lista` se mantiene en los
dos planes, porque el `Bitmap Heap Scan` no devuelve las filas
ordenadas.

**Antecedente de TP3:** este mismo índice se probó para Q2 en TP3 con
una sola corrida por lado y no mostró mejora (12.384 ms → 12.787 ms,
"dentro del ruido"). Con tiempos tan chicos, una corrida por lado no
alcanza para decidir; la medición de 3 rondas intercaladas de este TP
sí muestra una mejora consistente.

**Decisión: ACEPTADO Y APLICADO EN FIRME**
(`CREATE INDEX idx_producto_categoria_precio ON producto (id_categoria, precio_lista); ANALYZE producto;`).

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


### Prueba 3 — `producto` con los dos índices aceptados (Q6 y Q2)

Con el Caso 4, `producto` pasa a tener dos índices nuevos de este TP.
Se midió el costo de escritura con los dos juntos:
`Parte_A_Indices/medir_escritura_producto_dos_indices.sql`, con la
salida completa en `Parte_A_Indices/medicion_escritura_producto_dos_indices_salida.txt`.
Son 500 `INSERT` en `producto` dentro de transacciones con `ROLLBACK`,
3 rondas intercaladas, medidas con `\timing` de `psql` (no con `time`
de consola).

**Ronda de calentamiento:** el primer `INSERT` de la sesión tardó
65.963 ms por arranque en frío. Queda en la salida, pero no se cuenta.
En una corrida anterior sin calentamiento, ese costo caía en la Ronda 1
"sin índices" y daba la conclusión falsa de que los índices aceleraban
la escritura.

| Ronda | Sin los 2 índices (ms) | Con los 2 índices (ms) |
|---|---|---|
| 1 | 13.505 | 18.407 |
| 2 | 11.225 | 17.462 |
| 3 | 12.578 | 19.168 |
| **Promedio** | **12.4** | **18.3** |

Con los dos índices, cada carga de 500 filas en `producto` tarda
alrededor de un 47% más, en las 3 rondas. Se acepta ese costo porque
`producto` se escribe poco y se lee mucho en reportes: a cambio, Q6
mejora ~41% y Q2 ~37%. Al terminar la prueba se corrió
`VACUUM ANALYZE producto;`, porque los `INSERT` deshechos con
`ROLLBACK` dejan filas muertas que le hacen perder a Q6 el
`Index Only Scan` sin ir al heap.

**Sobre `detalle_pedido`:** la consigna pide medir `INSERT` en
`detalle_pedido`. Ninguno de los índices aceptados vive en esa tabla,
así que un `INSERT` en `detalle_pedido` no tiene que mantenerlos (la
Prueba 1 ya lo mostró: sin diferencia significativa). El costo real de
los índices aceptados aparece en `producto`, y por eso se mide ahí.

**Tres índices sobre `producto` que empiezan por `id_categoria`:**
`idx_productos_categoria_activo` (heredado de TP1, parcial),
`idx_producto_categoria_precio_activo` (Q6, parcial) e
`idx_producto_categoria_precio` (Q2, no parcial). Los dos de TP5 no son
redundantes entre sí: Q2 no puede usar los parciales porque no filtra
por `activo`, y Q6 usa el parcial para resolver el `AVG` con
`Index Only Scan`. Con los dos presentes, un `EXPLAIN` de Q6 confirma
que sigue eligiendo `idx_producto_categoria_precio_activo`
(`Parte_A_Indices/plan_q6_con_dos_indices.txt`). El de TP1 no se toca,
porque está en `schema.sql` y el modelo heredado no se modifica.


### Prueba 4 — `detalle_pedido` con los dos índices aceptados

La consigna pide medir el costo de escritura con `INSERT` en
`detalle_pedido`. Script: `Parte_A_Indices/medir_escritura_detalle_pedido.sql`,
con la salida completa en `Parte_A_Indices/medicion_escritura_detalle_pedido_salida.txt`.
Son 500 `INSERT` en `detalle_pedido` (pares `id_pedido`/`id_producto`
válidos que todavía no existen), con `ROLLBACK` en cada carga, una
ronda de calentamiento y 3 rondas intercaladas, medidas con `\timing`.
En las rondas "sin índices", los dos `DROP INDEX` van en la misma
transacción que el `INSERT`, así que el `ROLLBACK` los restaura y la
base nunca queda sin ellos.

**Calentamiento:** 20.995 ms (no se cuenta).

| Ronda | Sin los 2 índices (ms) | Con los 2 índices (ms) |
|---|---|---|
| 1 | 8.067 | 9.163 |
| 2 | 7.195 | 8.876 |
| 3 | 7.805 | 8.646 |
| **Promedio** | **7.7** | **8.9** |

En las 3 rondas, la carga con índices fue algo más lenta, pero la
diferencia es de ~1,2 ms. No puede deberse a mantener los índices: los
dos viven en `producto`, y un `INSERT` en `detalle_pedido` no los
actualiza (solo mantiene la PK de `detalle_pedido` y verifica las FK
contra las PK de `pedido` y `producto`). Una explicación posible, que
no se verificó, es el orden fijo de las rondas: la ronda "con índices"
corre justo después de una transacción que borró y restauró índices de
`producto`, y PostgreSQL tiene que volver a cargar la información de
esa tabla. Comparado con la Prueba 3 (en `producto`, donde los índices
sí se mantienen: ~6 ms más sobre ~12 ms, un 47%), el efecto en
`detalle_pedido` es chico. **Conclusión:** el costo de escritura de los
índices aceptados se paga al escribir en `producto`, no en
`detalle_pedido`.