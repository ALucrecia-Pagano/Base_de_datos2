# Bitácora de uso de IA — TP8 Unidad 8 (Food Store en la feria)

Comisión 4 · Base de Datos II · UTN FRM. Grupo: Pagano, Liendo, Ávila.
Cada entrada se escribió el mismo día de la interacción. Las entradas de la spec (parte de Lucas Ávila) se hicieron en **Kiro** y se revisaron con **Claude** (Anthropic), que leyó el repositorio y comparó la spec con el código. Las entradas de otros integrantes quedan marcadas como pendientes hasta que ellos las confirmen.

**Aclaración de orden de trabajo.** La consigna pide escribir la spec *antes* de generar el código. En este grupo el código (`schema_sqlite.sql`, `semaforo.sql`, `casos_2c.sql`, `importar_snapshot.sql`) ya estaba hecho cuando se escribió la spec. Por eso la spec es **retroactiva**: describe lo que el sistema ya hace y se verificó contra ese código. No se presenta como previa.

---

## Entrada 1 — 03/11/2026, ~15:40 · Kiro (modo Spec) · Lucas
**Qué pedí.** Una spec retroactiva con exactamente 4 requisitos EARS, cada uno ligado a un caso de `casos_2c.sql` (REQ-01 precio distinto → CONFLICTO, C2; REQ-02 stock insuficiente → RECHAZADO, C3; REQ-03 producto dado de baja → RECHAZADO, C4; REQ-04 UUID repetido → no se duplica ni se reevalúa, C6), más `design.md` y `tasks.md` breves. Le indiqué no generar ni modificar código y que leyera `casos_2c.sql`, `semaforo.sql` y `schema_sqlite.sql` antes de escribir.
**Qué propuso.** Antes de escribir, Kiro leyó el código y me hizo dos preguntas: (1) el semáforo solo llega a CONFLICTO si no hay ningún rechazo, así que "precio distinto → CONFLICTO" es incompleto; (2) lo que impide el UUID repetido es la `PRIMARY KEY` de `cola_sync`, no una lógica del semáforo.
**Qué acepté.** La opción "técnico completo": REQ-01 con la condición compuesta (precio distinto *y* sin condición de rechazo) y REQ-04 con los dos mecanismos (error de unicidad de la PK y filtro `PENDIENTE`).
**Qué descarté.** Mi redacción simplificada de REQ-01 y REQ-04, porque no coincidía con el código.
**Por qué.** El código evalúa primero los rechazos y el error de C6 es `UNIQUE constraint failed`; una spec que dijera otra cosa fallaría en la defensa.

## Entrada 2 — 03/11/2026, ~15:50 · Kiro + revisión con Claude · Lucas
**Qué pedí.** Generar `requirements.md`, `design.md` y `tasks.md`; luego revisé `requirements.md` con Claude, comparándolo línea por línea con `semaforo.sql`.
**Qué propuso Kiro.** En REQ-03, criterio 4: tratar un `producto_id` inexistente "como producto dado de baja". En el criterio 2 del mismo requisito, registrar el motivo `'Producto dado de baja'` sin condiciones.
**Qué descarté.** Ese criterio 4 tal como estaba escrito. El estado final sí es `RECHAZADO`, pero el motivo que escribe el código es `'Producto inexistente en la instantánea'`, no `'Producto dado de baja'`. También descarté la redacción incondicional del criterio 2: el motivo de baja solo se registra si antes no hay productos inexistentes ni no disponibles (orden del `CASE` de motivo).
**Qué acepté.** Las correcciones que Kiro aplicó a pedido mío (criterios 2 y 4 de REQ-03) y la ampliación del glosario de `Estado_RECHAZADO` (producto no disponible y solicitud sin ítems, que el código también rechaza). Comprobé el archivo resultante en el repositorio.
**Por qué.** Aceptar el texto tal cual habría dejado un requisito que el código contradice.

## Entrada 3 — 03/11/2026, ~16:00 · Kiro + revisión con Claude · Lucas
**Qué pedí.** Revisar `design.md` y `tasks.md` contra el repositorio.
**Qué propuso Kiro.** Describir una "tablet Android" y presentar la idempotencia como "verificada" en `resultado_semaforo_2b.md`.
**Qué descarté.** (a) "Android": no figura en ningún archivo del repositorio, la IA lo agregó por su cuenta. (b) "Verificada": ese mismo documento dice que la variante actual de `semaforo.sql` debe reejecutarse para actualizar la evidencia.
**Qué acepté.** "tablet" a secas y "Parcialmente verificada", con la aclaración de la reejecución pendiente. Lo demás de `design.md` y `tasks.md` (precedencia de estados, casos C2–C6, valores de cada caso) coincide con `casos_2c.sql` y el semáforo.
**Por qué.** No se afirma lo que no ocurrió.
**Pendiente conocido.** `tasks.md` marca como hechos los puntos de control 3 y 5, pero el repositorio no tiene una evidencia propia de cada uno; solo respaldan el punto 7 los documentos `resultado_casos_2c.md` y `resultado_semaforo_2b.md`.

