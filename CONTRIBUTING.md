# Guía de colaboración

Leer [README.md](README.md), [AGENTS.md](AGENTS.md) y el [plan de trabajo](NoSQL_y_Movil/TP1_FoodStore_NoSQL/docs/plan_trabajo.md) antes de comenzar. Las siguientes son convenciones de colaboración; no acreditan una configuración de GitHub. La protección de `main` todavía no fue comprobada.

Los archivos de FoodStore se mantienen en `TP1_FoodStore_NoSQL/`; las responsabilidades siguientes corresponden a ese trabajo. Las reglas generales permanecen en la raíz.

## Responsabilidades

| Integrante | Consignas |
|---|---|
| Amanda | 1, 2 y 3 |
| Mateo | 4 y 5 |
| Lucas | 6 y 7 |

El equipo completo revisa la conclusión y el informe final. Registrar el alcance de cada tarea antes de iniciarla para evitar trabajo superpuesto y coordinar cambios en archivos de otro integrante.

### TP8 — Unidad 8

| Integrante | Consignas |
|---|---|
| Mateo | 1 y 2 |
| Amanda | 3 y la preparación de la 2.c en PostgreSQL |
| Lucas | 4.a y README |
| Los tres | 4.b (bitácora y DUIA por partes) y ensayo de defensa |

Los archivos del TP8 se mantienen en `TP8_Unidad8/`.

## Flujo acordado

Amanda realizó la preparación inicial mientras trabajaba sola y autorizó publicaciones directas en `main` durante esa etapa. Al incorporarse el equipo, el flujo previsto es trabajar en ramas y revisar mediante pull request, según los pasos siguientes. Ese antecedente no autoriza publicaciones directas para cualquier cambio documental futuro ni acredita protección de `main`.

1. Comprobar la rama y el estado del repositorio antes de actualizarlo.
2. Actualizar con `git pull --ff-only` cuando corresponda; detenerse ante conflictos o divergencias. Para asistentes, las operaciones de escritura requieren la autorización indicada en AGENTS.md.
3. Trabajar en ramas descriptivas, por ejemplo `amanda/modelo-migracion`, `mateo/consultas-comparacion` y `lucas/analisis-ia`.
4. Hacer commits pequeños con mensajes claros. Amanda realiza commits y pushes salvo nuevo pedido explícito.
5. Revisar el diff antes de publicar y comprobar que no incluya secretos ni datos personales reales.
6. Presentar un pull request con propósito, consignas, archivos afectados, validaciones, evidencias y asuntos pendientes. Acordar que otro integrante revise antes de integrar.

Aplicar las reglas comunes de datos, Git y comunicación de [AGENTS.md](AGENTS.md). Aprobar un script no autoriza ejecutarlo.

## Reportar un error

Indicar objetivo, pasos reproducibles, comportamiento esperado y observado, mensaje de error exacto, rama o revisión, archivos involucrados, fecha, motor y versiones conocidas. Si corresponde, identificar base, colección o tablas sin secretos y enlazar evidencia anonimizada. Separar hechos verificados de hipótesis; no adjuntar respaldos completos ni datos personales.
