-- TP7 — comprobaciones_seguridad.sql (cuerpo compartido, ejecución histórica).
-- Ejecutado dentro del ensayo, aplicación y validación independiente:
-- ../docs/evidencias/ensayo_correccion_seguridad_20261015_1117.md y
-- ../docs/evidencias/aplicacion_correccion_seguridad_20261015_1121.md.
-- No se ejecutó nuevamente en esta revisión documental.
-- Comprobaciones completas de la corrección de auditoría 2026-10-15, usadas
-- por sql/corregir_seguridad_tp7.sql (dentro de su transacción, antes de
-- decidir COMMIT/ROLLBACK) y por sql/validar_correccion_seguridad.sql
-- (transacción propia que termina en ROLLBACK).
-- Este archivo NO abre ni cierra la transacción exterior: sin BEGIN, COMMIT
-- ni ROLLBACK. Tampoco crea SAVEPOINT exteriores (el corrector aísla los
-- fixtures con su propio SAVEPOINT y los revierte antes del eventual COMMIT).
-- Requiere -v lab_vf_password / lab_vf_password_new (sintéticas, no reales).
-- Prohibido consultar o mostrar pg_authid, contraseñas o hashes.
-- Las denegaciones usan WHERE FALSE (sin obtener filas sensibles aunque
-- existiera un fallo); solo SQLSTATE 42501 se acepta, el resto se propaga.
-- Nota psql: este archivo no usa variables (:'…') dentro de cuerpos $$.
-- Activa ON_ERROR_STOP también aquí: un error SQL explícito interrumpe TODA la
-- ejecución (incluido el archivo padre que lo incluye vía \ir) e impide
-- alcanzar COMMIT. No se usa \q: dentro de un archivo incluido puede devolver
-- el control al padre en lugar de garantizar la salida con error.

\set ON_ERROR_STOP on

-- Guardas por error SQL explícito (nunca \q): en la rama de ausencia de cada
-- variable se ejecuta directamente un DO con RAISE EXCEPTION; con ON_ERROR_STOP
-- el fallo interrumpe TODA la ejecución (incluido el padre vía \ir) e impide
-- alcanzar COMMIT.
\if :{?lab_vf_password}
\else
DO $$ BEGIN RAISE EXCEPTION 'Falta -v lab_vf_password (sintética, no real), STOP'; END $$;
\endif
\if :{?lab_vf_password_new}
\else
DO $$ BEGIN RAISE EXCEPTION 'Falta -v lab_vf_password_new (sintética, no real), STOP'; END $$;
\endif

SET LOCAL search_path TO public, pg_temp;
SET LOCAL my.lab_vf_pw TO :'lab_vf_password';
SET LOCAL my.lab_vf_pw_new TO :'lab_vf_password_new';

-- §0. Prerrequisitos (objetos del TP7 instalado; la ausencia aborta).
DO $$
BEGIN
  IF current_database() <> 'foodstore_dev' THEN
    RAISE EXCEPTION 'abortado: base actual=% se esperaba foodstore_dev', current_database();
  END IF;
  IF to_regclass('public.usuario') IS NULL THEN
    RAISE EXCEPTION 'prerrequisito ausente: tabla public.usuario, STOP';
  END IF;
  IF to_regprocedure('public.fn_autenticar(varchar,varchar)') IS NULL THEN
    RAISE EXCEPTION 'prerrequisito ausente: fn_autenticar(varchar,varchar), STOP';
  END IF;
  IF to_regprocedure('public.fn_resetear_password(bigint,varchar)') IS NULL THEN
    RAISE EXCEPTION 'prerrequisito ausente: fn_resetear_password(bigint,varchar), STOP';
  END IF;
END
$$;

-- §0b. Los siete roles con sus atributos LOGIN/NOLOGIN esperados (un NOT EXISTS
-- sobre la lista solo detectaría que no existe ninguno; el LEFT JOIN exige
-- cada rol con su atributo).
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
  IF v_mal <> 0 THEN RAISE EXCEPTION 'prerrequisito: % desajustes en 7 roles/attrs esperados, STOP', v_mal; END IF;
END
$$;

-- §1. Controles booleanos de catálogos sensibles (sin extraer secretos).
DO $$
BEGIN
  IF NOT pg_has_role('rol_auditoria', 'pg_monitor', 'MEMBER') THEN
    RAISE EXCEPTION 'control monitoreo: rol_auditoria sin membresia pg_monitor';
  END IF;
  IF has_table_privilege('rol_auditoria', 'pg_catalog.pg_authid', 'SELECT') THEN
    RAISE EXCEPTION 'HALLAZGO: rol_auditoria aun puede leer pg_authid';
  END IF;
  IF has_table_privilege('rol_auditoria', 'pg_catalog.pg_shadow', 'SELECT') THEN
    RAISE EXCEPTION 'HALLAZGO: rol_auditoria aun puede leer pg_shadow';
  END IF;
  RAISE NOTICE 'control catalogos: pg_monitor sí; pg_authid/pg_shadow denegados';
