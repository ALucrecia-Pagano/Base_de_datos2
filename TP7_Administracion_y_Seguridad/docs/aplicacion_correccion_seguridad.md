# TP7 — Aplicación de la corrección de seguridad (auditoría 2026-10-15)

> Estado: **ejecutado el 2026-10-15 (~11:17–11:21 UTC-3)**: ensayo con `ROLLBACK` (exit 0),
> aplicación con `COMMIT` (exit 0) y validación independiente con `ROLLBACK` (exit 0).
> Las correcciones fueron aplicadas y publicadas en `88675cc`; el cierre documental posterior consta en `39e4c6e`.

## 1. Hallazgos que motivan la corrección

1. `rol_auditoria` recibía `SELECT` sobre **todas** las tablas de `pg_catalog` e `information_schema`
   (`roles.sql §9` anterior): un rol de monitoreo podía leer secretos del motor (`pg_authid.rolpassword`).
2. `app_web` y `admin_datos` se creaban con `PASSWORD 'CAMBIAR_POR_VAULT'` (hasta la corrección):
   secreto conocido y versionado. `roles.sql §2B` ahora crea sin contraseña habilitada; la instalación
   local ya tenía ambos logins neutralizados y el procedimiento no modifica credenciales.
3. `ALTER DEFAULT PRIVILEGES` otorgaba a `rol_app_escritura` futuros `SELECT, INSERT, UPDATE`: un `SELECT`
   de más respecto de RF-07 (`INSERT, UPDATE`), con lectura futura automática sobre tablas sensibles.
4. `fn_autenticar` / `fn_resetear_password` resolvían `crypt/gen_salt/btrim` por `search_path`, delegando
   la resolución a esquemas escribibles por otros roles.

## 2. Archivos (nuevos y modificados)

| Archivo | Cambio |
|---|---|
| `sql/roles.sql` (§§2B, 9, 10) | Sin password habilitada; sin catálogos; defaults al RF-07 exacto |
| `sql/fn_autenticar.sql`, `sql/fn_resetear_password.sql` | `search_path = pg_catalog, pg_temp`; llamadas calificadas con tipos explícitos; misma firma y comportamiento |
| `docs/kiro_roles_spec/requirements.md` (RF-06, RF-07, §2.2, §1.3) | Especificación corregida + contrato D11 para tablas sensibles |
| `docs/kiro_roles_spec/design.md` (§§2, 9, 10, D9–D11, §6) | Diseño corregido + contrato D11 explícito |
| `docs/kiro_roles_spec/verificacion_permisos.md` | Intacto salvo advertencia: su veredicto no valida estas correcciones |
| `sql/preparar_entorno_local.sql`, `sql/instalar_entorno_local.sql` (§5) | Reutilizan canónicos vía `\ir`; copias vulnerables eliminadas |
| `sql/corregir_seguridad_tp7.sql` | **Nuevo.** Ensayo (ROLLBACK) por defecto; con `-v aplicar=1`, COMMIT tras controles |
| `sql/validar_correccion_seguridad.sql` | **Nuevo.** ROLLBACK: fixtures funcionales, permitidos/denegados, `proconfig`, demo D11 |
| Este documento | Procedimiento, efectos y reversión |

Las copias internas anteriores de funciones vivían en `preparar/instalar_entorno_local.sql §5` del commit
0060cfd (recuperables vía `git show 0060cfd:...`); las evidencias previas
(`validacion_20261015_014013.md`, `ejecucion_20261015_0215.md`) corresponden a esas versiones internas.
Esas evidencias previas no validan las versiones corregidas. Las ejecuciones posteriores de las
versiones corregidas constan en §6 (ensayo, aplicación y validación independiente).

## 3. Respaldo previo (obligatorio, fuera del repo)

Antes de aplicar, con autorización separada:

```bash
pg_dump -w -U postgres -Fc -f "C:/Users/hp/Respaldos_BD2/respaldo_foodstore_dev_<AAAAMMDD_HHMMSS>_antes_tp7_correccion_seguridad.dump" foodstore_dev
pg_restore --list "<archivo>"  # legible no equivale a restauración probada
```

Sin sobrescribir respaldos anteriores. Registrar ruta, tamaño y salidas.

Alcance del respaldo: el `pg_dump` custom conserva la base (esquema, datos, `ALTER DEFAULT PRIVILEGES`,
`GRANT`s sobre objetos de la base y definiciones de funciones). **No** contiene por sí solo el estado
global del clúster: roles, membresías y contraseñas, `TABLESPACE`s, ni la configuración (`ALTER SYSTEM` /
`postgresql.auto.conf`). Para una recuperación completa se requiere captura adicional de metadatos:
`pg_dumpall --globals-only` (roles), `SELECT * FROM pg_file_settings` y copia de `postgresql.auto.conf`
(solo lectura, fuera del repo). No se afirma que el custom baste para todo el clúster.

