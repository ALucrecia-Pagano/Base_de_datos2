# TP7 Parte C.4 — Respuesta completa de la IA (conservada íntegra)

- Herramienta: OpenCode. Modelo informado por la configuración: Muse Spark 1.3 Free.
- Entrada entregada: exclusivamente `docs/log_simulacro_anonimizado.txt` (209 líneas), sin explicar el escenario.
- Esta respuesta se conserva íntegra, sin correcciones ni resúmenes. La revisión humana está en `docs/informe_incidente.md`.
- No se registran fechas o metadatos de la sesión por no constar en evidencia.

---

## C.4 — Reconstrucción a partir del log anonimizado (única evidencia)

Trabajo solo con `docs/log_simulacro_anonimizado.txt` (209 líneas). No consulté otros archivos ni ejecuté nada.

### 1. Hechos observados (con líneas)

- **Una sola sesión, un solo origen, ~0,08 s:** todo ocurre bajo PID 21348, usuario `postgres`, base `foodstore_dev`, aplicación `psql`, origen `198.51.100.7(40001)`. Conexión recibida/autenticada (`scram-sha-256`)/autorizada (lín. 1–3, 02:10:24.422–436), `BEGIN` (lín. 4), `ROLLBACK` (lín. 208) y desconexión con duración `0:00:00.091` (lín. 209). No hay otras sesiones ni otros orígenes en el fragmento.
- **Chequeo de prerrequisitios previo:** bloque `DO` (lín. 7–34) que abortaría si faltan `fn_autenticar`, tabla `usuario` o roles `rol_soporte`/`app_web`/`admin_datos`, o los dos sintéticos. No hay error: continúa a la marca de inicio (lín. 35).
- **Tres intentos fallidos + uno exitoso contra la misma cuenta:** tres llamadas `fn_autenticar('usuario_anon_01@anon.invalid', 'clave_erronea_anon_0N')` (lín. 45, 49, 53) seguidas cada una de `LOG … FALLIDO` (lín. 59, 84, 109). Luego `fn_autenticar` con el secreto de sesión y `LOG … EXITOSO id=1` (lín. 140, 149). Las contraseñas incorrectas son tres valores distintos; la correcta viaja redactada (`SET LOCAL my.sim_pw_ok TO '***'`, lín. 6).
- **Lectura masiva restringida en columnas:** `SET LOCAL ROLE rol_soporte` (lín. 166), `SELECT id, nombre, apellido, mail, celular, rol, eliminado, created_at FROM public.usuario ORDER BY id` —todas las filas, sin `LIMIT`, sin columna de credencial— (lín. 167–169), `RESET ROLE` (lín. 170).
- **Intento de escalamiento denegado:** `SET LOCAL ROLE app_web` (lín. 171), `SAVEPOINT` (lín. 172), `EXECUTE 'GRANT admin_datos TO app_web'` dentro de bloque que captura `insufficient_privilege` (lín. 173–187) y `LOG … DENEGADO sqlstate=42501 usuario=app_web` (lín. 188). Cierre con `RELEASE`, `RESET ROLE`, marca de fin y `ROLLBACK` (lín. 205–208).
- **Sin fallos de autenticación del motor:** no hay líneas `FATAL` ni `password authentication failed`; las "fallas" son retornos de función, no rechazos de conexión.

### 2. Hipótesis de lo ocurrido (secuencia)

Un cliente automatizado (`psql`, una sola conexión) ejecutó un guion controlado: verificó prerrequisitos, probó 3 credenciales erróneas contra una cuenta sintética, luego la credencial correcta (éxito, id=1), leyó la tabla de usuarios con un rol limitado y a columnas permitidas, intentó auto-otorgarse el rol administrativo y fue denegado (42501), cerrando con `ROLLBACK`. El patrón —marcas de inicio/fin, `SAVEPOINT`/`RELEASE`, `SET LOCAL`/`RESET`, mensajes de resultado numerados, duración sub-segundo— es consistente con un **laboratorio guiado, no con un ataque real**.

### 3. Hipótesis de contención (propuesta, no ejecutada)

Si esto fuera real: (a) bloquear temporalmente el origen en el perímetro; (b) forzar rotación de la credencial de la cuenta objetivo y revisar sus sesiones activas; (c) confirmar que no hubo persistencia (aquí hubo `ROLLBACK` y el escalamiento fue denegado); (d) conservar el log íntegro y auditar accesos del rol implicado. Es solo hipótesis: no tomo ni recomiendo ejecutar ninguna acción desde este análisis.

### 4. Lo que el registro NO permite determinar (lectura crítica)

- **Contenido real devuelto:** el log muestra el texto del `SELECT` masivo, no sus filas; cuántas/cuáles filas se leyeron no es verificable aquí (los conteos solo constarían en la salida del cliente, ausente de este log).
- **Veracidad de los resultados:** `FALLIDO`/`EXITOSO id=1`/`DENEGADO` provienen de `RAISE LOG` del propio guion (instrumentación visible en lín. 47–48, 144–145, 182–183), no de un registro automático del motor. Si el guion mintiera, el log repetiría la mentira; la única señal independiente es la ausencia de `ERROR`/`HALLAZGO` y el `SQLSTATE` del manejador.
- **Secreto correcto:** viaja redactado (`'***'`); no se puede saber si era la credencial legítima ni su fortaleza.
- **Efecto del `ROLLBACK`:** se ve la sentencia, no qué habría persistido sin él (en el fragmento no hay escrituras, así que probablemente nada, pero el log no lo demuestra por sí solo).
- **Atribución e impacto:** un solo origen local, una sola sesión de 91 ms y datos sintéticos apuntan a prueba controlada; intencionalidad maliciosa, alcance en otras ventanas de tiempo y afectación a datos reales quedan fuera de lo que este fragmento sustenta. Cualquier afirmación sobre fechas fuera del 02:10:24.422–501, otros atacantes o exfiltración sería inferencia sin evidencia.
- **Causa de los fallidos:** el log no distingue credencial errónea de cuenta inexistente/eliminada (la función devuelve `NULL` en todos los casos por diseño visible en el código registrado); atribuirlo a una causa concreta excede el registro.
