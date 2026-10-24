\set ON_ERROR_STOP on
\pset pager off
DO $$ BEGIN IF current_database() <> 'foodstore_restore_test' THEN RAISE EXCEPTION 'Destino incorrecto: %', current_database(); END IF; END $$;
SET lock_timeout = '5s';
SET statement_timeout = '60s';
SELECT current_database() AS base, current_timestamp AS inicio;
SELECT c.relname,c.reltuples,(SELECT count(*) FROM pg_stats s WHERE s.schemaname=n.nspname AND s.tablename=c.relname) AS columnas_con_estadisticas FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname IN ('categoria','usuario','mv_resumen_ventas_categoria_mes') ORDER BY c.relname;
SELECT (SELECT count(*) FROM public.categoria) AS categoria,(SELECT count(*) FROM public.usuario) AS usuario,(SELECT count(*) FROM public.mv_resumen_ventas_categoria_mes) AS vista_materializada \gset antes_
\echo Conteos previos: categoria=:antes_categoria usuario=:antes_usuario vista_materializada=:antes_vista_materializada
ANALYZE VERBOSE public.categoria, public.usuario, public.mv_resumen_ventas_categoria_mes;
SELECT (SELECT count(*) FROM public.categoria)=:antes_categoria AND (SELECT count(*) FROM public.usuario)=:antes_usuario AND (SELECT count(*) FROM public.mv_resumen_ventas_categoria_mes)=:antes_vista_materializada AS conteos_sin_cambios \gset
\if :conteos_sin_cambios
\echo VALIDACION: conteos exactos preservados.
\else
\echo ERROR: conteos distintos.
\quit 3
\endif
SELECT c.relname,c.reltuples,(SELECT count(*) FROM pg_stats s WHERE s.schemaname=n.nspname AND s.tablename=c.relname) AS columnas_con_estadisticas FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname='public' AND c.relname IN ('categoria','usuario','mv_resumen_ventas_categoria_mes') ORDER BY c.relname;
SELECT current_database() AS base, current_timestamp AS fin;
