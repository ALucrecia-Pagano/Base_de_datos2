# spec: v_pedido_cliente

Objetivo: exponer pedidos fila a fila con los datos del cliente asociado.

Columnas: pedido_id, fecha_hora, forma_pago, estado, cliente_id, nombre_completo, email.
Criterio de aceptacion: equivalencia bidireccional con EXCEPT frente al JOIN manual entre pedido y cliente.
