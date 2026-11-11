-- TP7 — corregir_seguridad_tp7.sql (ensayo y aplicación históricos acreditados).
-- Ensayo ROLLBACK: ../docs/evidencias/ensayo_correccion_seguridad_20261015_1117.md.
-- Aplicación COMMIT y validación posterior:
-- ../docs/evidencias/aplicacion_correccion_seguridad_20261015_1121.md.
-- Sin nueva ejecución en esta revisión documental.
-- Aplica los hallazgos de la auditoría 2026-10-15 sobre un entorno donde el
-- TP7 YA está instalado. No reinstala, no borra objetos ni datos, no toca
-- evidencias de A–D. Requiere respaldo custom fechado fuera del repo ANTES de
-- ejecutar (ver docs/aplicacion_correccion_seguridad.md).
--
-- Correcciones (todas idempotentes; re-ejecutar es un no-op):
--   §1 revoca los SELECT indiscriminados sobre pg_catalog e information_schema
--      de rol_auditoria (ya instalados). Borrar el GRANT del archivo no basta.
--   §2 reduce los privilegios por defecto de rol_app_escritura al RF-07 exacto
--      (INSERT, UPDATE; sin SELECT futuro), serie plana y FOR ROLE admin_datos.
--   §3 reutiliza los archivos canónicos (CREATE OR REPLACE) vía \ir y reafirma
--      los EXECUTE de roles.sql §8. Las copias internas de
--      preparar/instalar_entorno_local.sql se reemplazaron por \ir (las
--      evidencias anteriores corresponden a sus versiones internas del commit
--      0060cfd, recuperables vía git show). Las funciones canónicas corregidas
--      fueron aplicadas mediante este corrector (evidencia de aplicación 11:21).
--      No se acredita una nueva ejecución completa de los instaladores modificados.
-- Este script NO modifica contraseñas: la instalación local anterior ya
-- neutralizó ambos logins (evidencia de ejecución C: app_web.password_null=t,
-- admin_datos.password_null=t). roles.sql crea los logins con PASSWORD NULL
-- solo para instalaciones nuevas.
-- Selector estricto de persistencia (antes de BEGIN y de modificar objetos).
-- psql NO evalúa igualdades en \if (solo valores on/off: t/f/1/0/on/off/yes/no).
-- Las comparaciones se calculan en SQL con :'aplicar' (literal citado por psql;
-- el valor nunca se interpola en SQL dinámico) y los booleanos resultantes
-- ('t'/'f') viajan a psql con \gset, que los recalcula siempre, sobrescribiendo
-- valores previos. Si aplicar está ausente, se le asigna 0.
-- Ausente o texto exacto '0' = ensayo (ROLLBACK); únicamente texto exacto '1'
-- = aplicar (COMMIT); cualquier otro valor produce un error SQL real aquí,
-- con ON_ERROR_STOP interrumpe toda la ejecución e impide alcanzar COMMIT.
-- Modos: por defecto ENSAYO (ROLLBACK final: prueba la corrección completa sin
-- persistir). Solo con -v aplicar=1 termina con COMMIT tras los controles.
-- Ningún COMMIT ocurre antes de superar sus comprobaciones. Sin ALTER SYSTEM.
-- El corrector ejecuta las comprobaciones completas (cuerpo compartido
-- sql/comprobaciones_seguridad.sql: permisos, funciones, auth, reset, defaults)
-- dentro de su propia transacción ANTES de decidir. Los fixtures y la demo
-- viajan en un SAVEPOINT que se revierte antes del eventual COMMIT: ningún
-- usuario ni tabla de prueba persiste. Cualquier fallo impide confirmar.
-- Ejecutar como el mismo superusuario que aplicó roles.sql (normalmente
-- postgres), porque ALTER DEFAULT PRIVILEGES (serie plana) pertenece al rol
-- ejecutor. Requiere: psql -X [-v aplicar=1] -v lab_vf_password='…'
--   -v lab_vf_password_new='…' -f sql/corregir_seguridad_tp7.sql
-- (las -v son sintéticas para los fixtures de comprobación, no reales).
-- Nota psql: este archivo no usa variables (:'…') dentro de cuerpos $$.

