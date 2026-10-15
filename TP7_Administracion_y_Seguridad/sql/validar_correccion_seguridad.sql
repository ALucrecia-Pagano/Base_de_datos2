-- TP7 — validar_correccion_seguridad.sql (PARA REVISIÓN, NO EJECUTADO).
-- Validador independiente: ejecuta el cuerpo compartido de comprobaciones
-- (sql/comprobaciones_seguridad.sql) dentro de su propia transacción y
-- termina en ROLLBACK. El cuerpo compartido no abre ni cierra transacciones.
-- Requiere: psql -X -v lab_vf_password='…' -v lab_vf_password_new='…'
--   -f sql/validar_correccion_seguridad.sql (sintéticas de laboratorio, no reales).
-- Advertencia: -v NO evita exposición en historial shell, ps ni log del servidor.
-- Nota psql: este archivo no usa variables (:'…') dentro de cuerpos $$.

\set ON_ERROR_STOP on

BEGIN;

-- El cuerpo compartido exige sus -v, fija search_path/GUC y comprueba todo:
-- prerrequisitos y roles, catálogos sensibles, monitoreo y soporte, auth/reset
-- con fixtures sintéticos nuevos (IDs explícitos, revierten aquí), escalamiento
-- denegado, DEFINER + proconfig y demo D11.
\ir comprobaciones_seguridad.sql

ROLLBACK; -- validación reversible; nada persiste (fixtures, demo D11 y todo).
-- Sin COMMIT ni ALTER SYSTEM aquí.
