-- TP7-D: ejecutado una vez el 2026-10-17 con ROLLBACK. Evidencia: ../docs/evidencias/usuario_anon_cobertura_20261017_233704.md
-- Autonomo: no incluye usuario_anon.sql. Solo publica agregados, nunca credenciales.
\set ON_ERROR_STOP on
BEGIN ISOLATION LEVEL REPEATABLE READ;
SET LOCAL search_path TO pg_catalog, pg_temp;
SET LOCAL TIME ZONE 'America/Argentina/Buenos_Aires';

DO $$
BEGIN
  IF current_database() <> 'foodstore_dev' THEN
    RAISE EXCEPTION 'STOP: destino distinto de foodstore_dev';
  END IF;
  IF to_regclass('public.usuario') IS NULL THEN
    RAISE EXCEPTION 'STOP: falta public.usuario';
  END IF;
  IF to_regclass('public.usuario_anon_cobertura_tp7') IS NOT NULL
     OR to_regtype('public.usuario_anon_cobertura_tp7') IS NOT NULL
     OR to_regclass('pg_temp.tp7_d_fixtures') IS NOT NULL THEN
    RAISE EXCEPTION 'STOP: nombre de ensayo ocupado';
  END IF;
  IF EXISTS (SELECT FROM pg_event_trigger WHERE evtenabled <> 'D') THEN
    RAISE EXCEPTION 'STOP: revisar event triggers antes de cualquier DDL';
  END IF;
END $$;

-- Impide escrituras concurrentes durante el ensayo; no bloquea lecturas normales.
LOCK TABLE public.usuario IN SHARE ROW EXCLUSIVE MODE;
DO $$
BEGIN
  IF EXISTS (SELECT FROM pg_class WHERE oid = 'public.usuario'::regclass
             AND (relkind <> 'r' OR relrowsecurity OR relispartition))
     OR EXISTS (SELECT FROM pg_inherits WHERE inhparent = 'public.usuario'::regclass
                 OR inhrelid = 'public.usuario'::regclass)
     OR EXISTS (SELECT FROM pg_trigger WHERE tgrelid = 'public.usuario'::regclass
                 AND NOT tgisinternal AND tgenabled <> 'D')
     OR EXISTS (SELECT FROM pg_rewrite WHERE ev_class = 'public.usuario'::regclass) THEN
    RAISE EXCEPTION 'STOP: tabla, politicas, triggers o reglas requieren revision';
  END IF;
  IF (SELECT count(*) FROM pg_attribute WHERE attrelid = 'public.usuario'::regclass
        AND attnum > 0 AND NOT attisdropped) <> 9
     OR NOT EXISTS (SELECT FROM pg_attribute WHERE attrelid = 'public.usuario'::regclass
          AND attname = 'id' AND atttypid = 'bigint'::regtype AND attidentity = 'a')
     OR NOT EXISTS (SELECT FROM pg_attribute WHERE attrelid = 'public.usuario'::regclass
          AND attname = 'contrasena' AND atttypid = 'varchar'::regtype
          AND atttypmod = 259 AND attnotnull) THEN
    RAISE EXCEPTION 'STOP: esquema no coincide con usuario documentado';
  END IF;
  IF EXISTS (SELECT FROM public.usuario
              WHERE id BETWEEN -770706 AND -770701
                 OR mail IN (SELECT 'lab_d_cobertura_' || n || '@example.invalid'
                             FROM generate_series(1,6) AS n)) THEN
    RAISE EXCEPTION 'STOP: ID o correo de fixture ocupado';
  END IF;
END $$;