\set ON_ERROR_STOP on

\if :{?aplicar}
\else
\set aplicar 0
\endif
SELECT :'aplicar' IN ('0', '1') AS modo_valido,
       :'aplicar' = '1' AS m_aplicar
\gset
\if :modo_valido
\else
DO $$ BEGIN RAISE EXCEPTION 'corregir_seguridad_tp7.sql: valor aplicar inválido (solo texto 0, 1 o ausente)'; END $$;
\endif

BEGIN;

SET LOCAL search_path TO public, pg_temp;

-- §0. Prerrequisitos: entorno con TP7 instalado (invertido respecto de los
-- scripts de instalación: aquí la ausencia aborta, nada se crea desde cero).
DO $$
BEGIN
  IF current_database() <> 'foodstore_dev' THEN
    RAISE EXCEPTION 'abortado: base actual=% se esperaba foodstore_dev', current_database();
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pgcrypto') THEN
    RAISE EXCEPTION 'prerrequisito ausente: extension pgcrypto, STOP';
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
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_auditoria') THEN
    RAISE EXCEPTION 'prerrequisito ausente: rol rol_auditoria, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_web') THEN
    RAISE EXCEPTION 'prerrequisito ausente: rol app_web, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_datos') THEN
    RAISE EXCEPTION 'prerrequisito ausente: rol admin_datos, STOP';
  END IF;
END
$$;

-- §0b. Los siete roles con sus atributos LOGIN/NOLOGIN esperados (LEFT JOIN
-- desde los esperados: un NOT EXISTS sobre la lista solo detectaría que no
-- existe ninguno, y un FULL JOIN contaría roles ajenos del servidor).
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

-- §1. Procedencia real de pgcrypto: se verifica la pertenencia de los OID
-- EXACTOS utilizados —public.crypt(text, text) y public.gen_salt(text)— a la
-- extensión pgcrypto mediante pg_depend, con classid/refclassid correctos
-- (pg_proc → pg_extension, deptype 'e'). Contar funciones por nombre no
-- probaría la procedencia de la firma utilizada; aquí se comprueba el OID que
-- las funciones canónicas invocan. No se afirma ausencia de sobrecargas: los
-- conteos por nombre solo se informan (NOTICE). Ante duda se aborta.
DO $$
DECLARE
  v_oid_crypt OID := to_regprocedure('public.crypt(text, text)');
  v_oid_salt  OID := to_regprocedure('public.gen_salt(text)');
  v_ext OID;
  v_n_crypt INT;
  v_n_salt  INT;
BEGIN
  IF v_oid_crypt IS NULL THEN
    RAISE EXCEPTION 'procedencia: public.crypt(text, text) no existe; esquema inesperado, STOP (no se adivina)';
  END IF;
  IF v_oid_salt IS NULL THEN
    RAISE EXCEPTION 'procedencia: public.gen_salt(text) no existe; esquema inesperado, STOP (no se adivina)';
  END IF;
  SELECT oid INTO v_ext FROM pg_extension WHERE extname = 'pgcrypto';
  IF v_ext IS NULL THEN
    RAISE EXCEPTION 'procedencia: extension pgcrypto no instalada, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_depend
                 WHERE classid = 'pg_proc'::regclass AND objid = v_oid_crypt
                   AND refclassid = 'pg_extension'::regclass
                   AND refobjid = v_ext AND deptype = 'e') THEN
    RAISE EXCEPTION 'procedencia: public.crypt(text, text) (oid=%) no pertenece a pgcrypto, STOP', v_oid_crypt;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_depend
                 WHERE classid = 'pg_proc'::regclass AND objid = v_oid_salt
                   AND refclassid = 'pg_extension'::regclass
                   AND refobjid = v_ext AND deptype = 'e') THEN
    RAISE EXCEPTION 'procedencia: public.gen_salt(text) (oid=%) no pertenece a pgcrypto, STOP', v_oid_salt;
  END IF;
  SELECT count(*) INTO v_n_crypt FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public' AND p.proname = 'crypt';
  SELECT count(*) INTO v_n_salt FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE n.nspname = 'public' AND p.proname = 'gen_salt';
  RAISE NOTICE 'procedencia verificada: crypt oid=%, gen_salt oid=% (mismo-nombre en public: crypt=%, gen_salt=%)',
    v_oid_crypt, v_oid_salt, v_n_crypt, v_n_salt;