END
$$;

-- §2. Monitoreo permitido + secreto denegado como rol_auditoria.
SET LOCAL ROLE rol_auditoria;
SELECT count(*) AS pg_stat_activity_filas FROM pg_stat_activity;
RESET ROLE;

SAVEPOINT sp_authid;
DO $$
BEGIN
  SET LOCAL ROLE rol_auditoria;
  BEGIN
    PERFORM rolname FROM pg_catalog.pg_authid WHERE FALSE;
    RAISE EXCEPTION 'HALLAZGO: lectura de pg_authid tuvo éxito, se esperaba SQLSTATE 42501';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLSTATE <> '42501' THEN
      RAISE EXCEPTION 'catalogos: SQLSTATE inesperado=% (se esperaba 42501)', SQLSTATE;
    END IF;
    RAISE NOTICE 'control pg_authid: DENEGADO sqlstate=% usuario=%', SQLSTATE, current_user;
  END;
  RESET ROLE;
END
$$;
RELEASE SAVEPOINT sp_authid;

-- §3. Soporte preservado: lectura de columnas permitidas (conteo) + hash denegado.
SET LOCAL ROLE rol_soporte;
SELECT count(*) AS usuario_filas FROM public.usuario;
RESET ROLE;

SAVEPOINT sp_hash;
DO $$
BEGIN
  SET LOCAL ROLE rol_soporte;
  BEGIN
    PERFORM contrasena FROM public.usuario WHERE FALSE;
    RAISE EXCEPTION 'HALLAZGO: lectura de contrasena tuvo éxito, se esperaba SQLSTATE 42501';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLSTATE <> '42501' THEN
      RAISE EXCEPTION 'soporte: SQLSTATE inesperado=% (se esperaba 42501)', SQLSTATE;
    END IF;
    RAISE NOTICE 'control contrasena: DENEGADO sqlstate=% usuario=%', SQLSTATE, current_user;
  END;
  RESET ROLE;
END
$$;
RELEASE SAVEPOINT sp_hash;

-- §4. Fixtures sintéticos NUEVOS con IDs explícitos (no consumen secuencias:
-- ROLLBACK no revierte nextval, por eso no se usa el default). Si el esquema
-- exige GENERATED ALWAYS, el INSERT lleva OVERRIDING SYSTEM VALUE.
-- Conflictos de IDs y correos: aborta si existen. No modifica usuarios
-- existentes. Sin mostrar hashes.
DO $$
DECLARE
  v_pw TEXT := current_setting('my.lab_vf_pw', true);
  v_pw_new TEXT := current_setting('my.lab_vf_pw_new', true);
BEGIN
  IF EXISTS (SELECT 1 FROM public.usuario WHERE id IN (900001, 900002)
             OR mail IN ('lab_vf_valido_01@example.invalid','lab_vf_eliminado_01@example.invalid')) THEN
    RAISE EXCEPTION 'conflicto: IDs o mails de fixture ya existen, STOP (no reutilizar en silencio)';
  END IF;
  IF v_pw IS NULL OR v_pw_new IS NULL
     OR pg_catalog.char_length(v_pw) < 12 OR pg_catalog.char_length(v_pw_new) < 12 THEN
    RAISE EXCEPTION 'passwords sintéticas insuficientes (mínimo 12), STOP';
  END IF;
  IF v_pw = v_pw_new THEN
    RAISE EXCEPTION 'passwords sintéticas deben ser distintas entre sí, STOP';
  END IF;
  IF v_pw = 'incorrecta_laboratorio_99' OR v_pw_new = 'incorrecta_laboratorio_99' THEN
    RAISE EXCEPTION 'password sintética coincide con la incorrecta de prueba, STOP';
  END IF;
END
$$;

INSERT INTO public.usuario (id, nombre, apellido, mail, celular, contrasena, rol, eliminado)
OVERRIDING SYSTEM VALUE
VALUES (900001, 'LabVF', 'Valido01', 'lab_vf_valido_01@example.invalid', '2600000091',
        public.crypt(:'lab_vf_password', public.gen_salt('bf'::text)), 'USUARIO', FALSE);
INSERT INTO public.usuario (id, nombre, apellido, mail, celular, contrasena, rol, eliminado)
OVERRIDING SYSTEM VALUE
VALUES (900002, 'LabVF', 'Eliminado01', 'lab_vf_eliminado_01@example.invalid', '2600000092',
        public.crypt(:'lab_vf_password', public.gen_salt('bf'::text)), 'USUARIO', TRUE);

