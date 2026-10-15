-- TP7 Parte C — activar_auditoria_local.sql (ejecución histórica documentada).
-- Ejecución y restauración posterior: ../docs/evidencias/ejecucion_20261015_0215.md.
-- No se volvió a ejecutar en esta revisión documental.
-- Activa la auditoría nativa necesaria para el simulacro C en foodstore_dev.
--
-- Alcance: ALTER SYSTEM escribe postgresql.auto.conf y AFECTA A TODO EL CLÚSTER
-- (todas las bases), no solo a foodstore_dev. ALTER SYSTEM no admite ejecutarse
-- dentro de un bloque de transacción (BEGIN…COMMIT): intentarlo da error.
-- Por eso este archivo NO contiene BEGIN ni COMMIT.
--
-- NO modifica logging_collector ni reinicia el servidor. Si logging_collector
-- estuviera en off, este script aborta (§0): activarlo requiere reinicio
-- (contexto postmaster) y queda fuera del alcance autorizado.
--
-- Parámetros que prepara (solo estos cuatro):
--   log_connections = on, log_disconnections = on, log_statement = all,
--   log_line_prefix = '%m [%p] %u@%d %r %a '
-- log_statement=all es necesario porque 'mod' no registra el SELECT masivo del
-- simulacro (ni los retornos, cubiertos por la instrumentación RAISE del script C).
-- Contrapartida: 'all' genera ruido y vuelca sintéticas en texto plano al log.
--
-- Uso previsto (ver docs/ejecucion_local.md): con captura previa de valores/fuentes,
-- ejecutar una vez con psql -X -f activar_auditoria_local.sql; la comprobación
-- posterior corre desde una CONEXIÓN NUEVA (ver §3 con \c + SHOW).

\set ON_ERROR_STOP on

-- §0. Guardas previas (solo lectura; abortan sin cambiar nada).
DO $$
BEGIN
  IF current_database() <> 'foodstore_dev' THEN
    RAISE EXCEPTION 'abortado: base actual=% se esperaba foodstore_dev (auditoría del laboratorio C)', current_database();
  END IF;
  IF current_setting('logging_collector') <> 'on' THEN
    RAISE EXCEPTION 'logging_collector=%: se requiere on sin reinicio; si estuviera off, STOP (reinicio fuera de alcance)', current_setting('logging_collector');
  END IF;
END
$$;

-- §1. Activación a nivel clúster (4 parámetros, sin tocar logging_collector).
ALTER SYSTEM SET log_connections = 'on';
ALTER SYSTEM SET log_disconnections = 'on';
ALTER SYSTEM SET log_statement = 'all';
ALTER SYSTEM SET log_line_prefix = '%m [%p] %u@%d %r %a ';

-- §2. Recarga sin reinicio (parámetros SIGHUP; no requiere postmaster).
SELECT pg_reload_conf() AS recarga_ok;

-- §3. Comprobación posterior DESDE UNA CONEXIÓN NUEVA.
-- \c abre una conexión nueva dentro de esta misma invocación psql, para que los
-- SHOW reflejen la configuración recargada tal como la verá el simulacro.
\c foodstore_dev
SHOW log_connections;
SHOW log_disconnections;
SHOW log_statement;
SHOW log_line_prefix;
SELECT name, setting, unit, context, source, sourcefile
FROM pg_settings
WHERE name IN ('log_connections','log_disconnections','log_statement','log_line_prefix','logging_collector')
ORDER BY name;
SELECT pg_current_logfile() AS log_activo;
-- Nota: la restauración posterior usa los valores/fuentes capturados antes (§ejecucion_local.md):
-- ALTER SYSTEM SET para los que estaban en auto.conf, ALTER SYSTEM RESET para los que
-- venían de otra fuente, siempre + pg_reload_conf(). Sin reinicio.
