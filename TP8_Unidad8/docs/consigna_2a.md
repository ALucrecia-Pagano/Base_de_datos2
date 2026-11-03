# Consigna 2.a — Instantánea del servidor

La instantánea se obtiene desde una vista de lectura en la copia de pruebas
de PostgreSQL. La vista se encuentra en
[`vista_snapshot_movil.sql`](../postgresql/vista_snapshot_movil.sql).

La correspondencia con el modelo real de Food Store es:

| PostgreSQL | Instantánea | SQLite |
|---|---|---|
| `producto.id` | `id` | `producto_cache.id` |
| `producto.nombre` | `nombre` | `producto_cache.nombre` |
| `producto.precio_lista` | `precio_centavos` | `producto_cache.precio_centavos` |
| `producto.stock` | `stock` | `producto_cache.stock_visto` |
| `producto.activo` | `disponible` | `producto_cache.disponible` |
| `NOT producto.activo` | `eliminado` | `producto_cache.eliminado` |
| `CURRENT_TIMESTAMP` | `fecha_copia` | `producto_cache.fecha_copia` |

El precio se convierte a centavos enteros para evitar `REAL`. La vista no
modifica PostgreSQL. `disponible` y `eliminado` se derivan de `activo`, porque
el modelo real documentado no registra una columna separada de baja lógica.

## Exportación e importación prevista

En PostgreSQL de pruebas:

```sql
\copy (SELECT * FROM v_snapshot_movil)
TO 'servidor_snapshot.csv' CSV HEADER
```

En SQLite:

1. Crear la tabla `snapshot_servidor` con
   [`schema_sqlite.sql`](../movil/schema_sqlite.sql).
2. Importar `servidor_snapshot.csv` en `snapshot_servidor_import`, omitiendo
   la fila de encabezados con `.import --csv --skip 1`.
3. Ejecutar [`importar_snapshot.sql`](../movil/importar_snapshot.sql).
4. Verificar que `producto_cache` contiene la misma cantidad de filas que la
   instantánea.

La exportación quedó registrada en
[`servidor_snapshot.csv`](../movil/servidor_snapshot.csv), y la importación
se utilizó para construir las copias SQLite de las pruebas de las consignas
2.b y 2.c. Los resultados documentados se conservan en
[`resultado_semaforo_2b.md`](resultado_semaforo_2b.md) y
[`resultado_casos_2c.md`](resultado_casos_2c.md).
