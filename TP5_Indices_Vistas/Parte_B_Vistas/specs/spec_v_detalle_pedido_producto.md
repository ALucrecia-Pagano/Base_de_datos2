# spec: v_detalle_pedido_producto

Objetivo: exponer cada linea de pedido con el nombre del producto.

Columnas: id_pedido, id_producto, producto, cantidad, precio_unitario, subtotal.
Criterio de aceptacion: equivalencia bidireccional con EXCEPT frente al JOIN manual entre detalle_pedido y producto.
