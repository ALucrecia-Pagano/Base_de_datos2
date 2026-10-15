-- TP7 C/D — instalar_entorno_local.sql (INSTALACIÓN PERSISTENTE, para revisión).
-- Basado en preparar_entorno_local.sql, cuya validación reversible ya pasó (exit 0,
-- ROLLBACK final). Ese archivo de validación se conserva intacto con ROLLBACK;
-- ESTE archivo es el único destinado a persistir, y termina con COMMIT únicamente
-- después de superar todos los controles.
-- Requiere: psql -X -v lab_c_password_01='…' -v lab_c_password_02='…' -f instalar_entorno_local.sql
-- Advertencia: -v NO evita exposición en historial shell, ps ni log del servidor.
-- Solo sintéticas de laboratorio. Sin COMMIT anticipado, sin ALTER SYSTEM.
-- Reutiliza roles.sql mediante \ir, sin modificar A/B.
-- Crea únicamente: extensión pgcrypto, tipo rol_usuario, tabla usuario, 5 vistas,
-- materializada + índice, 2 funciones (+REVOKE FROM PUBLIC), 7 roles vía roles.sql
-- (con sus GRANTs) y los 2 sintéticos lab_c_incidente_01/02 con hashes bcrypt válidos.
-- NO altera usuarios ni datos de las cinco tablas originales (solo las lee para las
-- vistas/materializada). NO toca BITACORA.md.
-- Antes del COMMIT neutraliza los placeholders de roles.sql con PASSWORD NULL en
-- app_web y admin_datos: el laboratorio usa cambios de rol desde la conexión
-- administrativa y no necesita esos logins por contraseña.

\set ON_ERROR_STOP on

\if :{?lab_c_password_01}
\else
DO $$ BEGIN RAISE EXCEPTION 'Falta -v lab_c_password_01 (sintética, no real), STOP'; END $$;
\endif
\if :{?lab_c_password_02}
\else
DO $$ BEGIN RAISE EXCEPTION 'Falta -v lab_c_password_02 (sintética, no real), STOP'; END $$;
\endif

BEGIN;

-- Contexto de esquema explícito + transferencia transaccional de secretos (fuera de $$).
SET LOCAL search_path TO public, pg_temp;
SET LOCAL my.lab_pw01 TO :'lab_c_password_01';
SET LOCAL my.lab_pw02 TO :'lab_c_password_02';

-- 1. Abort-on-existence (vacío inicial; cualquier existencia => STOP, sin sobrescribir).
DO $$
BEGIN
  IF current_database() <> 'foodstore_dev' THEN
    RAISE EXCEPTION 'abortado: base actual=% se esperaba foodstore_dev', current_database();
  END IF;
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    RAISE EXCEPTION 'conflicto: extension pgcrypto ya existe, STOP';
  END IF;
  IF to_regtype('public.rol_usuario') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: tipo public.rol_usuario ya existe, STOP';
  END IF;
  IF to_regclass('public.usuario') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: tabla public.usuario ya existe, STOP';
  END IF;
  IF to_regclass('public.v_usuario_publico') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: vista % ya existe, STOP', 'v_usuario_publico';
  END IF;
  IF to_regclass('public.v_reporte_ventas_cliente') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: vista % ya existe, STOP', 'v_reporte_ventas_cliente';
  END IF;
  IF to_regclass('public.v_catalogo_productos') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: vista % ya existe, STOP', 'v_catalogo_productos';
  END IF;
  IF to_regclass('public.v_detalle_pedido_producto') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: vista % ya existe, STOP', 'v_detalle_pedido_producto';
  END IF;
  IF to_regclass('public.v_pedido_cliente') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: vista % ya existe, STOP', 'v_pedido_cliente';
  END IF;
  IF to_regclass('public.mv_resumen_ventas_categoria_mes') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: materializada % ya existe, STOP', 'mv_resumen_ventas_categoria_mes';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_class WHERE relname = 'idx_mv_resumen_ventas_categoria_mes') THEN
    RAISE EXCEPTION 'conflicto: indice % ya existe, STOP', 'idx_mv_resumen_ventas_categoria_mes';
  END IF;
  IF to_regprocedure('public.fn_autenticar(varchar,varchar)') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: funcion % ya existe, STOP', 'fn_autenticar(varchar,varchar)';
  END IF;
  IF to_regprocedure('public.fn_resetear_password(bigint,varchar)') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: funcion % ya existe, STOP', 'fn_resetear_password(bigint,varchar)';
  END IF;
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname IN ('rol_app_lectura','rol_app_escritura','rol_soporte','rol_reportes','rol_auditoria','app_web','admin_datos')) THEN
    RAISE EXCEPTION 'conflicto: alguno de los roles TP7 ya existe, STOP';
  END IF;
