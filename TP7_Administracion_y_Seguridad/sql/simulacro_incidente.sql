-- TP7 Parte C — simulacro_incidente.sql (PARA REVISIÓN, NO EJECUTADO).
-- Secuencia PDF C.1: varios fn_autenticar fallidos → uno exitoso → lectura masiva
-- de usuario → intento de escalamiento (membresía en admin_datos) que debe fallar.
-- Todo con cuentas y credenciales exclusivamente SINTÉTICAS de laboratorio,
-- unificadas con preparar_entorno_local.sql: lab_c_incidente_01/02@example.invalid.
-- Este archivo NO se ejecutó todavía; no presenta resultados reales.
--
-- Prerrequisitos (NO instalados por la validación anterior: preparar_entorno_local.sql
-- terminó en ROLLBACK y revirtió todo). Antes de ejecutar se requiere, con autorización
-- separada: instalación persistente de extensión + tipo + tabla usuario + 5 vistas +
-- materializada + 2 funciones + roles vía roles.sql, más los 2 sintéticos con hashes
-- bcrypt válidos y auditoría activa. Este script NO crea esos objetos: si faltan,
-- aborta (ver §0). No incluye preparar_entorno_local.sql como si dejara objetos
-- disponibles tras su ROLLBACK.
--
-- Identidades: aplicación (fila usuario.mail + contraseña) ≠ identidad PostgreSQL
-- (rol de sesión: postgres/app_web/rol_*). fn_autenticar devuelve BIGINT o NULL y NO
-- cambia session_user/current_user. Los cambios de rol (SET LOCAL ROLE … / RESET ROLE)
-- son acciones explícitas del laboratorio y quedarán en el log.
-- Instrumentación: los RAISE LOG/NOTICE de §§1-2/4 son instrumentación del laboratorio
-- para registrar los resultados verificados. PostgreSQL NO registra automáticamente los
-- valores devueltos por fn_autenticar; sin estos mensajes, el log solo mostraría el texto
-- de las llamadas. RAISE LOG va al log del servidor; RAISE NOTICE muestra el resultado
-- al cliente. Ningún mensaje incluye contraseñas ni hashes.
-- Requiere: psql -X -v lab_sim_password_ok='…' -f simulacro_incidente.sql
-- (contraseña correcta del sintético 01; los fallidos usan literales incorrectos
-- sintéticos). -v NO evita exposición: solo sintéticas.
-- Termina en ROLLBACK. Sin COMMIT ni ALTER SYSTEM.

\set ON_ERROR_STOP on

\if :{?lab_sim_password_ok}
\else
\echo 'Falta -v lab_sim_password_ok (sintética del sintético 01, no real)'
\q 1
\endif

BEGIN;

SET LOCAL search_path TO public, pg_temp;
SET LOCAL my.sim_pw_ok TO :'lab_sim_password_ok';

-- §0. Prerrequisitos: abortar si falta algo (no crear nada aquí).
DO $$
BEGIN
  IF current_database() <> 'foodstore_dev' THEN
    RAISE EXCEPTION 'abortado: base actual=% se esperaba foodstore_dev', current_database();
  END IF;
  IF to_regprocedure('public.fn_autenticar(varchar,varchar)') IS NULL THEN
    RAISE EXCEPTION 'prerrequisito ausente: fn_autenticar, STOP (la validación anterior revirtió todo)';
  END IF;
  IF to_regclass('public.usuario') IS NULL THEN
    RAISE EXCEPTION 'prerrequisito ausente: tabla public.usuario, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'rol_soporte') THEN
    RAISE EXCEPTION 'prerrequisito ausente: rol rol_soporte, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_web') THEN
    RAISE EXCEPTION 'prerrequisito ausente: rol app_web, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'admin_datos') THEN
    RAISE EXCEPTION 'prerrequisito ausente: rol admin_datos, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.usuario WHERE mail = 'lab_c_incidente_01@example.invalid' AND eliminado = FALSE) THEN
    RAISE EXCEPTION 'prerrequisito ausente: sintético lab_c_incidente_01, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.usuario WHERE mail = 'lab_c_incidente_02@example.invalid' AND eliminado = FALSE) THEN
    RAISE EXCEPTION 'prerrequisito ausente: sintético lab_c_incidente_02, STOP';
  END IF;
END
$$;

-- Marca de inicio (con log_statement=all queda registrada como sentencia).
SELECT 'SIMULACRO_INCIDENTE_INICIO_C' AS marca, clock_timestamp() AS ts;

-- §1. Tres intentos fallidos sobre lab_c_incidente_01 (devuelven NULL; el log solo muestra
-- el texto, por eso se comprueba aquí cada valor devuelto y luego se instrumenta).
DO $$
DECLARE
  v_pw_ok TEXT := current_setting('my.sim_pw_ok', true);
  v_f1 BIGINT; v_f2 BIGINT; v_f3 BIGINT;
