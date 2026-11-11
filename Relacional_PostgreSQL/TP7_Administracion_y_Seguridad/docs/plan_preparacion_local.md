# TP7 C/D — Plan de preparación local (solo prepara, no ejecuta)

> Alcance de esta etapa: crear rama propia y estos dos archivos nuevos para revisión.
> No ejecuta SQL, no conecta a PostgreSQL, no cambia configuración, no hace commit ni push.
> No modifica A/B, TP5 ni `BITACORA.md`.

## 0. Procedencia (no son evidencias contradictorias)

- Equipo Mateo (A/B): `foodstore_dev`, PG 17.10, 6 tablas + 5 vistas + 1 materializada + 2 funciones + 7 roles al 2026-10-14. Fuente: `BITACORA.md`, `docs/kiro_roles_spec/verificacion_permisos.md §§1-6`, `docs/informe_auditoria.md §1` (`log_statement=all` en ese laboratorio).
- Inventario local Codex (esta máquina): `foodstore_dev`, PG 17.11, 5 tablas base; sin `usuario`, funciones ni roles TP7; `log_connections=off`, `log_disconnections=off`, `log_statement=none`, `logging_collector=on`.
- Se tratan como entornos/equipos distintos. Nada de lo anterior sustituye la verificación read-only del §2 antes de preparar.

## 1. Objetos que requieren C/D y archivos que permiten crearlos

- C.1: `fn_autenticar(VARCHAR,VARCHAR)->BIGINT` (`sql/fn_autenticar.sql`), lectura masiva permitida (§4), intento `GRANT admin_datos` que debe fallar (`sql/roles.sql §11`; `verificacion_permisos.md §6.2` es antecedente de otro entorno, no prueba local).
- C.2-6: marcas `SELECT` + `BEGIN/ROLLBACK` (`sql/auditoria_test.sql` como patrón, no para reutilizar datos), extracción y anonimización de log, reconstrucción posterior en sesión nueva (C.4), contraste y contención decidida por el equipo.
- D.1-3: `usuario_anon` nueva (archivo futuro `sql/usuario_anon.sql`, no creado aquí); agregación por `rol` y mes de `created_at`; equivalencia anon vs real.
- Base existente: `usuarios.sql` (tabla + tipo `rol_usuario`), `vistas.sql` (5 vistas), `vista_materializada.sql` (solo DDL + índice; se excluyen sus `REFRESH`/`SELECT` demo), `fn_resetear_password.sql`, `roles.sql` (única fuente de GRANTs/membresías de A).

## 2. Orden de preparación (verificable, `sql/preparar_entorno_local.sql`)

1. Assert `current_database()='foodstore_dev'`; abortar si no.
2. Pre-chequeos read-only dentro de `BEGIN`: extensión, tipo, tabla, 5 vistas, materializada + índice, 2 funciones, 7 roles, mails sintéticos ausentes. Ante conflicto → `RAISE EXCEPTION` y detenerse (no sobrescribir/borrar/reutilizar en silencio).
3. Dentro del mismo `BEGIN … ROLLBACK`: crear lo faltante con definiciones reales citadas, incluir `roles.sql` vía `\ir` (sin modificarlo ni duplicar su lógica), insertar solo sintéticos C, correr controles `SELECT`/booleanos (sin mostrar hashes). Termina en `ROLLBACK`, sin `COMMIT`.
4. Roles: este script no pre-crea los roles que `roles.sql` ya crea; los `GRANT`/`ALTER DEFAULT PRIVILEGES` siguen siendo exclusivamente `roles.sql`. No se agregan membresías ni permisos para facilitar el simulacro.

## 3. Conflictos que obligan a detenerse

- DB distinta de `foodstore_dev`; tipo/tabla/vista/función/rol/índice esperado ya existente; mail sintético ya existente; `roles.sql` ausente o modificado respecto de A. No ampliar alcance ni tocar A/B/TP5/`BITACORA.md`.

## 4. Lectura masiva C.1 (acordada)

- `SET ROLE rol_soporte; SELECT id, nombre, apellido, mail, celular, rol, eliminado, created_at FROM public.usuario ORDER BY id; RESET ROLE;`
- Todas las filas, sin `LIMIT`, sin `contrasena`. El `SET ROLE`/`RESET ROLE` es acción explícita del laboratorio y quedará en el log.
- `fn_autenticar` devuelve id o `NULL`; no cambia `session_user`/`current_user` de PostgreSQL. Éxito = retorno no nulo con el id esperado, misma sesión PG. Identidad de aplicación (fila `usuario`) ≠ identidad PostgreSQL (`app_web`, `rol_*`, `admin_datos`).
- Si la cátedra exigiera literalmente `SELECT *` con hash como rol bajo, se declara limitación (solo `admin_datos` puede; implicaría cambio de actor) en lugar de declarar cumplimiento.

## 5. Hashes y `crypt`

- `usuarios_datos.sql:14-18` son marcadores (`hash_ejemplo_*`), no bcrypt válidos. No se supone qué devuelve `crypt()` ante formato inválido (no comprobado). Los sintéticos C usan `crypt(<password por -v/Vault>, gen_salt('bf'))` calculado en ejecución; nunca se versionan contraseñas ni hashes ni se modifican los usuarios existentes. `-v` no evita exposición en historial shell, `ps` ni log del servidor: usar solo sintéticas.

## 6. C.4 diferida

- La reconstrucción con IA se hará después en una sesión nueva de OpenCode, con el log anonimizado como única evidencia y sin explicar el escenario. Esta etapa no la ejecuta.

## 7. DB vs clúster

- Solo `foodstore_dev`: tablas, vistas, materializada, funciones, `GRANT` sobre objetos, sintéticos revertidos.
- Clúster completo: `CREATE ROLE/LOGIN`, `pg_monitor`, `CONNECTION LIMIT`, `ALTER SYSTEM` + `pg_reload_conf()`, archivos de log. Afectan a todas las DBs. Este plan no los toca.

## 8. Respaldo y auditoría para ejecución futura (documentado, no realizado)

- Respaldo custom fechado fuera del repo + registro de `pg_settings(name,setting,source)` para los 7 parámetros de auditoría; restauración DB solo con autorización específica (operaciones fuera de transacción aparte).
- Auditoría futura: fijar `log_connections=on`, `log_disconnections=on`, `log_statement=all` (necesario para que el `SELECT` masivo quede registrado; `mod` no registra lecturas), `log_line_prefix='%m [%p] %u@%d %r %a '`, verificar `logging_collector=on`; si estuviera `off` se requiere reinicio (STOP sin autorización). Restaurar valores previos con `ALTER SYSTEM SET` + `pg_reload_conf()`. No usar `RAISE NOTICE` como marca (con `log_min_messages=WARNING` no garantiza registro); usar marcas `SELECT 'MARCADOR'`.
