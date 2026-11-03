PRAGMA foreign_keys = ON;

-- Evalúa únicamente solicitudes PENDIENTE.
-- La instantánea es la autoridad para esta simulación; no se modifica
-- PostgreSQL ni se descuentan existencias.

DROP TABLE IF EXISTS temp.evaluacion_semaforo;

CREATE TEMP TABLE evaluacion_semaforo AS
SELECT
    c.solicitud_uuid,
    c.id_local,
    COUNT(i.producto_id) AS cantidad_items,
    SUM(
        CASE
            WHEN s.id IS NULL
              OR s.disponible <> 1
              OR s.eliminado <> 0
              OR i.cantidad > s.stock
            THEN 1 ELSE 0
        END
    ) AS cantidad_rojos,
    SUM(
        CASE WHEN s.id IS NULL THEN 1 ELSE 0 END
    ) AS productos_inexistentes,
    SUM(
        CASE WHEN s.id IS NOT NULL AND s.disponible <> 1
             THEN 1 ELSE 0 END
    ) AS productos_no_disponibles,
    SUM(
        CASE WHEN s.id IS NOT NULL AND s.eliminado <> 0
             THEN 1 ELSE 0 END
    ) AS productos_dados_de_baja,
    SUM(
        CASE WHEN s.id IS NOT NULL AND i.cantidad > s.stock
             THEN 1 ELSE 0 END
    ) AS stocks_insuficientes,
    SUM(
        CASE WHEN s.id IS NOT NULL
                  AND i.precio_centavos_visto <> s.precio_centavos
             THEN 1 ELSE 0 END
    ) AS conflictos_precio
FROM cola_sync AS c
LEFT JOIN item_borrador AS i
    ON i.id_local = c.id_local
LEFT JOIN snapshot_servidor AS s
    ON s.id = i.producto_id
WHERE c.estado = 'PENDIENTE'
GROUP BY c.solicitud_uuid, c.id_local;

UPDATE cola_sync AS c
SET
    estado = (
        SELECT CASE
            WHEN e.cantidad_items = 0 OR e.cantidad_rojos > 0
                THEN 'RECHAZADO'
            WHEN e.conflictos_precio > 0
                THEN 'CONFLICTO'
            ELSE 'SIMULADO_APROBADO'
        END
        FROM evaluacion_semaforo AS e
        WHERE e.solicitud_uuid = c.solicitud_uuid
    ),
    motivo = (
        SELECT CASE
            WHEN e.cantidad_items = 0
                THEN 'Solicitud sin ítems'
            WHEN e.productos_inexistentes > 0
                THEN 'Producto inexistente en la instantánea'
            WHEN e.productos_no_disponibles > 0
                THEN 'Producto no disponible'
            WHEN e.productos_dados_de_baja > 0
                THEN 'Producto dado de baja'
            WHEN e.stocks_insuficientes > 0
                THEN 'Stock insuficiente'
            WHEN e.conflictos_precio > 0
                THEN 'Cambió el precio observado'
            ELSE 'Precio, disponibilidad y stock coinciden'
        END
        FROM evaluacion_semaforo AS e
        WHERE e.solicitud_uuid = c.solicitud_uuid
    )
WHERE c.estado = 'PENDIENTE'
  AND EXISTS (
      SELECT 1
      FROM evaluacion_semaforo AS e
      WHERE e.solicitud_uuid = c.solicitud_uuid
  );

DROP TABLE evaluacion_semaforo;

SELECT solicitud_uuid, id_local, estado, motivo
FROM cola_sync
ORDER BY solicitud_uuid;