-- El id del fixture se publica vía GUC (app_web no tiene SELECT sobre
-- usuario y no se le otorga aquí; el lookup corre con el rol de la sesión).
SELECT id AS vf_id FROM public.usuario WHERE mail = 'lab_vf_valido_01@example.invalid' \gset
SET LOCAL my.lab_vf_id TO :'vf_id';

-- §4a. Auth como app_web: válida = id exacto; incorrecta = NULL; eliminado = NULL.
SET LOCAL ROLE app_web;
DO $$
DECLARE
  v_pw TEXT := current_setting('my.lab_vf_pw', true);
  v_id_esp BIGINT := current_setting('my.lab_vf_id', true)::BIGINT;
  v_auth BIGINT;
BEGIN
  IF v_id_esp IS NULL THEN RAISE EXCEPTION 'fixture sin id, STOP'; END IF;
  v_auth := public.fn_autenticar('lab_vf_valido_01@example.invalid', v_pw);
  IF v_auth IS DISTINCT FROM v_id_esp THEN
    RAISE EXCEPTION 'auth válida: esperado id=%, obtenido=%', v_id_esp, v_auth;
  END IF;
  v_auth := public.fn_autenticar('lab_vf_valido_01@example.invalid', 'incorrecta_laboratorio_99');
  IF v_auth IS NOT NULL THEN
    RAISE EXCEPTION 'auth incorrecta: esperado NULL, obtenido=%', v_auth;
  END IF;
  v_auth := public.fn_autenticar('lab_vf_eliminado_01@example.invalid', v_pw);
  IF v_auth IS NOT NULL THEN
    RAISE EXCEPTION 'auth eliminado: esperado NULL, obtenido=%', v_auth;
  END IF;
  RAISE NOTICE 'auth: válida=id exacto, incorrecta=NULL, eliminado=NULL';
END
$$;
RESET ROLE;

-- §4b. Reseteo como rol_soporte: válido = TRUE; inválidos = FALSE.
-- IS DISTINCT FROM rechaza también NULL (un IF NOT pasaría un NULL en silencio).
SET LOCAL ROLE rol_soporte;
DO $$
DECLARE
  v_pw_new TEXT := current_setting('my.lab_vf_pw_new', true);
  v_id_esp BIGINT := current_setting('my.lab_vf_id', true)::BIGINT;
BEGIN
  IF v_id_esp IS NULL THEN RAISE EXCEPTION 'fixture sin id, STOP'; END IF;
  IF public.fn_resetear_password(v_id_esp, v_pw_new) IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'reset válido: se esperaba TRUE (incluido no-NULL)';
  END IF;
  IF public.fn_resetear_password(NULL::BIGINT, 'x') IS DISTINCT FROM FALSE THEN
    RAISE EXCEPTION 'reset nulo: se esperaba FALSE (incluido no-NULL)';
  END IF;
  IF public.fn_resetear_password(v_id_esp, 'corta') IS DISTINCT FROM FALSE THEN
    RAISE EXCEPTION 'reset corto: se esperaba FALSE (incluido no-NULL)';
  END IF;
  RAISE NOTICE 'reseteo: válido=TRUE, inválidos=FALSE';
END
$$;
RESET ROLE;

-- §4c. Re-auth como app_web (rol_soporte no tiene EXECUTE sobre fn_autenticar
-- por matriz 4.5; no se le otorga aquí): la nueva autentica con id exacto y
-- la anterior deja de autenticar.
SET LOCAL ROLE app_web;
DO $$
DECLARE
  v_pw TEXT := current_setting('my.lab_vf_pw', true);
  v_pw_new TEXT := current_setting('my.lab_vf_pw_new', true);
  v_id_esp BIGINT := current_setting('my.lab_vf_id', true)::BIGINT;
  v_auth BIGINT;
BEGIN
  IF v_id_esp IS NULL THEN RAISE EXCEPTION 'fixture sin id, STOP'; END IF;
  v_auth := public.fn_autenticar('lab_vf_valido_01@example.invalid', v_pw_new);
  IF v_auth IS DISTINCT FROM v_id_esp THEN
    RAISE EXCEPTION 're-auth tras reset: esperado id=%, obtenido=%', v_id_esp, v_auth;
  END IF;
  v_auth := public.fn_autenticar('lab_vf_valido_01@example.invalid', v_pw);
  IF v_auth IS NOT NULL THEN
    RAISE EXCEPTION 'password anterior: se esperaba NULL tras el reset, obtenido=%', v_auth;
  END IF;
  RAISE NOTICE 're-auth: nueva=id exacto, anterior=NULL';
END
$$;
RESET ROLE;

