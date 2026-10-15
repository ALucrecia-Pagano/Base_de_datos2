# TP7 Parte C — Procedimiento del simulacro (para revisión, no ejecutado)

> `sql/simulacro_incidente.sql` está preparado para revisión. No se ejecutó:
> no hay resultados reales, no hay decisión humana de contención redactada.

## 1. Decisiones tomadas en el script

- Secuencia PDF C.1 completa: 3 `fn_autenticar` fallidos sobre `lab_c_incidente_01@example.invalid` (contraseñas incorrectas sintéticas `incorrecta_laboratorio_01/02/03`) → 1 exitoso sobre el mismo sintético con `-v lab_sim_password_ok` → lectura masiva → `GRANT admin_datos TO app_web` bajo `app_web`, que debe fallar. Usuarios unificados con `preparar_entorno_local.sql` (`lab_c_incidente_01/02`); el §0 exige ambos presentes. Antes de usarla, el script comprueba que la contraseña correcta no coincida con ninguna incorrecta.
- Solo sintéticas: nada de usuarios reales; la correcta va por `-v` (no versionada, no publicada).
- Autenticación comprobada por valor devuelto (`NULL` en cada fallido; id exacto en éxito), porque el log de sentencias no demuestra el retorno.
- Instrumentación de resultados (sin contraseñas ni hashes): tras verificar cada fallo, `RAISE LOG` + `RAISE NOTICE` con número de intento y `FALLIDO`; tras verificar el éxito, `EXITOSO` con el id; en el manejador del escalamiento rechazado, `DENEGADO` con `SQLSTATE` y `current_user` (será `app_web`). Los mensajes solo se emiten después de verificar; si el escalamiento tiene éxito se aborta como `HALLAZGO` y nunca se emite `DENEGADO`.
- Lectura masiva: `SET LOCAL ROLE rol_soporte; SELECT id, nombre, apellido, mail, celular, rol, eliminado, created_at FROM public.usuario ORDER BY id; RESET ROLE;` — todas las filas, sin `LIMIT`, sin `contrasena`. Cambios de rol explícitos; identidad de aplicación ≠ identidad PostgreSQL (`fn_autenticar` no cambia `session_user`).
- Escalamiento aislado: `SET ROLE` fuera del bloque interno; `GRANT` en `EXECUTE` con `EXCEPTION WHEN insufficient_privilege` que solo acepta `SQLSTATE 42501` (sin depender del idioma). Éxito u otro error → fallo. Si tiene éxito: `RAISE 'HALLAZGO…'` detiene el lab (con `ON_ERROR_STOP` la conexión debe cerrarse para descartar); se informa como defecto del esquema y no se aprueba.
- Marcadores `SIMULACRO_INCIDENTE_INICIO_C/FIN_C` (requieren `log_statement=all` para quedar en el log) y `ROLLBACK` final. Sin `COMMIT` ni `ALTER SYSTEM`.

## 2. Instrumentación vs log nativo (aclaración)

- Los `RAISE LOG`/`NOTICE` son instrumentación del laboratorio, no comportamiento automático de PostgreSQL: el motor no registra por sí solo los valores devueltos por `fn_autenticar` (solo vería el texto de la llamada con `log_statement=all`).
- `RAISE LOG` va al log del servidor (queda con el `log_min_messages=WARNING` vigente); `RAISE NOTICE` muestra el resultado al cliente `psql` (no queda en el servidor con ese nivel). Por eso el script emite ambos: el log no debe presentarse como si PostgreSQL registrara automáticamente los retornos.
- Ningún mensaje incluye contraseñas ni hashes (solo intento, resultado, id entero, `SQLSTATE` y usuario de sesión).

## 3. Prerrequisitos: la validación anterior no instaló nada

- `preparar_entorno_local.sql` terminó en `ROLLBACK`: extensión, tipo, `usuario`, vistas, materializada, funciones y roles TP7 **no** quedaron instalados. Este script no los crea: su §0 aborta si falta `fn_autenticar`, `usuario`, `rol_soporte`, `app_web`, `admin_datos` o los sintéticos `lab_c_incidente_01/02`.
- No incluir `preparar_entorno_local.sql` como si dejara objetos disponibles tras su `ROLLBACK`.

## 4. Preparación y auditoría pendientes (documentadas, no realizadas)

- Respaldo custom fechado de `foodstore_dev` fuera del repo (efecto: solo lectura del origen; archivo fuera del repo). No sobrescribir anteriores.
- Instalación persistente autorizada (efecto en base: extensión, tipo, tabla, vistas, materializada, funciones, sintéticos `lab_c_incidente_01/02` con hashes válidos; efecto en clúster: 7 roles). Vía `roles.sql` + sintéticos, sin tocar usuarios existentes.
- Auditoría (efecto en clúster completo, no solo la base): `log_connections=on`, `log_disconnections=on`, `log_statement=all` (necesario: `mod` no registra el `SELECT` masivo; tampoco registra los retornos, de ahí la instrumentación), `log_line_prefix='%m [%p] %u@%d %r %a '`, verificar `logging_collector=on`; si está `off` requiere reinicio (STOP sin autorización). Capturar valores previos de `pg_settings` y restaurarlos después con `ALTER SYSTEM SET` + `pg_reload_conf()`. El log contendrá contraseñas sintéticas en texto plano: usar solo sintéticas.
- Nada de lo anterior se ejecuta en esta etapa.

## 5. Evidencias: salida de cliente vs log nativo

- Salida del cliente: lo que devuelve `psql` (incluye los `NOTICE` de instrumentación; redirección a archivo). Log nativo: archivo del servidor en `log_directory` (ruta vía `pg_current_logfile()`), con quién/cuándo/dónde por `log_line_prefix` más las líneas `LOG` de instrumentación.
- Conservar los originales localmente (fuera del repo o en `docs/evidencias/` según volumen). Producir copias sanitizadas para compartir: reemplazar mails, nombres, IPs/puertos y cualquier parámetro de contraseña por valores sintéticos deterministas (misma tabla de sustitución que D/`usuario_anon`), manteniendo marcas y orden. Verificar que no queden credenciales ni hashes antes de entregar.
- Fragmento a extraer: entre `SIMULACRO_INCIDENTE_INICIO_C` y `FIN_C`, más `conexión/recibida/autenticada/autorizada`, `FATAL` si lo hubiera, sentencias, líneas de instrumentación (`FALLIDO`/`EXITOSO`/`DENEGADO`) y `desconexión`.

## 6. C.4 en sesión nueva de OpenCode

- Se hará después, en una sesión nueva, entregando **solamente** el log anonimizado como única evidencia, sin explicar el escenario ni el script ejecutado. Pedir reconstrucción + hipótesis de contención; luego contrastar contra lo ejecutado y decidir contención con criterio del equipo (esa decisión humana aún no está redactada).

## 7. Pendiente de ejecución (con autorización separada)

1. Respaldo + captura de `pg_settings` de auditoría.
2. Instalación persistente + sintéticos `lab_c_incidente_01/02` + auditoría `all`.
3. Una pasada del simulacro con `-v` sintética; conservar salida de cliente y extraer fragmento entre marcas.
4. Anonimizar copia del fragmento; verificar sanitización.
5. Sesión nueva OpenCode con solo el log anonimizado; contraste escrito; decisión de contención del equipo.