END
$$;

-- 2. Dependencias (definiciones reales; CREATE plano, sin IF NOT EXISTS).
CREATE EXTENSION pgcrypto;
CREATE TYPE public.rol_usuario AS ENUM ('ADMIN', 'VENDEDOR', 'USUARIO');
CREATE TABLE public.usuario (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    apellido VARCHAR(80) NOT NULL,
    mail VARCHAR(120) NOT NULL UNIQUE,
    celular VARCHAR(30),
    contrasena VARCHAR(255) NOT NULL,
    rol public.rol_usuario NOT NULL DEFAULT 'USUARIO',
    eliminado BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_usuario_nombre_no_vacio CHECK (trim(nombre) <> ''),
    CONSTRAINT chk_usuario_apellido_no_vacio CHECK (trim(apellido) <> ''),
    CONSTRAINT chk_usuario_mail_no_vacio CHECK (trim(mail) <> ''),
    CONSTRAINT chk_usuario_contrasena_no_vacia CHECK (trim(contrasena) <> ''));

-- 3. Vistas verbatim vistas.sql (nombres calificados; cuerpos del repo; search_path ya fijado a public).
CREATE OR REPLACE VIEW public.v_usuario_publico AS
SELECT id, nombre, apellido, mail, celular, rol, created_at FROM public.usuario WHERE eliminado = FALSE;
CREATE OR REPLACE VIEW public.v_reporte_ventas_cliente AS
SELECT c.id AS cliente_id, c.nombre_completo, COUNT(DISTINCT p.id) AS pedidos,
  COALESCE(SUM(dp.subtotal), 0)::NUMERIC(12, 2) AS total_facturado
FROM public.cliente AS c LEFT JOIN public.pedido AS p ON p.id_cliente = c.id AND p.estado <> 'CANCELADO'
LEFT JOIN public.detalle_pedido AS dp ON dp.id_pedido = p.id GROUP BY c.id, c.nombre_completo;
CREATE OR REPLACE VIEW public.v_catalogo_productos AS
SELECT p.id AS producto_id, p.nombre AS producto, c.nombre AS categoria, p.precio_lista, p.stock
FROM public.producto AS p JOIN public.categoria AS c ON c.id = p.id_categoria
WHERE p.activo = TRUE AND c.activo = TRUE;
CREATE OR REPLACE VIEW public.v_detalle_pedido_producto AS
SELECT dp.id_pedido, dp.id_producto, pr.nombre AS producto, dp.cantidad, dp.precio_unitario, dp.subtotal
FROM public.detalle_pedido AS dp JOIN public.producto AS pr ON pr.id = dp.id_producto;
CREATE OR REPLACE VIEW public.v_pedido_cliente AS
SELECT p.id AS pedido_id, p.fecha_hora, p.forma_pago, p.estado, c.id AS cliente_id, c.nombre_completo, c.email
FROM public.pedido AS p JOIN public.cliente AS c ON c.id = p.id_cliente;