## 4. Orden de aplicación (cada paso con autorización)

1. **Respaldo** (§3) + captura de metadatos + inventario de prerrequisitos (el propio script §0 aborta
   si falta algo).
2. **Ensayo**: una pasada sin `-v aplicar` (ausente o `aplicar=0`):
   `psql -X -v lab_vf_password='…' -v lab_vf_password_new='…' -f sql/corregir_seguridad_tp7.sql`.
   Ejecuta correcciones + comprobaciones completas (cuerpo compartido) y termina en `ROLLBACK`.
   Conservar la salida. Cualquier otro valor de `aplicar` aborta antes de modificar objetos.
3. **Corrección**: solo si el ensayo salió limpio, la misma pasada con `-v aplicar=1` (único valor que
   permite `COMMIT`), como el superusuario que aplicó `roles.sql`. Las comprobaciones completas corren
   dentro de su transacción antes de decidir; fixtures y demo viajan en un `SAVEPOINT` que se revierte
   antes del `COMMIT`: ningún usuario ni tabla de prueba persiste. Efecto persistente: catálogos
   revocados (conserva `pg_monitor`), defaults RF-07, funciones reemplazadas con `EXECUTE` de §8.
   **Sin cambios de contraseñas**.
4. **Comprobación posterior**: con la corrección ya aplicada (o no), una pasada del validador
   independiente (misma sintaxis `-v`, `ROLLBACK` final) para verificar el estado resultante.
5. **Evidencias**: archivar las salidas en `docs/evidencias/`; recién entonces actualizar documentación
   general y bitácora (no autorizado en este paso).

## 5. Reversión (sin restaurar permisos inseguros)

- **Catálogos**: si algo legítimo necesitara un catálogo puntual, otorgarlo granularmente con justificación
  y autorización; el blanket anterior no se restaura automáticamente bajo ningún concepto.
- **Contraseñas**: este procedimiento no las modifica; nada que revertir aquí.
- **Defaults**: `ALTER DEFAULT PRIVILEGES ... GRANT SELECT ON TABLES TO rol_app_escritura` (plana y
  `FOR ROLE admin_datos`) si el equipo lo autorizara; documentar el motivo.
- **Funciones**: las versiones internas del commit 0060cfd se conservan como historia (recuperables
  vía `git show 0060cfd:...`), pero **no** se restauran operativamente: reintroducirían las
  vulnerabilidades corregidas. Ante un fallo, detenerse, conservar la salida, cerrar la conexión para
  descartar la transacción e investigar la causa (procedencia, roles, defaults) sin revertir a código
  vulnerable; no corregir ni reintentar automáticamente.
- Ante cualquier error: detenerse, conservar la salida, cerrar la conexión para descartar la transacción;
  no corregir ni reintentar automáticamente.

## 6. Resultados observados (2026-10-15; sin reescribir antecedentes)

- **Ensayo** (`aplicar=0`, exit 0, `ROLLBACK` final, nada persistió):
  [salida íntegra](evidencias/salida_psql_ensayo_correccion_20261015_111731.txt) y
  [evidencia](evidencias/ensayo_correccion_seguridad_20261015_1117.md) (respaldo 11:17:15, inventario
  previo con exceso `audit_lee_authid=t` y defaults `arw`, comparación posterior idéntica al previo).
- **Aplicación** (`aplicar=1`, exit 0, **`COMMIT` final** con comprobaciones previas superadas y
  fixtures revertidos por SAVEPOINT):
  [salida íntegra](evidencias/salida_psql_aplicacion_correccion_20261015_112112.txt).
- **Validación independiente** (conexión nueva, exit 0, `ROLLBACK` final, nada persistió por esta vía):
  [salida íntegra](evidencias/salida_psql_validacion_correccion_20261015_112125.txt).
- **Posterior** (conexión nueva): `rol_auditoria` con `pg_monitor` sin leer `pg_authid`/`pg_shadow`;
  funciones `DEFINER` + `proconfig` cerrado; defaults escritura `aw` (sin SELECT) en ambas series;
  conteos y secuencia intactos; fixtures 0, sin `tmp_demo`. Detalle en
  [evidencia](evidencias/aplicacion_correccion_seguridad_20261015_1121.md).
- Las verificaciones anteriores (`validacion_20261015_014013.md`, `ejecucion_20261015_0215.md`) siguen
  describiendo las versiones internas del commit 0060cfd; no se reescriben como pruebas de las
  funciones actuales.

## 7. Publicación

Las correcciones de seguridad se publicaron en `88675cc`; las verificaciones posteriores y el cierre documental se incorporaron hasta `39e4c6e`.
