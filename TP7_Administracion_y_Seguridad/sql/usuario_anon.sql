-- TP7 Parte D — usuario_anon.sql (ejecución histórica con ROLLBACK, exit 0).
-- Salida: ../docs/evidencias/salida_psql_usuario_anon_20261015_091628.txt.
-- Muestra ejecutada: 2 usuarios, 2 roles y un mes; sin nueva ejecución ni persistencia.
-- Anonimización de laboratorio + verificación de equivalencia agregada.
-- Fuente de requisitos: Trabajo Practico Unidad 5.pdf, Parte D.
-- Esquema real: TP5_Indices_Vistas/Parte_B_Vistas/usuarios.sql
--   (id, nombre, apellido, mail, celular, contrasena, rol, eliminado, created_at).
--
-- Qué hace, en una sola transacción REPEATABLE READ con zona horaria fija:
--   §0 comprueba foodstore_dev y el esquema requerido; se detiene si
--      public.usuario_anon ya existe (no borra ni sobrescribe objetos).
--   §1 crea public.usuario_anon con sintéticos deterministas (.invalid).
--   §2 la puebla desde public.usuario sin copiar identificadores reales.
--   §3 muestra ambas agregaciones (rol × mes de alta) y la comparación lado a lado.
--   §4 aborta con RAISE EXCEPTION si hay diferencias (EXCEPT ALL en ambos
--      sentidos + conteos totales); el NOTICE final solo resume, no sustituye
--      la comprobación.
-- No consulta ni imprime contrasena ni ningún hash. No incluye siquiera una
-- columna de contraseña. Termina en ROLLBACK: esta primera versión valida la
-- creación y la equivalencia sin dejar usuario_anon persistida.
-- Sin COMMIT ni ALTER SYSTEM. No requiere variables psql (-v).
-- Nota psql: este archivo no usa variables (:'…') dentro de cuerpos $$.

\set ON_ERROR_STOP on

BEGIN ISOLATION LEVEL REPEATABLE READ;

-- Misma instantánea (REPEATABLE READ) y mismo criterio mensual para ambos
-- conjuntos: toda la lectura ocurre bajo esta zona horaria.
SET LOCAL search_path TO public, pg_temp;
SET LOCAL TIME ZONE 'America/Argentina/Buenos_Aires';

-- §0. Prerrequisitos y abort-on-existence.
DO $$
BEGIN
  IF current_database() <> 'foodstore_dev' THEN
    RAISE EXCEPTION 'abortado: base actual=% se esperaba foodstore_dev', current_database();
  END IF;
  IF to_regclass('public.usuario') IS NULL THEN
    RAISE EXCEPTION 'prerrequisito ausente: tabla public.usuario, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema = 'public' AND table_name = 'usuario' AND column_name = 'rol') THEN
    RAISE EXCEPTION 'prerrequisito ausente: columna usuario.rol, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema = 'public' AND table_name = 'usuario' AND column_name = 'eliminado') THEN
    RAISE EXCEPTION 'prerrequisito ausente: columna usuario.eliminado, STOP';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns
                 WHERE table_schema = 'public' AND table_name = 'usuario' AND column_name = 'created_at') THEN
    RAISE EXCEPTION 'prerrequisito ausente: columna usuario.created_at, STOP';
  END IF;
  IF to_regclass('public.usuario_anon') IS NOT NULL THEN
    RAISE EXCEPTION 'conflicto: tabla public.usuario_anon ya existe, STOP (no se borra ni sobrescribe)';
  END IF;
END
$$;

-- §1. Tabla anonimizada: solo sintéticos de laboratorio + lo necesario para
-- agregar. Sin celular, sin contrasena/hash, sin apellido real, sin created_at
-- de precisión completa, sin id/mail/nombre originales. mes_alta DATE (día 1
-- del mes) minimiza la precisión temporal.
-- Limitación: los valores son deterministas (derivan del id) y los grupos
-- pequeños (p. ej. 2 sintéticas) permiten reidentificación por rol×mes; esto
-- es seudonimización de laboratorio, no anonimización irreversible.
CREATE TABLE public.usuario_anon (
    id_anon BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre_lab VARCHAR(80) NOT NULL,
    mail_lab VARCHAR(120) NOT NULL UNIQUE,
    rol public.rol_usuario NOT NULL,
    eliminado BOOLEAN NOT NULL,
    mes_alta DATE NOT NULL
);

COMMENT ON TABLE public.usuario_anon IS
  'TP7-D laboratorio: sintéticos deterministas (.invalid); conserva rol, eliminado y mes de alta para agregación. Sin celular, sin contrasena, sin identificadores reales. Grupos pequeños no garantizan anonimización irreversible.';

