# TP7 — Evidencia de respaldo y ensayo reversible de la corrección de seguridad

- Fecha: 2026-10-15 ~11:17 (UTC-3). Rama: `main`. Base: `foodstore_dev`, PostgreSQL 17.11,
  conexión administrativa explícita `psql -X -w -U postgres` (sin mostrar credenciales).
- Alcance ejecutado: respaldo + ensayo (`aplicar=0`) con `ROLLBACK` final. Sin cambios persistentes,
  sin `aplicar=1`, sin commit/push. Sin credenciales reales ni hashes en este archivo.

## 1. Respaldo (aprobado, restauración no probada)

- `C:/Users/hp/Respaldos_BD2/respaldo_foodstore_dev_20261015_111715_antes_tp7_correccion_seguridad.dump`
  (custom, 76543 bytes, sin sobrescribir anteriores).
- `pg_dump` exit 0; `pg_restore --list` exit 0 y legible (284 entradas TOC, `Format: CUSTOM`).
  Legible no equivale a restauración probada. No se exportaron contraseñas ni hashes de roles.

## 2. Inventario previo (sin secretos)

- Conteos: categoria 2, cliente 3, producto 3, pedido 5, detalle_pedido 7, usuario 2.
- `usuario_id_seq`: `last_value=2, is_called=t`.
- Fixtures 900001/900002: 0. `tmp_sensible_demo`: ausente. `usuario_anon`: ausente.
- `rol_auditoria`: miembro `pg_monitor` (t), lee `pg_authid` (t) — exceso instalado confirmado.
- Defaults: escritura `arw` (= SELECT de más vs RF-07) en serie plana y `FOR ROLE admin_datos`.
- Funciones: `prosecdef=t`, `proconfig={search_path=public, pg_temp}` (configuración anterior instalada).

## 3. Ensayo único (aprobado)

- Comando (sintéticas de laboratorio, valores no publicados):
  `psql -X -w -U postgres -d foodstore_dev -v aplicar=0 -v lab_vf_password=*** -v lab_vf_password_new=*** -f TP7_Administracion_y_Seguridad/sql/corregir_seguridad_tp7.sql`
- `PSQL_EXIT=0`. Salida íntegra en
  `TP7_Administracion_y_Seguridad/docs/evidencias/salida_psql_ensayo_correccion_20261015_111731.txt`.
- Comprobaciones observadas (todas sin `ERROR`): procedencia pgcrypto verificada por OID
  (`crypt` 1 homónima, `gen_salt` 2 homónimas, firmas exactas de la extensión);
  catálogos `pg_authid`/`pg_shadow` denegados a `rol_auditoria` (42501) con `pg_monitor` vigente;
  `contrasena` denegada a `rol_soporte` (42501); auth válida = id exacto, incorrecta = NULL,
  eliminado = NULL; reset válido = TRUE con re-auth y anterior = NULL; inválidos = FALSE;
  escalamiento denegado 42501; funciones `DEFINER` + `proconfig` cerrado + llamadas calificadas;
  demo D11 (herencia + excepción en la misma transacción).
- Cierre: `ROLLBACK TO SAVEPOINT sp_pruebas` + `RELEASE` + `ROLLBACK` final. Nada persistió.

## 4. Comparación posterior en conexión nueva (aprobada)

- Conteos 2/3/3/5/7 + usuario 2; secuencia `2/t` (sin avance: fixtures con IDs explícitos).
- Fixtures 0, `tmp_demo` ausente.
- `rol_auditoria` vuelve a leer `pg_authid` (t): la revocación del ensayo se revirtió.
- Defaults `arw` y `proconfig` anterior restituidos: estado idéntico al previo.
- Conclusión: el ensayo no dejó ningún cambio. Detenido aquí para revisión antes de aplicar.
