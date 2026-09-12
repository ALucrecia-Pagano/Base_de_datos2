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