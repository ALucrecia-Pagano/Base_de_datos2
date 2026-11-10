PRAGMA foreign_keys = ON;

-- Importar el CSV en snapshot_servidor_import antes de ejecutar este archivo
-- con ".import --csv --skip 1 ..." para omitir sus encabezados.
-- PostgreSQL exporta los booleanos como t/f; aquí se convierten a 1/0.

INSERT INTO snapshot_servidor (
    id,
    nombre,
    precio_centavos,
    stock,
    disponible,
    eliminado,
    fecha_copia
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
    id,
    nombre,
    precio_centavos,
    stock_visto,
    disponible,
    eliminado,
    fecha_copia
)
SELECT
    id,
    nombre,
    precio_centavos,
    stock,
    disponible,
    eliminado,
    fecha_copia
FROM snapshot_servidor;
