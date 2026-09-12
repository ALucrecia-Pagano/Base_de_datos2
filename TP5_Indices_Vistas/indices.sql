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