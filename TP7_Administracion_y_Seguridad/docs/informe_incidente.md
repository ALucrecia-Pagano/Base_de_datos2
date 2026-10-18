# TP7 Parte C — Informe del incidente (secuencia real, contraste y decisión)

> Secuencia realmente ejecutada el 2026-10-15 sobre `foodstore_dev` (PostgreSQL 17.11):
> instalación persistente con `COMMIT`, auditoría `all`, una pasada de
> `sql/simulacro_incidente.sql` (3 fallidos → 1 éxito → lectura masiva → escalamiento
> denegado 42501, `ROLLBACK` final), auditoría restaurada. Evidencias:
> `docs/evidencias/ejecucion_20261015_0215.md`, `docs/log_simulacro_anonimizado.txt`
> (209 líneas, PID 21348; bytes originales conservados intactos, copia de lectura UTF-8 con
> reparación localizada de mojibake en `docs/log_simulacro_anonimizado.utf8.txt`). La reconstrucción de la IA está íntegra en
> `docs/respuesta_ia_incidente.md`.

## 1. Secuencia ejecutada y evidencias

1. Inventario: 5 tablas base (categoria 2, cliente 3, producto 3, pedido 5, detalle_pedido 7), sin objetos/roles TP7.
2. Respaldo custom `respaldo_foodstore_dev_20261015_020646_antes_tp7_instalacion.dump` (`pg_dump` 0, `--list` legible; no equivale a restauración probada).
3. Instalación `sql/instalar_entorno_local.sql` (exit 0, `COMMIT`; logins con `PASSWORD NULL` verificado por booleanos; conteos intactos; 2 sintéticos).
4. Auditoría `on/on/all/'%m [%p] %u@%d %r %a '`, verificada en conexión nueva, log `postgresql-2026-10-15_000000.log`.
5. Simulacro (exit 0): marcas 02:10:24.469835–24.500797; `NOTICE` 3× `FALLIDO`, `EXITOSO id=1`, masiva 2 filas sintéticas, `DENEGADO 42501 usuario=app_web`; `ROLLBACK`.
6. Fragmento líneas 91–299 preservado fuera del repo; copia anonimizada verificada (0 secretos).
7. Auditoría restaurada por `RESET`×4 + reload a valores/fuentes previas, verificada en conexión nueva.
8. Final: conteos 2/3/3/5/7 sin cambios; 0 membresía `app_web → admin_datos`; 2 sintéticos persistidos.

## 2. Contraste: C.4 contra lo ejecutado