-- §5. Bloqueo de escalamiento preservado: app_web no se otorga admin_datos.
SET LOCAL ROLE app_web;
SAVEPOINT sp_escalamiento;
DO $$
BEGIN
  BEGIN
    EXECUTE 'GRANT admin_datos TO app_web';
    RAISE EXCEPTION 'HALLAZGO: el escalamiento tuvo éxito; esquema defectuoso, detener y revertir (no aprobado)';
  EXCEPTION WHEN insufficient_privilege THEN
    IF SQLSTATE <> '42501' THEN
      RAISE EXCEPTION 'escalamiento: SQLSTATE inesperado=% (se esperaba 42501)', SQLSTATE;
    END IF;
    RAISE NOTICE 'control escalamiento: DENEGADO sqlstate=% usuario=%', SQLSTATE, current_user;
  END;
END
$$;
RELEASE SAVEPOINT sp_escalamiento;
RESET ROLE;

-- §6. Funciones endurecidas: SECURITY DEFINER + proconfig exacto
-- (search_path cerrado). La cadena en prosrc es solo señal suplementaria:
-- el veredicto se basa en prosecdef y proconfig, no en grep de código.
DO $$
DECLARE
  v_src TEXT;
  v_def BOOLEAN;
  v_cfg TEXT[];
BEGIN
  SELECT prosecdef, proconfig, prosrc INTO v_def, v_cfg, v_src FROM pg_proc
   WHERE oid = to_regprocedure('public.fn_autenticar(varchar,varchar)');
  IF NOT v_def THEN RAISE EXCEPTION 'control funciones: fn_autenticar sin SECURITY DEFINER'; END IF;
  IF v_cfg IS DISTINCT FROM ARRAY['search_path=pg_catalog, pg_temp'] THEN
    RAISE EXCEPTION 'control funciones: fn_autenticar con proconfig inesperado=%', v_cfg;
  END IF;
  IF position('public.crypt(' IN v_src) = 0 THEN
    RAISE EXCEPTION 'control funciones: fn_autenticar sin llamada calificada public.crypt(';
  END IF;
  SELECT prosecdef, proconfig, prosrc INTO v_def, v_cfg, v_src FROM pg_proc
   WHERE oid = to_regprocedure('public.fn_resetear_password(bigint,varchar)');
  IF NOT v_def THEN RAISE EXCEPTION 'control funciones: fn_resetear_password sin SECURITY DEFINER'; END IF;
  IF v_cfg IS DISTINCT FROM ARRAY['search_path=pg_catalog, pg_temp'] THEN
    RAISE EXCEPTION 'control funciones: fn_resetear_password con proconfig inesperado=%', v_cfg;
  END IF;
  IF position('public.gen_salt(' IN v_src) = 0 THEN
    RAISE EXCEPTION 'control funciones: fn_resetear_password sin llamada calificada public.gen_salt(';
  END IF;
  RAISE NOTICE 'control funciones: DEFINER + proconfig cerrado + llamadas calificadas';
END
$$;

-- §7. Contrato D11 (demostración reversible): una tabla sensible futura debe
-- nacer y despojarse en la MISMA transacción, antes del COMMIT. PostgreSQL no
-- detecta qué tabla es sensible: la declara el humano que la crea.
-- Se ejecuta como el superusuario que aplicó roles.sql (misma hipótesis que
-- la corrección); si los defaults no aplican, se aborta con mensaje claro.
CREATE TABLE public.tmp_sensible_demo (id BIGINT PRIMARY KEY, dato TEXT);
DO $$
BEGIN
  IF NOT has_table_privilege('rol_app_escritura', 'public.tmp_sensible_demo', 'INSERT') THEN
    RAISE EXCEPTION 'D11 demo: el default RF-07 no heredó escritura (¿otro rol ejecutor?), STOP';
  END IF;
  IF NOT has_table_privilege('rol_app_lectura', 'public.tmp_sensible_demo', 'SELECT') THEN
    RAISE EXCEPTION 'D11 demo: el default RF-07 no heredó lectura, STOP';
  END IF;
END
$$;
-- Excepción sensible en la misma transacción, antes de cualquier COMMIT:
-- sin lectura ni escritura para nadie (ni secuencias: esta tabla no genera).
REVOKE ALL ON TABLE public.tmp_sensible_demo FROM rol_app_lectura, rol_app_escritura;
DO $$
BEGIN
  IF has_table_privilege('rol_app_escritura', 'public.tmp_sensible_demo', 'INSERT')
     OR has_table_privilege('rol_app_lectura', 'public.tmp_sensible_demo', 'SELECT') THEN
    RAISE EXCEPTION 'D11 demo: la excepción sensible no quedó aplicada, STOP';
  END IF;
  RAISE NOTICE 'D11 demo: herencia verificada y excepción aplicada en la misma transacción';
END
$$;
