-- ============================================================================
-- indices.sql — Índices propuestos y evaluados para TP5 (Unidad 3, Semana 5)
-- Base: foodstore_tp3_carga
--
-- Cada bloque documenta: la consulta que motivó la propuesta, el índice
-- (creado o descartado), y el resultado real medido con EXPLAIN ANALYZE
-- (control de ruido: 3 corridas en orden intercalado, ver
-- informe_mediciones.md para el detalle completo).
-- ============================================================================

-- ----------------------------------------------------------------------------
-- CASO 1 — Q5: Ranking de clientes por gasto total (DENSE_RANK)
-- Spec: specs/spec_01_pedido_estado_detalle_join.md
-- ----------------------------------------------------------------------------

-- Candidato A — DESCARTADO
-- Propuesto por Kiro para atacar el filtro "estado <> 'CANCELADO'" en el
-- join pedido-cliente. NO SE CREA EN FIRME: el planificador lo ignoro en
-- las 9 de 9 corridas de control (3 escenarios x 3 rondas intercaladas),
-- manteniendo Parallel Seq Scan on pedido en todos los casos.
--
-- Motivo del descarte: la condicion "estado <> 'CANCELADO'" deja pasar
-- ~75% de las filas de pedido (Rows Removed by Filter confirma esto en
-- el plan real). Con esa selectividad tan baja, un indice parcial termina
-- cubriendo casi toda la tabla, y el optimizador prefiere el Seq Scan
-- paralelo antes que recorrer un B-tree casi tan grande como el heap.
-- Es un caso real de "columna con condicion parcial de baja selectividad",
-- uno de los ejemplos de sobreindexacion que pide descartar la consigna.
--
-- CREATE INDEX idx_pedido_no_cancelado_cliente
--     ON pedido (id_cliente)
--     WHERE estado <> 'CANCELADO';
-- (dejado comentado a proposito: NO se aplica)

-- Intervencion aceptada — SET LOCAL work_mem
-- No es un indice, es un ajuste de memoria de sesion. El plan base
-- mostraba el HashAggregate final derramando a disco (Batches: 5,
-- Disk Usage > 0). Con work_mem = '16MB' para esta sesion, el
-- HashAggregate paso a 1 solo batch, 100% en RAM, en las 3 rondas de
-- control sin excepcion. Mejora de tiempo real de ~15-29% segun la
-- ronda (ver informe_mediciones.md).
--
-- No requiere ningun CREATE INDEX ni cambio de schema. Se aplica por
-- sesion antes de correr el reporte de ranking:
--   SET LOCAL work_mem = '16MB';

-- ----------------------------------------------------------------------------
-- CASO 2 — Q6: Productos con precio superior al promedio de su categoria
-- Spec: specs/spec_02_producto_categoria_precio.md
-- ----------------------------------------------------------------------------

-- ACEPTADO, con salvedad importante documentada abajo
CREATE INDEX idx_producto_categoria_precio_activo
    ON producto (id_categoria, precio_lista DESC)
    WHERE activo = TRUE;

-- Resultado real: 271.205 s (baseline) -> 220.899 s (con indice), ~19%
-- de mejora. El indice SI se usa (Index Only Scan, Heap Fetches: 0) y
-- resuelve el AVG de la subconsulta sin volver al heap.
--
-- SALVEDAD: el indice no resuelve el problema de fondo de esta
-- consulta. La subconsulta correlacionada se ejecuta 50.003 veces (una
-- por producto) -- un patron O(n * filas_categoria) que ningun indice
-- puede eliminar, porque el costo esta en la CANTIDAD de ejecuciones
-- del SubPlan, no en el costo de cada ejecucion individual.
--
-- La solucion real a este problema (ya resuelta en TP4-Parte3) es
-- REESCRIBIR la consulta con una tabla derivada que pre-agrega el
-- promedio una sola vez por categoria (JOIN en vez de subconsulta
-- correlacionada), no crear un indice. Ver TP4_Reportes_Analiticos/
-- Parte3/consulta_b_subconsulta.sql (version V2), que resuelve el
-- mismo resultado en segundos.
--
-- Se acepta el indice igual porque: (a) es complementario, no
-- redundante, con idx_productos_categoria_activo (ese no incluye
-- precio_lista); (b) aporta una mejora real aunque modesta; (c) sirve
-- ademas para acelerar cualquier otra consulta futura que ordene
-- productos activos por precio dentro de una categoria.

-- ----------------------------------------------------------------------------
-- CASO 3 — Q4: Top 3 productos por facturacion dentro de cada categoria
-- Spec: specs/spec_03_pedido_fecha_brin.md
-- ----------------------------------------------------------------------------

-- Candidato BRIN — DESCARTADO SIN CREAR
-- CREATE INDEX idx_pedido_fecha_hora_brin
--     ON pedido USING BRIN (fecha_hora)
--     WITH (pages_per_range = 32);
--
-- Descartado antes de crearlo, con evidencia estadistica:
--   SELECT correlation FROM pg_stats
--   WHERE tablename = 'pedido' AND attname = 'fecha_hora';
--   -> resultado real: 0.013024098 (practicamente nula)
--
-- Un BRIN funciona eliminando rangos de paginas cuyo [min,max] no
-- intersecta el filtro. Con correlacion ~0, cada rango de paginas
-- contiene fechas de todo el año mezcladas (el seed genero fecha_hora
-- con random() independiente del orden de insercion por id), asi que
-- no hay casi ningun rango descartable. Crear este indice hubiera sido
-- un gasto de tiempo para confirmar algo que la estadistica ya
-- garantiza: no va a servir.

-- Candidato B-tree — CREADO Y MEDIDO, DESCARTADO
-- CREATE INDEX idx_pedido_fecha_hora_btree
--     ON pedido (fecha_hora DESC);
-- (dejado comentado a proposito: NO se aplica en firme)
--
-- Este si se creo y se midio (dentro de BEGIN...ROLLBACK), porque a
-- diferencia del BRIN no habia forma de descartarlo solo con
-- estadisticas -- el riesgo (perdida de paralelismo) solo se confirma
-- ejecutando. Resultado real: el planificador SI lo uso (Bitmap Index
-- Scan + Bitmap Heap Scan), pero el tiempo empeoro: 658.299 ms (sin
-- indice, Parallel Seq Scan) -> 921.482 ms (con indice, Bitmap Heap
-- Scan serializado). El filtro retiene ~47% de la tabla pedido -- muy
-- poco selectivo para justificar abandonar el Seq Scan paralelo.
-- Mismo patron ya documentado en TP3-Q3 con un indice equivalente.

-- Intervencion aceptada — SET LOCAL work_mem (igual que en Caso 1 y en TP4)
--   SET LOCAL work_mem = '16MB';
-- Ya confirmado en TP4-Parte4 que resuelve el spill a disco del
-- HashAggregate de esta misma consulta. No repetido en detalle aca
-- para no duplicar la medicion ya documentada en TP4.