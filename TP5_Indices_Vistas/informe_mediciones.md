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
filas (selectividad real ~75%, no el ~83% que había estimado la IA
antes de medir).

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

**Plan "antes":** `plan_q6_antes.txt`. Execution Time: **271.205 s**
(~4.5 minutos). Nodo relevante: `Nested Loop` con `SubPlan 1` ejecutado
**50.003 veces** (una por producto), cada una con `Bitmap Heap Scan`
sobre `producto` filtrando por `id_categoria` — patrón O(n²).

### Candidato — `idx_producto_categoria_precio_activo (id_categoria, precio_lista DESC) WHERE activo = TRUE`

Propuesto por Kiro (`specs/spec_02_producto_categoria_precio.md`),
probado con OpenCode dentro de `BEGIN...ROLLBACK`.

**Resultado:** Execution Time con índice: **220.899 s**. Mejora: ~19%.
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
- Aporta una mejora real, aunque modesta (~19%).
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

**Plan "antes":** `plan_q4_antes.txt`. Execution Time: **658.299 ms**.
Mismo patrón que en TP4: `Sort ... external merge Disk` (spill a
disco) como cuello de botella principal, y filtro
`estado <> 'CANCELADO' AND fecha_hora >= now() - interval '6 months'`
sobre `pedido`, reteniendo ~35.5% de las filas.

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
podría descartar casi ninguna. Se documenta el descarte con evidencia
estadística, sin gastar tiempo en crear y medir algo que ya se sabe
que no va a servir.

### Candidato 2 — B-tree simple sobre `fecha_hora`

```sql
CREATE INDEX idx_pedido_fecha_hora_btree ON pedido (fecha_hora DESC);
```

Probado con OpenCode dentro de `BEGIN...ROLLBACK` (no se aplicó en
firme). A diferencia del BRIN, este sí había que medirlo — el riesgo
(pérdida de paralelismo) no se puede descartar solo con estadísticas.

**Resultado real:** el planificador **sí usó** el índice (`Bitmap
Index Scan` + `Bitmap Heap Scan`), pero el tiempo **empeoró**:
658.299 ms → **921.482 ms**. El filtro retiene ~47% de la tabla
`pedido` — selectividad demasiado baja para que valga la pena
abandonar el `Parallel Seq Scan`. Mismo patrón exacto ya documentado en
TP3-Q3 con un índice equivalente sobre la misma columna.

**Decisión: DESCARTADO con evidencia empírica.**

### Intervención aceptada — `SET LOCAL work_mem = '16MB'`

Ya confirmada en TP4-Parte 4 sobre esta misma consulta: elimina el
spill a disco del `HashAggregate`, con mejora real medible. No se
repite la medición en detalle acá para no duplicar lo ya documentado
en `TP4_Reportes_Analiticos/Parte4/analisis_optimizacion.md`.

**Cierre del Caso 3:** dos tipos de descarte distintos — uno resuelto
con estadísticas previas (BRIN, sin necesidad de crear ni medir), otro
que exigió crear y medir para confirmar el riesgo (B-tree, donde el
optimizador *sí* lo usó pero el tiempo real empeoró de todas formas).
Ningún índice ayuda a esta consulta; la única intervención efectiva
sigue siendo `work_mem`, consistente con TP4.

## Punto 5 — Costo de los índices sobre la escritura

**Prueba:** insertar 500 filas en `detalle_pedido` dentro de una
transacción con `ROLLBACK` (para medir sin persistir), midiendo el
tiempo total con `time` sobre el comando `psql`.

**Hallazgo previo a la medición:** el primer intento de generar las
500 filas usó subconsultas escalares no correlacionadas
(`(SELECT id FROM pedido ORDER BY random() LIMIT 1)`), el mismo bug ya
documentado en TP3 — PostgreSQL las resuelve una sola vez para toda la
sentencia, no una vez por fila. Resultado: `INSERT 0 1` en vez de
`INSERT 0 500`. Corregido con la misma técnica de TP3 (array_agg +
índice de array aleatorio por fila), confirmando `INSERT 0 500` antes
de medir el tiempo real.

| Momento | Índices nuevos aplicados | Tiempo real (`INSERT` 500 filas) |
|---|---|---|
| Antes | Ninguno | 1.036 s |
| Después | `idx_producto_categoria_precio_activo` (sobre `producto`) | 0.888 s |

**Conclusión:** el tiempo de escritura en `detalle_pedido` no cambió de
forma significativa (diferencia dentro del ruido normal entre
corridas). Esto es el resultado **esperado**: el único índice que se
aplicó en firme hasta este punto vive en la tabla `producto`, no en
`detalle_pedido` — el costo de mantenimiento de un índice solo se paga
en la tabla donde ese índice existe. Si en la Parte A se llegara a
aceptar algún índice sobre `pedido` o `detalle_pedido` directamente,
ahí sí correspondería repetir esta medición para ver el costo real de
escritura en esa tabla puntual.