CREATE TEMP TABLE tp7_d_fixtures (
  id bigint PRIMARY KEY, nombre varchar(80), apellido varchar(80), mail varchar(120),
  celular varchar(30), contrasena varchar(255), rol public.rol_usuario,
  eliminado boolean, created_at timestamptz
) ON COMMIT DROP;
-- Suprimir cualquier ACL heredada, antes de poblar las tablas de ensayo.
DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT DISTINCT a.grantee FROM pg_class c,
    LATERAL aclexplode(c.relacl) a WHERE c.oid = 'pg_temp.tp7_d_fixtures'::regclass
      AND a.grantee <> c.relowner
  LOOP
    EXECUTE format('REVOKE ALL ON TABLE pg_temp.tp7_d_fixtures FROM %s',
      CASE WHEN r.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(r.grantee)) END);
  END LOOP;
END $$;

-- Marcador bloqueado: no es una clave ni un hash; ver justificacion en el plan.
INSERT INTO pg_temp.tp7_d_fixtures
SELECT -770700-n, 'LabD-Cobertura', 'Fixture-' || n,
       'lab_d_cobertura_' || n || '@example.invalid', NULL,
       '!TP7_D_COBERTURA_SIN_LOGIN!', rol::public.rol_usuario, eliminado, fecha
FROM (VALUES
 (1,'ADMIN',FALSE,TIMESTAMPTZ '2026-01-10 12:00:00-03'),
 (2,'ADMIN',TRUE, TIMESTAMPTZ '2026-01-20 12:00:00-03'),
 (3,'VENDEDOR',FALSE,TIMESTAMPTZ '2026-02-10 12:00:00-03'),
 (4,'VENDEDOR',FALSE,TIMESTAMPTZ '2026-02-20 12:00:00-03'),
 (5,'USUARIO',FALSE,TIMESTAMPTZ '2026-03-10 12:00:00-03'),
 (6,'USUARIO',TRUE, TIMESTAMPTZ '2026-03-20 12:00:00-03')
) AS f(n,rol,eliminado,fecha);

INSERT INTO public.usuario
  (id,nombre,apellido,mail,celular,contrasena,rol,eliminado,created_at)
OVERRIDING SYSTEM VALUE
SELECT id,nombre,apellido,mail,celular,contrasena,rol,eliminado,created_at
FROM pg_temp.tp7_d_fixtures;

-- CTAS sin filas ni identity: no crea ni consume secuencias para la copia.
CREATE TABLE public.usuario_anon_cobertura_tp7 AS
SELECT ('LabD-Anon-' || u.id)::varchar(80) AS nombre_lab,
       ('lab_d_anon_' || u.id || '@example.invalid')::varchar(120) AS mail_lab,
       u.rol, u.eliminado, date_trunc('month',u.created_at)::date AS mes_alta
FROM public.usuario u WITH NO DATA;
DO $$ DECLARE r record; BEGIN
  FOR r IN SELECT DISTINCT a.grantee FROM pg_class c,
    LATERAL aclexplode(c.relacl) a
    WHERE c.oid = 'public.usuario_anon_cobertura_tp7'::regclass AND a.grantee <> c.relowner
  LOOP
    EXECUTE format('REVOKE ALL ON TABLE public.usuario_anon_cobertura_tp7 FROM %s',
      CASE WHEN r.grantee = 0 THEN 'PUBLIC' ELSE quote_ident(pg_get_userbyid(r.grantee)) END);
  END LOOP;
END $$;
INSERT INTO public.usuario_anon_cobertura_tp7
SELECT ('LabD-Anon-' || u.id), ('lab_d_anon_' || u.id || '@example.invalid'),
       u.rol,u.eliminado,date_trunc('month',u.created_at)::date
FROM public.usuario u ORDER BY u.id;