El [prompt literal propio para C.4](registro_prompts_opencode_codex_20261015.md#p19473) se recuperó del chat de preparación, donde pedía usar exclusivamente el log anonimizado. La usuaria aportó posteriormente la reconstrucción conservada en la respuesta íntegra. Esto documenta el pedido y su seguimiento en el chat; no sustituye una exportación independiente del contexto completo de la sesión de OpenCode.

### Qué acertó la IA

- **Acertó** en autenticaciones fallidas/exitosas (3 `NULL` + id exacto), lectura con columnas permitidas sin credencial y escalamiento denegado 42501 bajo `app_web`.
- Identificó a `postgres` como usuario de la sesión y los cambios explícitos a `rol_soporte` y `app_web`. La sesión administrativa orquesta `SET ROLE`; no todas las operaciones conservan privilegios efectivos de superusuario y no se trata de una intrusión real.
- **Filas devueltas:** el log anonimizado muestra solo el texto del `SELECT` masivo, no sus filas. Las 2 filas se comprobaron en la **salida del cliente** (`salida_psql_simulacro_20261015_0210.txt`, fuera del repo), no en el log. La IA lo señaló correctamente como no verificable en el log.
- **SQLSTATE 42501:** el manejador del guion solo acepta 42501 y aborta como `HALLAZGO` en otro caso; las marcas `RAISE LOG` y `NOTICE … DENEGADO … usuario=app_web` provienen de ese mismo guion. Son evidencias concordantes de la ejecución documentada, no corroboraciones independientes entre sí. La comprobación posterior de membresías (0 filas `app_web → admin_datos`) acredita el estado tras `ROLLBACK`, pero por sí sola no demuestra que el intento haya sido rechazado.
- **Cambio de rol ≠ escalada por `fn_autenticar`:** los `SET LOCAL ROLE rol_soporte/app_web` son acciones explícitas del laboratorio (visibles como sentencias); `fn_autenticar` solo devolvió el id sin cambiar `session_user`. No presentarlos como escalada lograda.
- **Instalación vs simulacro:** la instalación persistió con `COMMIT` (objetos y sintéticos quedan); el simulacro terminó con `ROLLBACK` (sin cambios de datos). La validación previa (`preparar_*.sql`) también revirtió todo y no dejó objetos.

### Qué omitió o no desarrolló

No se identifica una omisión comprobable adicional que deba imputarse a la IA a partir
del log entregado. La falta de filas devueltas, secreto correcto y alcance fuera del
fragmento son límites que la propia respuesta reconoce, no omisiones inventadas.

### Qué afirmó sin respaldo suficiente del log

- **"Origen local":** no se demuestra con la IP sustituida del anonimizado (`198.51.100.7` es documentación, no evidencia). El origen real (`::1`, instalación propia) consta en el fragmento original y en el inventario del equipo, no en la copia entregada a la IA.
- **Definición interna de `fn_autenticar`:** el fragmento registra llamadas y el comentario visible del guion (`fn` no cambia identidad PG), pero no la definición completa de la función; la semántica `NULL` genérico se conoce por `sql/fn_autenticar.sql`, fuera de lo entregado a la IA.

La referencia de la respuesta a un “origen local” no queda acreditada por la dirección
anonimizada. Asimismo, la afirmación de que el diseño de NULL genérico era visible en el
código registrado excede el fragmento: la definición completa de la función no estaba allí.
No se le atribuye haber omitido a `postgres` ni haber afirmado una intrusión hostil.

### Evaluación de la contención propuesta

- **Bloquear el origen:** la IA lo propuso como hipótesis. No se justifica automáticamente: exigiría validar el origen real y contar con autorización, y aquí el origen era la propia sesión autorizada.

Esta recomendación era condicional, no una afirmación de intrusión hostil ni un error
de hecho atribuido a la IA; su aplicación real exigiría investigación y autorización.

### Límite del ejercicio autodescriptivo

El log incluye comentarios, marcadores y mensajes instrumentados de un laboratorio
autodescriptivo. Esas pistas facilitaron reconocer el escenario controlado; este resultado
no demuestra capacidad para reconstruir cualquier incidente real.

## 3. Decisión humana (aprobada por la integrante que dirige esta sesión)

> “En este laboratorio no se bloquean direcciones ni se cambian credenciales adicionales, porque se verificó que fue una prueba autorizada con datos sintéticos y que el escalamiento fue rechazado. Se conservan las evidencias y se comprueba la ausencia de membresías indebidas. Ante un incidente real equivalente, primero se valida el origen y la cuenta afectada; si se confirma acceso no autorizado, se revocan las sesiones y se restablece la credencial comprometida. El bloqueo del origen dependerá de esa investigación.”

Decisión aprobada por la integrante que dirige esta sesión; no se atribuye aprobación a compañeros que no participaron. Las medidas del escenario real son propuestas, no acciones ejecutadas (nada se bloqueó, revocó ni restableció en este laboratorio).

## 4. Límites

- Restauración del respaldo no probada; concurrencia y costos no medidos. Al cierre de la Parte C
  estaban pendientes la Parte D y el cierre de la bitácora E; estado actual: D ejecutada
  ([verificación de equivalencia](verificacion_equivalencia.md)) y bitácora consolidada en la raíz
  ([BITACORA.md](../../BITACORA.md)).
- La Parte C cierra con este informe + respuesta IA íntegra + log anonimizado + evidencia fechada.

## Revisión documental de codificación (2026-10-15)

El round-trip Latin-1 anterior conservaba bytes, pero no demostraba legibilidad. Los originales
mezclan fragmentos Latin-1 y secuencias UTF-8: no tienen una codificación uniforme. Solo se
repararon secuencias comprobadas en la copia de lectura; no se repitió el laboratorio.
Transformación, líneas y hashes antes/después en la [revisión documental](revision_documental_20261015.md).
