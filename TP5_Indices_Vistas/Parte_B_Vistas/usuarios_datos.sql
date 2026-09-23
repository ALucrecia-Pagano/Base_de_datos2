-- TP5 - Parte B: datos de usuario para que la base se pueda reconstruir
-- desde cero y para que la verificacion de equivalencia compare contra
-- filas reales, no contra una tabla casi vacia.
--
-- Incluye las 2 filas administrativas que ya existian en
-- foodstore_tp3_carga (admin@foodstore.com, vero@foodstore.com) pero no
-- estaban en ningun script del repo -- sin esto, recrear la base desde
-- schema.sql + views.sql no reproducia el estado real. Se agregan tal
-- cual estaban (mismo mail, rol y contrasena-hash de ejemplo).
--
-- Idempotente: ON CONFLICT (mail) DO NOTHING, para poder correr
-- views.sql mas de una vez sin fallar por el UNIQUE de mail.
--
-- Los mails de las 5 filas de prueba se tomaron de clientes reales
-- existentes en foodstore_tp3_carga:
--   SELECT id, email FROM cliente ORDER BY id LIMIT 4;
--   1 | ana.gomez@example.com
--   2 | luis.paz@example.com
--   3 | marta.ruiz@example.com
--   4 | usuario1@test.com
-- Sin esto, v_usuario_publico y v_pedido_usuario se verificaban con la
-- tabla usuario en un estado que no probaba nada util (ver duia.md,
-- Punto 2 de la auditoria): ninguna de las 2 filas administrativas
-- coincide con un cliente, asi que el JOIN de v_pedido_usuario daba 0
-- filas de cualquier forma. Las 5 filas de prueba agregan casos reales:
-- usuarios que si matchean con un cliente existente, uno que no
-- matchea con nadie, y uno eliminado que matchea pero debe quedar
-- filtrado.

INSERT INTO usuario (nombre, apellido, mail, celular, contrasena, rol, eliminado) VALUES
    -- Filas administrativas preexistentes en foodstore_tp3_carga, ahora versionadas.
    ('Admin', 'Sistema', 'admin@foodstore.com', '2615000001',
     'hash_ejemplo_no_es_texto_plano_1', 'ADMIN', FALSE),
    ('Vero', 'Reportes', 'vero@foodstore.com', '2615000002',
     'hash_ejemplo_no_es_texto_plano_2', 'VENDEDOR', FALSE),
    -- Coincide con cliente.email de un cliente real (id 1): debe aparecer en v_pedido_usuario.
    ('Ana', 'Gomez', 'ana.gomez@example.com', '2615000101',
     'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3', 'USUARIO', FALSE),
    -- Coincide con cliente.email de un cliente real (id 2): debe aparecer en v_pedido_usuario.
    ('Luis', 'Paz', 'luis.paz@example.com', '2615000102',
     'c775e7b757ede630cd0aa1113bd102661ab38829', 'USUARIO', FALSE),
    -- Coincide con cliente.email de un cliente real (id 3): debe aparecer en v_pedido_usuario.
    ('Marta', 'Ruiz', 'marta.ruiz@example.com', '2615000103',
     '2c624232cdd221771294dfbb310aca000a0df6ac', 'USUARIO', FALSE),
    -- Sin cliente asociado (mail no existe en cliente.email): no debe aparecer en v_pedido_usuario.
    ('Sin', 'Cliente', 'sin.cliente@foodstore-interno.com', '2615000104',
     '5e884898da28047151d0e56f8dc6292773603d0d', 'USUARIO', FALSE),
    -- Coincide con cliente.email de un cliente real (id 4) pero eliminado = TRUE:
    -- debe quedar excluido de v_pedido_usuario y de v_usuario_publico pese al match.
    ('Eliminado', 'DeBaja', 'usuario1@test.com', '2615000105',
     '6f8db599de986fab7a21625b7916589c0a3a5340', 'USUARIO', TRUE)
ON CONFLICT (mail) DO NOTHING;
