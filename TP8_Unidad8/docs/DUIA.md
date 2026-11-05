# DUIA — Declaración de Uso de IA · TP8 Unidad 8 (Food Store en la feria)

**Materia:** Base de Datos II · **Comisión:** 4 · **Docente:** Sergio Neira
**Alumnos:** Mateo Lautaro Liendo, Lucas Ávila, Amanda Pagano
**Fecha:** 03/11/2026

Como en los TP anteriores del grupo, cada integrante declara su parte. El detalle cronológico de la parte de Lucas está en [bitacora_ia.md](bitacora_ia.md). Cada integrante puede explicar y defender en clase lo que declara.

**Herramientas de IA.** La consigna menciona OpenCode. El docente autorizó usar cualquier herramienta de IA; cada parte declara la que usó realmente.

## Parte de Lucas Ávila — Spec en Kiro (consigna 4.a) y revisión

| Campo | Detalle |
|---|---|
| **Herramientas** | Kiro (modo Spec) y Claude (Anthropic). Kiro ya se había usado en el grupo para los steering docs del repositorio relacional y en TP4. |
| **Spec o prompt utilizado** | Una spec retroactiva con exactamente 4 requisitos EARS ligados a casos de `casos_2c.sql` (REQ-01 precio distinto → CONFLICTO, C2; REQ-02 stock insuficiente → RECHAZADO, C3; REQ-03 producto dado de baja → RECHAZADO, C4; REQ-04 UUID repetido → no se duplica ni se reevalúa, C6), más `design.md` y `tasks.md` breves. Se indicó no generar ni modificar código y leer primero `semaforo.sql`, `casos_2c.sql` y `schema_sqlite.sql`. |
| **Qué generó** | `requirements.md`, `design.md` y `tasks.md` en `docs/kiro/`. Antes de escribir, Kiro leyó el código y planteó dos precisiones (precedencia de los rechazos sobre el conflicto de precio; la `PRIMARY KEY` de `cola_sync` como mecanismo real de unicidad). |
| **Qué se aceptó** | La versión técnica completa de REQ-01 y REQ-04; los criterios y motivos de REQ-02; la tabla de precedencia de estados y los casos C2–C6 de `design.md` y `tasks.md`, que coinciden con el código. |
| **Qué se modificó o descartó, y por qué** | **Descartado:** (1) la redacción simplificada de REQ-01 y REQ-04 (propuesta inicial de Lucas con ayuda de Claude), porque no coincidía con el código. (2) El criterio 4 de REQ-03, que equiparaba un producto inexistente a uno dado de baja: el estado es `RECHAZADO`, pero el motivo que escribe el código es `'Producto inexistente en la instantánea'`. (3) En `design.md`, "tablet Android" (no figura en el repositorio) y "idempotencia verificada" (la evidencia pide reejecutar la variante actual del semáforo). **Modificado:** el criterio 2 de REQ-03 (el motivo de baja solo se registra si no hay productos inexistentes ni no disponibles) y el glosario de `Estado_RECHAZADO` (producto no disponible y solicitud sin ítems). |
| **Verificación realizada** | Cada requisito se comparó línea por línea con `semaforo.sql` y los valores de cada caso con `casos_2c.sql`. Los archivos corregidos se releyeron desde el repositorio. No se ejecutó SQL en esta etapa. |
| **Limitaciones declaradas** | La spec se escribió **después** del código (retroactiva), aunque la consigna pide hacerla antes. Los puntos de control 3 y 5 de `tasks.md` figuran como hechos sin evidencia individual en el repositorio. Claude solo leyó archivos; no ejecutó SQLite, PostgreSQL ni MongoDB. |

## Parte de Mateo Liendo — Código SQLite de `movil/` (consignas 1 y 2)

| Campo | Detalle |
|---|---|
| **Herramienta** | Agente de GitHub Copilot. |
| **Qué generó** | El código de `movil/` (`schema_sqlite.sql`, `semaforo.sql`, `casos_2c.sql`, `importar_snapshot.sql`, `pruebas_sqlite.sql`). |
| **Detalle (spec o prompt, qué se aceptó, qué se descartó, verificación)** | A completar por Mateo. Dato documentado en `docs/resultado_semaforo_2b.md`: se corrigió un alias SQL con espacio que impedía analizar el script y se agregó una evaluación agrupada con rechazo de solicitudes sin ítems. |

## Parte de Amanda Pagano — Mapa, mantenimiento y code review (consigna 3)

| Campo | Detalle |
|---|---|
| **Herramientas** | Claude (Anthropic), Antigravity con el modelo Claude Sonnet 5.5 en modo Plan, y el agente de GitHub Copilot. |
| **Spec o prompt utilizado** | Claude: revisar el estado del TP contra la consigna y guiar paso a paso la consigna 2.c y la consigna 3. Copilot: prompts cerrados con los bloques exactos a reemplazar en `casos_2c.sql`, `consigna_2c.md`, `resultado_casos_2c.md`, el README y esta DUIA, sin commits y sin tocar otros archivos. Antigravity: code review de solo lectura de los 75 scripts de la cursada, con archivo, línea y fragmento citado, una prueba de comprobación por hallazgo y autocrítica de falsos positivos. |
| **Qué generó** | Claude: los scripts `preparar_casos_2c.sql`, `verificar_sin_cambios_2c.sql` y `recargar_snapshot.sql`, los cambios de `casos_2c.sql` y los borradores de `consigna_3a.md`, `consigna_3b.md` y `consigna_3c.md`. Copilot: la aplicación de cambios ya redactados en archivos existentes. Antigravity: 24 hallazgos (F01 a F24). |
| **Qué se aceptó** | Preparar C2 y C4 en una copia de PostgreSQL y exportar una instantánea nueva; los cambios puntuales en `casos_2c.sql`; 20 hallazgos aceptados y la corrección de F07. |
| **Qué se modificó o descartó, y por qué** | (1) Reescribir `casos_2c.sql` completo: se limitó a cambios puntuales para no reemplazar el trabajo de Mateo. (2) La primera pasada de Antigravity cubrió 54 de 75 scripts: se le pidió completar el resto. (3) Los hallazgos F09, F10 y F11 se descartaron con fundamento, y en F02 la IA interpretó mal `views.sql` (ver `consigna_3c.md`). (4) Claude afirmó, a partir del DUIA de TP2, que los triggers estaban instalados en `foodstore_copia_trabajo`; la base mostró que no, y la prueba de F05 se hizo instalándolos dentro de la transacción. |
| **Verificación realizada** | Todo se ejecutó en copias: `foodstore_tp8_feria` (copia de `foodstore_dev`), bases SQLite en memoria o fuera del repositorio y `BEGIN … ROLLBACK` en PostgreSQL. Casos C2 a C6 con SQLite 3.54.1; pedidos y stock iguales antes y después (5 pedidos, 7 detalles, stock total 185). F05, F07 y F09 comprobados en la base, con prueba de regresión después de corregir F07. Cada diff de Copilot se revisó antes del commit. |
| **Limitaciones declaradas** | Los hallazgos no desarrollados se decidieron por lectura del código, sin comprobación en la base. Los respaldos de MongoDB y de la tablet de la consigna 3.b son un plan, no se ensayaron. A las herramientas de IA solo se les dieron scripts y datos ficticios. |

## Datos personales
No se cargaron contraseñas, correos ni datos personales reales en las herramientas de IA ni en las bases. Las pruebas usan datos inventados y copias de la base.
