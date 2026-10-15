# TP7 — Evidencia de aplicación y validación de la corrección de seguridad

- Fecha: 2026-10-15 ~11:21 (UTC-3). Rama: `main`. Base: `foodstore_dev`, PostgreSQL 17.11,
  conexión administrativa explícita `psql -X -w -U postgres` (sin mostrar credenciales).
- Precondición: scripts sin cambios desde el ensayo (mtimes anteriores a 11:17:31, mismo set de
  archivos); respaldo `respaldo_foodstore_dev_20261015_111715_antes_tp7_correccion_seguridad.dump`
  disponible (76543 bytes). Sin credenciales reales ni hashes en este archivo.

## 1. Aplicación — COMMIT (aprobada)

- Comando (sintéticas de laboratorio, valores no publicados):
  `psql -X -w -U postgres -d foodstore_dev -v aplicar=1 -v lab_vf_password=*** -v lab_vf_password_new=*** -f TP7_Administracion_y_Seguridad/sql/corregir_seguridad_tp7.sql`
- `PSQL_EXIT=0`. Salida íntegra en
  `TP7_Administracion_y_Seguridad/docs/evidencias/salida_psql_aplicacion_correccion_20261015_112112.txt`.
- Secuencia observada: procedencia pgcrypto verificada por OID (`crypt`/`gen_salt` de la extensión);
  `REVOKE` de catálogos; 8 `ALTER DEFAULT PRIVILEGES`; funciones reemplazadas (`CREATE FUNCTION` × 2,
  `REVOKE` de `PUBLIC` incluido); 3 `GRANT EXECUTE`; comprobaciones completas del cuerpo compartido
  (catálogos, monitoreo, soporte, auth/reset con fixtures, escalamiento, `DEFINER`+`proconfig`, demo D11);
  `ROLLBACK TO SAVEPOINT sp_pruebas` (fixtures y demo revertidos) y **`COMMIT` final**.

## 2. Validación independiente — ROLLBACK (aprobada)

- Comando (conexión nueva, sintéticas distintas, valores no publicados):
  `psql -X -w -U postgres -d foodstore_dev -v lab_vf_password=*** -v lab_vf_password_new=*** -f TP7_Administracion_y_Seguridad/sql/validar_correccion_seguridad.sql`
- `PSQL_EXIT=0`. Salida íntegra en
  `TP7_Administracion_y_Seguridad/docs/evidencias/salida_psql_validacion_correccion_20261015_112125.txt`.
- Mismas comprobaciones superadas; cierre `ROLLBACK` final. Nada persistió por esta vía.

## 3. Comprobación posterior en conexión nueva (aprobada)

- `rol_auditoria`: miembro `pg_monitor` (t); no lee `pg_authid` (f) ni `pg_shadow` (f).
- Funciones: `prosecdef=t`, `proconfig={search_path=pg_catalog, pg_temp}` en ambas.
- Defaults `rol_app_escritura`: `aw` (= INSERT+UPDATE, sin SELECT) en serie `postgres` y
  `FOR ROLE admin_datos`; lectura `r` para `rol_app_lectura` en ambas.
- Conteos 2/3/3/5/7 + usuario 2; secuencia `usuario_id_seq 2/t` (sin avance).
- Fixtures 900001/900002: 0. `tmp_sensible_demo`: ausente.

## 4. Cambios que quedaron persistidos

Catálogos revocados a `rol_auditoria` (conserva `pg_monitor`); defaults al RF-07 exacto (ambas series);
funciones reemplazadas por versiones endurecidas con `EXECUTE` de §8. Sin cambios de contraseñas, sin
reinstalación, sin borrado de objetos o datos, sin `ALTER SYSTEM`.