-- 4. Materializada + índice verbatim vista_materializada.sql:8-27 (sin REFRESH/SELECT demo).
CREATE MATERIALIZED VIEW public.mv_resumen_ventas_categoria_mes AS
SELECT c.id AS id_categoria, c.nombre AS categoria, date_trunc('month', p.fecha_hora) AS mes,
  COUNT(DISTINCT p.id) AS cantidad_pedidos, SUM(dp.cantidad) AS unidades_vendidas, SUM(dp.subtotal) AS facturacion_total
FROM public.pedido p JOIN public.detalle_pedido dp ON dp.id_pedido = p.id
JOIN public.producto pr ON pr.id = dp.id_producto JOIN public.categoria c ON c.id = pr.id_categoria
WHERE p.estado <> 'CANCELADO' GROUP BY c.id, c.nombre, date_trunc('month', p.fecha_hora) WITH DATA;
CREATE UNIQUE INDEX idx_mv_resumen_ventas_categoria_mes
  ON public.mv_resumen_ventas_categoria_mes (id_categoria, mes);

-- 5. Funciones canónicas corregidas vía \ir (endurecidas 2026-10-15:
-- SET search_path = pg_catalog, pg_temp, llamadas calificadas con tipos
-- explícitos, REVOKE FROM PUBLIC incluido). Las copias internas anteriores
-- (crypt/gen_salt sin calificar) se eliminan de este archivo por vulnerables;
-- la evidencia de instalación (ejecucion_20261015_0215.md) corresponde a esas
-- versiones internas del commit 0060cfd, recuperables vía git show.
-- No se afirma que las versiones corregidas hayan sido ejecutadas.
\ir fn_autenticar.sql
\ir fn_resetear_password.sql

-- 6. Permisos originales de A en esta misma transacción (sin duplicar ni modificar el archivo).
\ir roles.sql

-- 7. Neutralización de placeholders ANTES del COMMIT: los logins quedan sin contraseña
-- habilitada (el laboratorio usa SET ROLE desde la conexión administrativa).
ALTER ROLE app_web WITH PASSWORD NULL;
ALTER ROLE admin_datos WITH PASSWORD NULL;

-- 8. Sintéticos acordados (fuera de $$: aquí sí interpola :'var'; tabla recién creada y vacía).
INSERT INTO public.usuario (nombre, apellido, mail, celular, contrasena, rol, eliminado)
VALUES ('LabC', 'Incidente01', 'lab_c_incidente_01@example.invalid', '2600000001', crypt(:'lab_c_password_01', gen_salt('bf')), 'USUARIO', FALSE);
INSERT INTO public.usuario (nombre, apellido, mail, celular, contrasena, rol, eliminado)
VALUES ('LabC', 'Incidente02', 'lab_c_incidente_02@example.invalid', '2600000002', crypt(:'lab_c_password_02', gen_salt('bf')), 'VENDEDOR', FALSE);

-- 9a. Siete roles con atributos LOGIN/NOLOGIN esperados (LEFT JOIN desde los esperados).
DO $$
DECLARE v_mal INT;
BEGIN
  SELECT count(*) INTO v_mal
  FROM (VALUES
    ('rol_app_lectura', false), ('rol_app_escritura', false), ('rol_soporte', false),
    ('rol_reportes', false), ('rol_auditoria', false), ('app_web', true), ('admin_datos', true)
  ) AS e(rol, login)
  LEFT JOIN pg_roles r ON r.rolname = e.rol
  WHERE r.rolname IS NULL OR r.rolcanlogin IS DISTINCT FROM e.login;
  IF v_mal <> 0 THEN RAISE EXCEPTION 'control roles: % desajustes en 7 roles/attrs esperados', v_mal; END IF;
END
$$;

-- 9b. Dos sintéticos + bcrypt válido (solo booleano) + auth exacta + auth nula.
DO $$
DECLARE
  v_pw01 TEXT := current_setting('my.lab_pw01', true);
  v_n INT; v_b1 BOOLEAN; v_b2 BOOLEAN;
  v_id_esp BIGINT; v_auth BIGINT; v_mala BIGINT;
