-- TP7 C/D — preparar_entorno_local.sql (VALIDACIÓN REVERSIBLE, no instala).
-- No modifica A/B, TP5 ni BITACORA.md. Sin COMMIT ni ALTER SYSTEM. Termina en ROLLBACK.
-- Requiere: psql -v lab_c_password_01='…' -v lab_c_password_02='…' -f preparar_entorno_local.sql
-- Advertencia: -v NO evita exposición en historial shell, ps ni log del servidor
-- (log_statement=all registra el texto). Solo sintéticas de laboratorio.
-- \ir roles.sql se incluye sin modificarlo; sus efectos quedan en esta transacción y se revierten.
-- Definiciones verbatim de: usuarios.sql:7/13-27, vistas.sql:4-71,
-- vista_materializada.sql:8-27, fn_autenticar.sql:37-68, fn_resetear_password.sql:38-66.

\set ON_ERROR_STOP on

\if :{?lab_c_password_01}
\else
\echo 'Falta -v lab_c_password_01 (sintética, no real)'
\q 1
\endif
\if :{?lab_c_password_02}
\else
\echo 'Falta -v lab_c_password_02 (sintética, no real)'
\q 1
\endif

BEGIN;

-- Contexto de esquema explícito + transferencia transaccional de secretos (fuera de $$).
SET LOCAL search_path TO public, pg_temp;
SET LOCAL my.lab_pw01 TO :'lab_c_password_01';
SET LOCAL my.lab_pw02 TO :'lab_c_password_02';

-- 1. Abort-on-existence (vacío inicial; cualquier existencia => STOP).
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

-- 5. Funciones verbatim fn_*.sql (solo se calificó el FROM a public.usuario; lógica idéntica).
CREATE OR REPLACE FUNCTION public.fn_autenticar(p_email VARCHAR, p_password VARCHAR)
RETURNS BIGINT LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $func$ DECLARE v_id BIGINT;
BEGIN
  IF p_email IS NULL OR p_password IS NULL OR btrim(p_email) = '' OR btrim(p_password) = '' THEN RETURN NULL; END IF;
  SELECT u.id INTO v_id FROM public.usuario AS u
  WHERE u.mail = btrim(p_email) AND u.eliminado = FALSE AND u.contrasena = crypt(p_password, u.contrasena) LIMIT 1;
  IF FOUND THEN RETURN v_id; END IF; RETURN NULL;
END; $func$;
REVOKE ALL ON FUNCTION public.fn_autenticar(VARCHAR, VARCHAR) FROM PUBLIC;
CREATE OR REPLACE FUNCTION public.fn_resetear_password(p_id_usuario BIGINT, p_nueva_password VARCHAR)
RETURNS BOOLEAN LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, pg_temp
AS $func$ DECLARE v_actualizadas INTEGER;
BEGIN
  IF p_id_usuario IS NULL OR p_nueva_password IS NULL OR char_length(btrim(p_nueva_password)) < 8 THEN RETURN FALSE; END IF;
  UPDATE public.usuario AS u SET contrasena = crypt(btrim(p_nueva_password), gen_salt('bf'))
  WHERE u.id = p_id_usuario AND u.eliminado = FALSE;
  GET DIAGNOSTICS v_actualizadas = ROW_COUNT; RETURN (v_actualizadas = 1);
END; $func$;
REVOKE ALL ON FUNCTION public.fn_resetear_password(BIGINT, VARCHAR) FROM PUBLIC;

-- 6. Permisos originales de A en esta misma transacción (sin duplicar ni modificar el archivo).
\ir roles.sql

-- 7. Neutralización de placeholders en validación reversible (futura instalación: rotar a Vault de inmediato).
ALTER ROLE app_web VALID UNTIL '1970-01-01 00:00:00+00';
ALTER ROLE admin_datos VALID UNTIL '1970-01-01 00:00:00+00';

-- 8. Sintéticos C (fuera de $$: aquí sí interpola :'var'; tabla recién creada y vacía).
INSERT INTO public.usuario (nombre, apellido, mail, celular, contrasena, rol, eliminado)
VALUES ('LabC', 'Incidente01', 'lab_c_incidente_01@example.invalid', '2600000001', crypt(:'lab_c_password_01', gen_salt('bf')), 'USUARIO', FALSE);
INSERT INTO public.usuario (nombre, apellido, mail, celular, contrasena, rol, eliminado)
VALUES ('LabC', 'Incidente02', 'lab_c_incidente_02@example.invalid', '2600000002', crypt(:'lab_c_password_02', gen_salt('bf')), 'VENDEDOR', FALSE);

-- 9a. Siete roles con atributos LOGIN/NOLOGIN esperados (LEFT JOIN desde los esperados; otros roles del servidor no cuentan).
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

-- 9c. Lectura efectiva de columnas autorizadas como rol_soporte (sin contrasena, sin mostrar valores).
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

-- 9d. Acceso denegado a contrasena: solo SQLSTATE 42501; éxito u otro error => fallo. Sin depender del idioma.
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

ROLLBACK;
-- Futuro (no ejecutado): respaldo custom fechado fuera del repo + captura pg_settings de auditoría;
-- con autorización separada, ALTER SYSTEM de logs + pg_reload_conf(). Sin ALTER SYSTEM ni COMMIT aquí.