END
$$;

-- §2. Revocación de los permisos excesivos YA INSTALADOS sobre catálogos.
REVOKE SELECT ON ALL TABLES IN SCHEMA pg_catalog FROM rol_auditoria;
REVOKE SELECT ON ALL TABLES IN SCHEMA information_schema FROM rol_auditoria;

-- §3. Privilegios por defecto al RF-07 exacto (revocar el SELECT de más y
-- reafirmar el resto para dejar el estado especificado, serie plana + D6).
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    REVOKE SELECT ON TABLES FROM rol_app_escritura;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public
    REVOKE SELECT ON TABLES FROM rol_app_escritura;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT INSERT, UPDATE ON TABLES TO rol_app_escritura;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT SELECT ON TABLES TO rol_app_lectura;
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO rol_app_escritura;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public
    GRANT INSERT, UPDATE ON TABLES TO rol_app_escritura;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public
    GRANT SELECT ON TABLES TO rol_app_lectura;
ALTER DEFAULT PRIVILEGES FOR ROLE admin_datos IN SCHEMA public
    GRANT USAGE, SELECT ON SEQUENCES TO rol_app_escritura;

-- §4. Funciones endurecidas desde los archivos canónicos (preservan firmas,
-- comportamiento, REVOKE FROM PUBLIC) + EXECUTE de roles.sql §8.
\ir fn_autenticar.sql
\ir fn_resetear_password.sql

GRANT EXECUTE ON FUNCTION public.fn_autenticar(VARCHAR, VARCHAR) TO rol_app_escritura;
GRANT EXECUTE ON FUNCTION public.fn_resetear_password(BIGINT, VARCHAR) TO rol_soporte;
GRANT EXECUTE ON FUNCTION
    public.fn_autenticar(VARCHAR, VARCHAR),
    public.fn_resetear_password(BIGINT, VARCHAR)
TO admin_datos;

-- §5. Comprobaciones completas ANTES de decidir: cuerpo compartido con el
-- validador independiente (evita duplicación). Los fixtures sintéticos y la
-- demo D11 viajan en un SAVEPOINT que se revierte antes del eventual COMMIT:
-- ningún usuario ni tabla de prueba persiste. Cualquier fallo impide confirmar.
SAVEPOINT sp_pruebas;
\ir comprobaciones_seguridad.sql
ROLLBACK TO SAVEPOINT sp_pruebas;
RELEASE SAVEPOINT sp_pruebas;

-- Cierre por el booleano calculado (nunca por mera existencia): solo 't'
-- (texto exacto '1' validado arriba) llega a COMMIT; 'f' termina en ROLLBACK.
\if :m_aplicar
-- Persistencia: solo después de superar TODAS las comprobaciones.
COMMIT;
\else
ROLLBACK; -- modo ensayo: corrección completa probada sin persistir.
\endif
-- Efecto previsto (modo aplicar): catálogos revocados a rol_auditoria
-- (conserva pg_monitor); defaults al RF-07 exacto; funciones reemplazadas
-- (cuerpos calificados) con EXECUTE de §8. Sin cambios de contraseñas.
-- Nada más cambia: sin reinstalación, sin borrado de objetos o datos,
-- sin ALTER SYSTEM.