BEGIN
  IF v_pw_ok IS NULL OR btrim(v_pw_ok) = '' THEN RAISE EXCEPTION 'secreto lab no recuperado, STOP'; END IF;
  IF v_pw_ok IN ('incorrecta_laboratorio_01', 'incorrecta_laboratorio_02', 'incorrecta_laboratorio_03') THEN
    RAISE EXCEPTION 'la contraseña correcta coincide con una incorrecta, STOP';
  END IF;
  v_f1 := public.fn_autenticar('lab_c_incidente_01@example.invalid', 'incorrecta_laboratorio_01');
  IF v_f1 IS NOT NULL THEN RAISE EXCEPTION 'control fallido 1: se esperaba NULL, obtenido %', v_f1; END IF;
  RAISE LOG 'simulacro C auth intento 1 resultado FALLIDO';
  RAISE NOTICE 'simulacro C auth intento 1 resultado FALLIDO';
  v_f2 := public.fn_autenticar('lab_c_incidente_01@example.invalid', 'incorrecta_laboratorio_02');
  IF v_f2 IS NOT NULL THEN RAISE EXCEPTION 'control fallido 2: se esperaba NULL, obtenido %', v_f2; END IF;
  RAISE LOG 'simulacro C auth intento 2 resultado FALLIDO';
  RAISE NOTICE 'simulacro C auth intento 2 resultado FALLIDO';
  v_f3 := public.fn_autenticar('lab_c_incidente_01@example.invalid', 'incorrecta_laboratorio_03');
  IF v_f3 IS NOT NULL THEN RAISE EXCEPTION 'control fallido 3: se esperaba NULL, obtenido %', v_f3; END IF;
  RAISE LOG 'simulacro C auth intento 3 resultado FALLIDO';
  RAISE NOTICE 'simulacro C auth intento 3 resultado FALLIDO';
END
$$;

-- §2. Un inicio exitoso sobre el mismo sintético (devuelve exactamente el id;
-- la sesión PG NO cambia de rol: la identidad de aplicación no es la de PostgreSQL).
DO $$
DECLARE
  v_pw_ok TEXT := current_setting('my.sim_pw_ok', true);
  v_id_esp BIGINT; v_ok BIGINT;
BEGIN
  SELECT id INTO v_id_esp FROM public.usuario WHERE mail = 'lab_c_incidente_01@example.invalid';
  v_ok := public.fn_autenticar('lab_c_incidente_01@example.invalid', v_pw_ok);
  IF v_ok IS DISTINCT FROM v_id_esp THEN
    RAISE EXCEPTION 'control éxito: esperado id=%, obtenido=% (fn no cambia identidad PG)', v_id_esp, v_ok;
  END IF;
  RAISE LOG 'simulacro C auth intento 4 resultado EXITOSO id=%', v_ok;
  RAISE NOTICE 'simulacro C auth intento 4 resultado EXITOSO id=%', v_ok;
  -- Nota: session_user/current_user siguen siendo los de la conexión; fn solo devolvió el id.
END
$$;

-- §3. Lectura masiva de usuario con columnas permitidas a rol_soporte.
-- Todas las filas, sin LIMIT, sin contrasena. Cambios de rol explícitos.
SET LOCAL ROLE rol_soporte;
SELECT id, nombre, apellido, mail, celular, rol, eliminado, created_at
FROM public.usuario
ORDER BY id;
RESET ROLE;

-- §4. Intento de escalamiento bajo rol de bajo privilegio (app_web): otorgarse
-- membresía en admin_datos. Debe fallar con SQLSTATE 42501. Error aislado: el SET ROLE
-- va fuera del bloque interno para no confundir sus errores con el del GRANT.
-- DENEGADO solo se emite tras verificar el 42501; si el GRANT tiene éxito se aborta
-- como hallazgo y nunca se emite DENEGADO.
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
    RAISE LOG 'simulacro C escalamiento resultado DENEGADO sqlstate=% usuario=%', SQLSTATE, current_user;
    RAISE NOTICE 'simulacro C escalamiento resultado DENEGADO sqlstate=% usuario=%', SQLSTATE, current_user;
    -- Esperado: membresía denegada a app_web. Continúa al ROLLBACK final.
  END;
END
$$;
RELEASE SAVEPOINT sp_escalamiento;
RESET ROLE;

-- Marca de fin.
SELECT 'SIMULACRO_INCIDENTE_FIN_C' AS marca, clock_timestamp() AS ts;

ROLLBACK; -- cierra el laboratorio reversible; nada persiste.
-- Nota: si el escalamiento hubiera tenido éxito, el RAISE 'HALLAZGO' aborta el script
-- (ON_ERROR_STOP detiene; la conexión debe cerrarse para descartar la transacción).
-- Ese caso se informa como defecto del esquema y NUNCA se declara aprobado.
-- Sin COMMIT ni ALTER SYSTEM aquí.