BEGIN
  IF v_pw01 IS NULL OR btrim(v_pw01) = '' THEN RAISE EXCEPTION 'control auth: secreto lab no recuperado'; END IF;
  SELECT count(*) INTO v_n FROM public.usuario WHERE mail IN ('lab_c_incidente_01@example.invalid','lab_c_incidente_02@example.invalid');
  IF v_n <> 2 THEN RAISE EXCEPTION 'control sintéticos: esperados 2, hallados %', v_n; END IF;
  SELECT (contrasena ~ '^[$]2[aby][$][0-9]{2}[$][./A-Za-z0-9]{53}$') INTO v_b1 FROM public.usuario WHERE mail = 'lab_c_incidente_01@example.invalid';
  SELECT (contrasena ~ '^[$]2[aby][$][0-9]{2}[$][./A-Za-z0-9]{53}$') INTO v_b2 FROM public.usuario WHERE mail = 'lab_c_incidente_02@example.invalid';
  IF NOT coalesce(v_b1, false) OR NOT coalesce(v_b2, false) THEN RAISE EXCEPTION 'control bcrypt: formato inválido (booleano false)'; END IF;
  SELECT id INTO v_id_esp FROM public.usuario WHERE mail = 'lab_c_incidente_01@example.invalid';
  v_auth := public.fn_autenticar('lab_c_incidente_01@example.invalid', v_pw01);
  IF v_auth IS DISTINCT FROM v_id_esp THEN RAISE EXCEPTION 'control auth correcta: esperado id=%, obtenido=%', v_id_esp, v_auth; END IF;
  v_mala := public.fn_autenticar('lab_c_incidente_01@example.invalid', 'incorrecta_laboratorio_00');
  IF v_mala IS NOT NULL THEN RAISE EXCEPTION 'control auth incorrecta: esperado NULL, obtenido=%', v_mala; END IF;
END
$$;

-- 9c. Lectura efectiva de columnas autorizadas como rol_soporte (sin contrasena).
DO $$
DECLARE v_n INT;
BEGIN
  SET LOCAL ROLE rol_soporte;
  SELECT count(*) INTO v_n FROM public.usuario;
  PERFORM id, nombre, apellido, mail, celular, rol, eliminado, created_at FROM public.usuario LIMIT 1;
  RESET ROLE;
  IF v_n <> 2 THEN RAISE EXCEPTION 'control lectura soporte: esperadas 2 filas, halladas %', v_n; END IF;
END
$$;

-- 9d. Acceso denegado a contrasena: solo SQLSTATE 42501. Sin depender del idioma.
SAVEPOINT sp_hash;
DO $$
DECLARE v_mail TEXT;
BEGIN
  SET LOCAL ROLE rol_soporte;
  SELECT mail INTO v_mail FROM public.usuario LIMIT 1;
  BEGIN
    PERFORM contrasena FROM public.usuario LIMIT 1;
    RAISE EXCEPTION 'control hash denegado: SELECT tuvo éxito, se esperaba SQLSTATE 42501';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLSTATE <> '42501' THEN
      RAISE EXCEPTION 'control hash denegado: SQLSTATE inesperado=% (se esperaba 42501)', SQLSTATE;
    END IF;
  END;
  RESET ROLE;
END
$$;
RELEASE SAVEPOINT sp_hash;

-- 10. Persistencia: solo después de superar TODOS los controles.
COMMIT;
-- Efecto previsto: extensión, tipo, usuario + 2 sintéticos, 5 vistas, materializada +
-- índice, 2 funciones, 7 roles con GRANTs de roles.sql, placeholders con PASSWORD NULL.
-- Las cinco tablas originales quedan intactas (solo leídas). Sin ALTER SYSTEM aquí.