DO $$
BEGIN
  IF EXISTS (
    (SELECT * FROM pg_temp.tp7_d_fixtures EXCEPT ALL
     SELECT id,nombre,apellido,mail,celular,contrasena,rol,eliminado,created_at
     FROM public.usuario WHERE id BETWEEN -770706 AND -770701)
    UNION ALL
    (SELECT id,nombre,apellido,mail,celular,contrasena,rol,eliminado,created_at
     FROM public.usuario WHERE id BETWEEN -770706 AND -770701 EXCEPT ALL
     SELECT * FROM pg_temp.tp7_d_fixtures)) THEN
    RAISE EXCEPTION 'STOP: fixtures ausentes o alterados';
  END IF;
  IF (SELECT count(*) FROM public.usuario WHERE id BETWEEN -770706 AND -770701) <> 6
     OR (SELECT count(*) FROM public.usuario WHERE id BETWEEN -770706 AND -770701 AND eliminado) <> 2
     OR EXISTS (
      (SELECT rol::text,date_trunc('month',created_at)::date,count(*),count(*) FILTER (WHERE eliminado)
       FROM public.usuario WHERE id BETWEEN -770706 AND -770701
       GROUP BY rol,date_trunc('month',created_at)::date
       EXCEPT ALL VALUES ('ADMIN',DATE '2026-01-01',2::bigint,1::bigint),
                        ('VENDEDOR',DATE '2026-02-01',2::bigint,0::bigint),
                        ('USUARIO',DATE '2026-03-01',2::bigint,1::bigint)))
     OR (SELECT count(*) FROM public.usuario_anon_cobertura_tp7
          WHERE nombre_lab IN ('LabD-Anon--770702','LabD-Anon--770706') AND eliminado) <> 2 THEN
    RAISE EXCEPTION 'STOP: distribucion o inclusion de eliminados incorrecta';
  END IF;
END $$;

SELECT rol,mes_alta,count(*) AS cantidad FROM public.usuario_anon_cobertura_tp7
GROUP BY rol,mes_alta ORDER BY rol,mes_alta;
SELECT rol,date_trunc('month',created_at)::date AS mes_alta,count(*) AS cantidad
FROM public.usuario GROUP BY rol,date_trunc('month',created_at)::date ORDER BY rol,mes_alta;
WITH anon AS (
 SELECT rol,mes_alta,count(*) AS cantidad FROM public.usuario_anon_cobertura_tp7 GROUP BY rol,mes_alta
), q_real AS (
 SELECT rol,date_trunc('month',created_at)::date AS mes_alta,count(*) AS cantidad
 FROM public.usuario GROUP BY rol,date_trunc('month',created_at)::date
)
SELECT coalesce(a.rol,r.rol) AS rol,coalesce(a.mes_alta,r.mes_alta) AS mes_alta,
       a.cantidad AS cantidad_anon,r.cantidad AS cantidad_real
FROM anon a FULL OUTER JOIN q_real r ON a.rol=r.rol AND a.mes_alta=r.mes_alta
ORDER BY rol,mes_alta;

DO $$
DECLARE d1 bigint; d2 bigint; na bigint; nr bigint;
BEGIN
 SELECT count(*) INTO d1 FROM (
  (SELECT rol,mes_alta,count(*) FROM public.usuario_anon_cobertura_tp7 GROUP BY rol,mes_alta)
  EXCEPT ALL
  (SELECT rol,date_trunc('month',created_at)::date,count(*) FROM public.usuario
   GROUP BY rol,date_trunc('month',created_at)::date)) d;
 SELECT count(*) INTO d2 FROM (
  (SELECT rol,date_trunc('month',created_at)::date,count(*) FROM public.usuario
   GROUP BY rol,date_trunc('month',created_at)::date)
  EXCEPT ALL
  (SELECT rol,mes_alta,count(*) FROM public.usuario_anon_cobertura_tp7 GROUP BY rol,mes_alta)) d;
 SELECT count(*) INTO na FROM public.usuario_anon_cobertura_tp7;
 SELECT count(*) INTO nr FROM public.usuario;
 IF d1<>0 OR d2<>0 OR na<>nr THEN
   RAISE EXCEPTION 'STOP: no equivalencia; diferencias %/%, totales %/%',d1,d2,na,nr;
 END IF;
 RAISE NOTICE 'Comparacion adicional: diferencias %/%, totales %/%',d1,d2,na,nr;
END $$;
ROLLBACK;
