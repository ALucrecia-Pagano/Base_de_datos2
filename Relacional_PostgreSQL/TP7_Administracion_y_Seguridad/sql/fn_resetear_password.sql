-- ============================================================================
-- TP7 — Clase 2: fn_resetear_password (reconstrucción punto de partida)
-- Proyecto: FoodStore — Base de Datos II (UTN FRM)
-- Archivo: TP7_Administracion_y_Seguridad/sql/fn_resetear_password.sql
-- Base de destino: foodstore_dev (NO ejecutar sobre foodstore_copia_trabajo)
-- Motor: PostgreSQL 16+ (compatible con 17)
-- ============================================================================
-- CONTEXTO:
--   Las funciones fn_autenticar / fn_resetear_password no existen en el
--   repositorio (TP1–TP6) ni en foodstore_dev (verificado 2026-10-14:
--   0 funciones en public en ambas bases). Se reconstruyen aquí como paso
--   previo obligatorio ("El caso de Food Store: punto de partida" del TP).
--
-- COMPATIBILIDAD DE ESQUEMA (decisión validada por el equipo):
--   Se mantiene el esquema real del repo
--   (TP5_Indices_Vistas/Parte_B_Vistas/usuarios.sql):
--     usuario(id, nombre, apellido, mail, celular, contrasena, rol,
--             eliminado, created_at)
--   p_id_usuario == columna "id"; p_nueva_password se guarda como hash
--   bcrypt en "contrasena" ("password_hash" del enunciado).
--
-- SEGURIDAD (endurecido en corrección de auditoría 2026-10-15, sin cambiar
-- firma, retorno ni comportamiento):
--   - pgcrypto crypt/gen_salt('bf') para el nuevo hash (nunca texto plano).
--   - SECURITY DEFINER + SET search_path = pg_catalog, pg_temp: ningún
--     identificador de usuario se resuelve implícitamente mediante public —
--     la tabla va como public.usuario y cada llamada va calificada.
--   - Llamadas calificadas con tipos explícitos: ninguna resolución depende de
--     esquemas escribibles por otros roles — public.crypt(text, text),
--     public.gen_salt(text), pg_catalog.btrim(text), pg_catalog.char_length(text).
--     El procedimiento de aplicación verifica la pertenencia a la extensión
--     pgcrypto de las firmas exactas utilizadas; no demuestra ausencia de otras
--     sobrecargas. Ante duda aborta, no adivina.
--   - REVOKE ALL FROM PUBLIC: el acceso se otorga solo vía roles.sql §8
--     (EXECUTE a rol_soporte y admin_datos, resto NINGUNO).
--   - Política mínima de password: longitud >= 8 tras trim (los CHECK del
--     repo solo exigen no-vacío; este mínimo es decisión TP7 documentada).
--   - Respeta baja lógica: no resetea usuarios con eliminado = TRUE
--     (devuelve FALSE); el alta/baja la gestiona rol_soporte vía
--     UPDATE(eliminado) según Kiro RF-03.
--
-- IDEMPOTENCIA: CREATE EXTENSION IF NOT EXISTS + CREATE OR REPLACE.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE OR REPLACE FUNCTION public.fn_resetear_password(
    p_id_usuario     BIGINT,
    p_nueva_password VARCHAR
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, pg_temp
AS $func$
DECLARE
    v_actualizadas INTEGER;
BEGIN
    -- Validación mínima (decisión TP7): password de al menos 8 caracteres.
    IF p_id_usuario IS NULL
       OR p_nueva_password IS NULL
       OR pg_catalog.char_length(pg_catalog.btrim(p_nueva_password)) < 8 THEN
        RETURN FALSE;
    END IF;

    UPDATE public.usuario AS u
    SET contrasena = public.crypt(pg_catalog.btrim(p_nueva_password)::text, public.gen_salt('bf'::text))
    WHERE u.id = p_id_usuario
      AND u.eliminado = FALSE;

    GET DIAGNOSTICS v_actualizadas = ROW_COUNT;

    RETURN (v_actualizadas = 1);
END;
$func$;

COMMENT ON FUNCTION public.fn_resetear_password(BIGINT, VARCHAR) IS
'TP7 Clase 2: resetea el hash bcrypt de usuario.contrasena para un usuario '
'activo. Devuelve TRUE si actualizó 1 fila. SECURITY DEFINER; EXECUTE vía roles.sql §8.';

-- Mínimo privilegio desde la creación (roles.sql §8 lo reafirma).
REVOKE ALL ON FUNCTION public.fn_resetear_password(BIGINT, VARCHAR) FROM PUBLIC;
