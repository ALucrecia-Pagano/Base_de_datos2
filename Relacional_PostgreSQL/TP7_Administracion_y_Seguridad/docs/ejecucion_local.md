# TP7 Parte C — Ejecución local (antecedente de preparación)

> **Antecedente histórico:** las instrucciones siguientes describen la preparación previa
> a la ejecución; las referencias a “no ejecutado” o “pendiente” corresponden a esa etapa.
>
> **Estado documentado actual:** la instalación, auditoría temporal, simulacro y restauración
> constan en la [evidencia de ejecución](evidencias/ejecucion_20261015_0215.md).
> El [informe del incidente y decisión humana de contención](informe_incidente.md)
> conserva el contraste y la decisión existentes; no son nuevas ejecuciones.
> Las funciones canónicas corregidas se aplicaron y validaron mediante el corrector
> ([evidencia](evidencias/aplicacion_correccion_seguridad_20261015_1121.md)).
> No se acredita una nueva ejecución de los instaladores completos modificados.
> **Verificación posterior autorizada:** diez pruebas negativas de guardas, directas e incluidas
> mediante `\ir`, dieron el error esperado y exit 3; los cinco marcadores posteriores estuvieron
> ausentes. Consulta PUBLIC: 0 filas, exit 0. Conexiones de solo lectura
> ([evidencia](evidencias/verificacion_guardas_public_20261015_124512.md)). No se ejecutaron instalaciones ni el simulacro completo.
> La preparación anterior solo tuvo verificaciones estáticas; estas son comprobaciones posteriores.

## 0. Archivos

- `sql/preparar_entorno_local.sql`: validación reversible ya superada (exit 0, `ROLLBACK` final). Se conserva intacto.
- `sql/instalar_entorno_local.sql` (nuevo): instalación persistente; termina con `COMMIT` solo tras superar todos los controles; neutraliza placeholders con `PASSWORD NULL`.
- `sql/activar_auditoria_local.sql` (nuevo): 4 `ALTER SYSTEM` + `pg_reload_conf()` + verificación en conexión nueva; sin `logging_collector`, sin reinicio, sin `BEGIN/COMMIT`.
- `sql/simulacro_incidente.sql`: laboratorio C con instrumentación `RAISE LOG/NOTICE`, `ROLLBACK` final.

## 1. Respaldo fechado previo (fuera del repositorio)

- Antes de instalar: `pg_dump -Fc foodstore_dev` a `C:/Users/hp/Respaldos_BD2/respaldo_foodstore_dev_AAAAMMDD_HHMMSS_antes_tp7_instalacion.dump`, sin sobrescribir anteriores.
- Comprobar exit 0 y `pg_restore --list` legible. Nota: legible no equivale a restauración probada.
- Registrar ruta, tamaño, fecha, formato y salidas. Ante cualquier error posterior, detenerse y conservar evidencia; no borrar ni recrear bases.

## 2. Captura de valores y orígenes previos de auditoría (antes de cambiar nada)

Por cada parámetro (`log_connections`, `log_disconnections`, `log_statement`, `log_line_prefix`, más testigo `logging_collector`):

1. `SHOW <param>;` y `SELECT name, setting, unit, context, source, sourcefile FROM pg_settings WHERE name = '<param>';`
2. Presencia en `postgresql.auto.conf`: `SELECT * FROM pg_file_settings WHERE name = '<param>';` (o inspección del archivo; contiene solo lo fijado por `ALTER SYSTEM`).
3. Guardar todo fechado fuera del repo o en `docs/evidencias/`.

Restauración correcta (después del simulacro): por cada parámetro, si **estaba** en `auto.conf`, `ALTER SYSTEM SET <param> = '<valor_previo>'`; si **no estaba** (venía de `postgresql.conf`/defecto/compilado), `ALTER SYSTEM RESET <param>` para devolverlo a su fuente anterior — no imponer con `SET` un valor que antes procedía de otra fuente. Siempre cerrar con `SELECT pg_reload_conf();` y verificar en conexión nueva. `logging_collector` no se toca en ninguna fase.

## 3. Orden exacto de ejecución (con autorización separada por paso)

1. **Inventario** (solo lectura): base `foodstore_dev`, 5 tablas + conteos, ausencia de objetos/roles TP7 (abort-on-existence), `pg_settings` de auditoría. Si hay conflicto, STOP.
2. **Respaldo** (§1) + **captura** (§2).
3. **Instalación**: una pasada `psql -X -v lab_c_password_01=*** -v lab_c_password_02=*** -f sql/instalar_entorno_local.sql` (sintéticas, no publicar). Efecto persistente en base: extensión, tipo, `usuario` + 2 sintéticos, 5 vistas, materializada + índice, 2 funciones. Efecto en clúster: 7 roles con `GRANT`s de `roles.sql`, logins con `PASSWORD NULL`. Las 5 tablas originales intactas (solo leídas). Verificar `COMMIT` y controles sin `ERROR`.
4. **Auditoría**: una pasada `psql -X -f sql/activar_auditoria_local.sql`. Efecto en clúster completo (todas las bases): 4 valores en `auto.conf` + recarga; verificación con `\c` + `SHOW`/`pg_settings`/`pg_current_logfile()`. Sin reinicio.
5. **Simulacro**: una pasada `psql -X -v lab_sim_password_ok=*** -f sql/simulacro_incidente.sql` (termina en `ROLLBACK`; solo persiste lo que el log registre). Conservar salida de cliente íntegra.
6. **Evidencias**: extraer fragmento del log entre `SIMULACRO_INCIDENTE_INICIO_C/FIN_C` (+ conexiones, sentencias, instrumentación `FALLIDO/EXITOSO/DENEGADO`, desconexión). Conservar originales; producir copia anonimizada verificada (sin mails/nombres/IPs/contraseñas/hashes) para C.4.
7. **Restauración de auditoría** (§2, solo `SET`/`RESET` + `pg_reload_conf()`, verificado en conexión nueva). No reinstala ni borra objetos.

## 4. Ante errores

- Detenerse en el paso que falle, conservar salida/error completos y el estado posterior (inventario + conteos). Cerrar la conexión para descartar transacciones abiertas.
- No modificar scripts para sortear errores, no `COMMIT` parciales, no borrar ni recrear bases, no reintentar a ciegas.
- No eliminar originales ni presentar resultados aún no obtenidos: sin ejecución no hay `FALLIDO`/`EXITOSO`/`DENEGADO` que informar.

## 5. Efectos persistentes previstos (para revisión antes de ejecutar)

- Tras instalación: +1 extensión, +1 tipo, +1 tabla (`usuario`, 2 filas sintéticas), +5 vistas, +1 materializada + índice, +2 funciones, +7 roles (clúster) con política A, logins sin contraseña habilitada.
- Tras auditoría: `auto.conf` con 4 entradas + recarga; resto del clúster sin cambios; sin reinicio.
- Tras simulacro: ningún cambio de datos/objetos (revierte); solo salida de cliente + líneas en el log del servidor.