## Entrada 4 — 03/11/2026, ~15:05 · Claude (Anthropic) · Lucas
**Qué pedí.** Ponerse al día con el README de Mateo, la consigna y los scripts, y armar el plan de mi parte (4.a, 4.b, 4.c).
**Qué propuso.** Un plan con orden de trabajo y siete riesgos: estructura de carpetas distinta entre el README y la consigna, falta de la consulta PostgreSQL de la consigna 2.c, evidencia del semáforo por reejecutar, spec retroactiva, falta de registro de IA, etc. También me sugirió redactar los 4 requisitos con la forma simple "precio distinto → CONFLICTO".
**Qué acepté.** El plan, el orden y la lista de riesgos (se comprobaron contra el repositorio).
**Qué descarté.** La redacción simplificada de REQ-01 (ver entrada 1): era una imprecisión de la propia IA y Kiro la detectó al leer el código.
**Por qué.** La consigna descuenta aceptar lo que dice la IA sin comprobarlo.

---

## Entrada 5 — 04/11/2026, ~20:30 · Claude (Anthropic) · Amanda
**Qué pedí.** Revisar el estado del TP8 contra la consigna y el repositorio, y planificar lo que faltaba.
**Qué propuso.** Que la consigna 2.c no cumplía "cambiar datos en la copia del servidor y exportar una instantánea nueva", y preparar C2 y C4 en una copia de PostgreSQL. También propuso reescribir `casos_2c.sql`.
**Qué acepté.** Preparar los casos en PostgreSQL (`foodstore_tp8_feria`) y exportar `servidor_snapshot_2c.csv`.
**Qué descarté.** Reescribir `casos_2c.sql` completo: lo limité a cuatro cambios puntuales.
**Por qué.** Para no reemplazar el trabajo de Mateo; los borradores, los UUID y el orden de los casos quedaron iguales.

## Entrada 6 — 04/11/2026, ~20:55 · Agente de GitHub Copilot · Amanda
**Qué pedí.** Aplicar en `casos_2c.sql` cuatro reemplazos con el texto exacto y ejecutar la verificación.
**Qué hizo.** Aplicó los cuatro cambios, pero no pudo ejecutar la verificación porque `sqlite3` no estaba instalado.
**Qué acepté.** Los cambios, después de revisar el diff línea por línea.
**Qué descarté.** Su verificación: la ejecuté yo con SQLite 3.54.1 y comparé con lo esperado.
**Por qué.** Un cambio que no se ejecutó no está comprobado.

## Entrada 7 — 04/11/2026, ~21:45 · Antigravity (Claude Sonnet 5.5, modo Plan) · Amanda
**Qué pedí.** Code review de solo lectura de los 75 scripts de la cursada, con archivo, línea, fragmento citado, prueba de comprobación y autocrítica.
**Qué propuso.** En la primera pasada leyó 54 de 75 scripts (el listado le truncó rutas). Después de autorizarle un segundo listado, completó 75 de 75: 24 hallazgos.
**Qué acepté.** 20 hallazgos como válidos (los de TP ya calificados quedan como mejora) y la corrección de F07.
**Qué descarté.** F09, F10 y F11, y la lectura de `views.sql` en F02 (indica correrse después de `schema.sql`, no correr `schema.sql` sobre la base de carga).
**Por qué.** F09 se refutó en la base; F10 y F11 son condiciones documentadas en la Unidad 6 y en TP7 (ver `consigna_3c.md`).

## Entrada 8 — 04/11/2026, ~22:00 · Claude (Anthropic) · Amanda
**Qué pedí.** Diseñar pruebas en la base para F05, F07 y F09.
**Qué propuso.** Para F05, borrar un pedido ENTREGADO. Afirmó, según el DUIA de TP2, que los triggers estaban instalados en `foodstore_copia_trabajo`.
**Qué acepté.** Las pruebas de F07 (antes y después de corregir, más regresión) y de F09 (vista, clave foránea y productos sin ventas).
**Qué descarté.** Esa afirmación: ninguna de las bases tiene hoy los triggers de TP2.
**Por qué.** Lo comprobé en la base; la prueba de F05 se hizo instalando los triggers dentro de `BEGIN … ROLLBACK`, para mostrar que el UPDATE se bloquea pero el DELETE pasa.

## Entradas pendientes de otros integrantes (no completadas por Lucas)
- **Mateo Liendo — código SQLite.** Mateo generó el código de `movil/` con el **agente de GitHub Copilot**. Falta que complete: qué pidió, qué aceptó y qué descartó. Dato documentado en el repositorio: la corrección de un alias SQL con espacio y la variante agrupada del semáforo con rechazo de solicitudes sin ítems (`resultado_semaforo_2b.md`). *La consigna menciona OpenCode para generar el esquema; si no se usó, la DUIA debe decir que fue Copilot.*
- **Amanda Pagano — consignas 2.c (preparación en PostgreSQL) y 3.** Completadas en las entradas 5 a 8.
