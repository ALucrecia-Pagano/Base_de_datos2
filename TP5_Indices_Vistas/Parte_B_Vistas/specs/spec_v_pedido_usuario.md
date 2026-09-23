# spec: v_pedido_usuario

Objetivo: cumplir la vista de pedidos con datos del usuario solicitada por la consigna.

Columnas: pedido_id, fecha_hora, forma_pago, estado, usuario_id, nombre, apellido, mail.
Relacion: el esquema heredado no tiene FK pedido-usuario; se usa mail = email entre usuario y cliente y se filtran usuarios no eliminados.
Criterio de aceptacion: equivalencia bidireccional con EXCEPT frente a la consulta manual con la misma relacion explicita.
