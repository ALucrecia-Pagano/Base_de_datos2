\set ON_ERROR_STOP on
\pset pager off
\pset null '(NULL)'
BEGIN TRANSACTION READ ONLY;
SELECT current_database() AS base, current_timestamp AS fecha, version() AS motor;
SELECT current_database() AS base, pg_database_size(current_database()) AS bytes, pg_size_pretty(pg_database_size(current_database())) AS tamano;
SELECT datname, numbackends, xact_commit, xact_rollback, blks_read, blks_hit, tup_returned, tup_fetched, tup_inserted, tup_updated, tup_deleted, deadlocks, stats_reset FROM pg_stat_database WHERE datname = current_database();
SELECT state, count(*) AS conexiones FROM pg_stat_activity WHERE datname = current_database() GROUP BY state ORDER BY state NULLS LAST;
-- Las tuplas de pg_stat_user_tables son estimaciones, no COUNT(*) exactos.
SELECT schemaname, relname, n_live_tup, n_dead_tup, n_mod_since_analyze, last_vacuum, last_autovacuum, last_analyze, last_autoanalyze, vacuum_count, autovacuum_count, analyze_count, autoanalyze_count FROM pg_stat_user_tables ORDER BY schemaname, relname;
SELECT schemaname, relname, pg_size_pretty(pg_total_relation_size(relid)) AS tamano_total, pg_total_relation_size(relid) AS bytes FROM pg_stat_user_tables ORDER BY pg_total_relation_size(relid) DESC;
-- Se omite texto SQL de otras sesiones para no guardar datos o secretos.
SELECT pid, usename, application_name, state, clock_timestamp()-query_start AS duracion, wait_event_type, wait_event FROM pg_stat_activity WHERE datname=current_database() AND state='active' AND pid <> pg_backend_pid() ORDER BY query_start;
SELECT name, setting, unit, source FROM pg_settings WHERE name IN ('autovacuum', 'track_counts', 'autovacuum_analyze_threshold', 'autovacuum_analyze_scale_factor', 'autovacuum_vacuum_threshold', 'autovacuum_vacuum_scale_factor', 'autovacuum_naptime', 'autovacuum_max_workers') ORDER BY name;
SELECT n.nspname AS esquema, c.relname AS tabla, c.reloptions AS opciones_particulares FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE c.relkind IN ('r','p') AND n.nspname NOT IN ('pg_catalog','information_schema') ORDER BY 1,2;
ROLLBACK;