-- §2. Población determinista desde usuario (fuera de $$; sin secretos).
INSERT INTO public.usuario_anon (nombre_lab, mail_lab, rol, eliminado, mes_alta)
SELECT ('LabD-Anon-' || u.id),
       ('lab_d_anon_' || u.id || '@example.invalid'),
       u.rol,
       u.eliminado,
       (date_trunc('month', u.created_at)::date)
FROM public.usuario AS u
ORDER BY u.id;

-- §3a. Agregación sobre la tabla anonimizada: todas las filas, incluidas
-- las eliminadas (sin filtro), por rol y mes de alta.
SELECT rol, mes_alta, COUNT(*) AS cantidad
FROM public.usuario_anon
GROUP BY rol, mes_alta
ORDER BY rol, mes_alta;

-- §3b. Agregación equivalente sobre la tabla real: mismas filas (sin filtro),
-- mismo agrupamiento, misma zona horaria de sesión.
SELECT rol, (date_trunc('month', created_at)::date) AS mes_alta, COUNT(*) AS cantidad
FROM public.usuario
GROUP BY rol, (date_trunc('month', created_at)::date)
ORDER BY rol, mes_alta;

-- §3c. Comparación lado a lado (FULL OUTER JOIN para mostrar desajustes).
WITH anon AS (
  SELECT rol, mes_alta, COUNT(*) AS cantidad
  FROM public.usuario_anon
  GROUP BY rol, mes_alta
), q_real AS (
  SELECT rol, (date_trunc('month', created_at)::date) AS mes_alta, COUNT(*) AS cantidad
  FROM public.usuario
  GROUP BY rol, (date_trunc('month', created_at)::date)
)
SELECT COALESCE(a.rol, r.rol) AS rol,
       COALESCE(a.mes_alta, r.mes_alta) AS mes_alta,
       a.cantidad AS cantidad_anon,
       r.cantidad AS cantidad_real
FROM anon AS a
FULL OUTER JOIN q_real AS r
  ON a.rol = r.rol AND a.mes_alta = r.mes_alta
ORDER BY rol, mes_alta;

-- §4. Equivalencia que aborta ante diferencias (no solo imprime "coinciden").
DO $$
DECLARE
  v_anon_menos_real INT;
  v_real_menos_anon INT;
  v_n_anon INT;
  v_n_real INT;
  v_grupos INT;
BEGIN
  SELECT count(*) INTO v_anon_menos_real FROM (
    (SELECT rol, mes_alta, COUNT(*) AS cantidad FROM public.usuario_anon
     GROUP BY rol, mes_alta)
    EXCEPT ALL
    (SELECT rol, (date_trunc('month', created_at)::date) AS mes_alta, COUNT(*) AS cantidad
     FROM public.usuario
     GROUP BY rol, (date_trunc('month', created_at)::date))
  ) AS d1;
  SELECT count(*) INTO v_real_menos_anon FROM (
    (SELECT rol, (date_trunc('month', created_at)::date) AS mes_alta, COUNT(*) AS cantidad
     FROM public.usuario
     GROUP BY rol, (date_trunc('month', created_at)::date))
    EXCEPT ALL
    (SELECT rol, mes_alta, COUNT(*) AS cantidad FROM public.usuario_anon
     GROUP BY rol, mes_alta)
  ) AS d2;
  SELECT count(*) INTO v_n_anon FROM public.usuario_anon;
  SELECT count(*) INTO v_n_real FROM public.usuario;
  SELECT count(*) INTO v_grupos FROM (
    SELECT rol, mes_alta FROM public.usuario_anon GROUP BY rol, mes_alta
  ) AS g;
  IF v_anon_menos_real <> 0 OR v_real_menos_anon <> 0 OR v_n_anon <> v_n_real THEN
    RAISE EXCEPTION 'no-equivalencia: anon-real=% filas, real-anon=% filas, totales anon=% real=%',
      v_anon_menos_real, v_real_menos_anon, v_n_anon, v_n_real;
  END IF;
  RAISE NOTICE 'equivalencia verificada: % filas totales, % grupos rol×mes',
    v_n_real, v_grupos;
END
$$;

ROLLBACK; -- validación reversible; usuario_anon no persiste en esta versión.
-- Efecto previsto: ningún objeto persiste; solo se muestran agregaciones por
-- rol×mes (sin identificadores) y se comprueba su equivalencia exacta.
-- Sin COMMIT ni ALTER SYSTEM aquí.
