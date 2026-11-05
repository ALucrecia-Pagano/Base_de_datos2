PRAGMA foreign_keys = ON;

-- Recarga la instantánea en una tablet que ya tiene datos.
-- Antes de ejecutarlo: vaciar snapshot_servidor_import e importar el CSV nuevo
-- con ".import --csv --skip 1 ...".
-- No usa DELETE sobre producto_cache: item_borrador la referencia por clave
-- foránea. Cada fila se actualiza en su lugar (la fila queda aunque el
-- producto se haya dado de baja).

BEGIN;

DELETE FROM snapshot_servidor;

INSERT INTO snapshot_servidor (
    id, nombre, precio_centavos, stock, disponible, eliminado, fecha_copia
)
SELECT
    CAST(id AS INTEGER),
    nombre,
    CAST(precio_centavos AS INTEGER),
    CAST(stock AS INTEGER),
    CASE disponible WHEN 't' THEN 1 WHEN 'f' THEN 0 END,
    CASE eliminado WHEN 't' THEN 1 WHEN 'f' THEN 0 END,
    fecha_copia
FROM snapshot_servidor_import;

INSERT INTO producto_cache (
    id, nombre, precio_centavos, stock_visto, disponible, eliminado, fecha_copia
)
SELECT id, nombre, precio_centavos, stock, disponible, eliminado, fecha_copia
FROM snapshot_servidor
WHERE true
ON CONFLICT (id) DO UPDATE SET
    nombre = excluded.nombre,
    precio_centavos = excluded.precio_centavos,
    stock_visto = excluded.stock_visto,
    disponible = excluded.disponible,
    eliminado = excluded.eliminado,
    fecha_copia = excluded.fecha_copia;

COMMIT;