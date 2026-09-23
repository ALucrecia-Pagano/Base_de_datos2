# spec: v_catalogo_productos

Objetivo: exponer el catalogo operativo de productos vigentes con su categoria.

Columnas: producto_id, producto, categoria, precio_lista, stock.
Filtros: producto.activo = TRUE y categoria.activo = TRUE.
Criterio de aceptacion: equivalencia bidireccional con EXCEPT frente al JOIN manual.
