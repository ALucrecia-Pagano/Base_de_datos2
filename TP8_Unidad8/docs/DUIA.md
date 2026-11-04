# DUIA — Declaración de Uso de IA · TP8 Unidad 8 (Food Store en la feria)

**Materia:** Base de Datos II · **Comisión:** 4 · **Docente:** Sergio Neira
**Alumnos:** Mateo Lautaro Liendo, Lucas Ávila, Amanda Pagano
**Fecha:** 03/11/2026

Como en los TP anteriores del grupo, cada integrante declara su parte. El detalle cronológico de la parte de Lucas está en [bitacora_ia.md](bitacora_ia.md). Cada integrante puede explicar y defender en clase lo que declara.

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
| **Herramienta** | A completar por Amanda (la consigna indica OpenCode, en modo Plan, para el code review 3.c). |
| **Detalle** | A completar por Amanda. |

## Datos personales
No se cargaron contraseñas, correos ni datos personales reales en las herramientas de IA ni en las bases. Las pruebas usan datos inventados y copias de la base.
