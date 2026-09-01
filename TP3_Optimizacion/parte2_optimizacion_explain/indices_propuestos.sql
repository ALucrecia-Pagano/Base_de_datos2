-- ============================================================================
-- TP3 Parte 2 - Indices propuestos por Kiro, justificados sobre planes reales
-- ============================================================================

-- Q1: ataca Parallel Seq Scan + Sort + Gather Merge (pedido, filtro estado)
CREATE INDEX idx_pedido_estado_fecha ON pedido (estado, fecha_hora DESC);

-- Q2: ataca Seq Scan + Sort (producto, filtro categoria+precio)
CREATE INDEX idx_producto_categoria_precio ON producto (id_categoria, precio_lista);

-- Q3a: ataca Parallel Seq Scan on pedido (filtro de fecha)
CREATE INDEX idx_pedido_fecha_hora ON pedido (fecha_hora);

-- Q3b: ataca Parallel Seq Scan on detalle_pedido (join por id_pedido)
CREATE INDEX idx_detalle_pedido_id_pedido ON detalle_pedido (id_pedido);
