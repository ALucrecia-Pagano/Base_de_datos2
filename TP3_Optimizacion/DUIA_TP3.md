# Declaración de Uso de IA — TP3 Optimización

## Parte 1 — Carga masiva (parte1_carga_masiva)

| Herramienta | Para qué se usó | Prompt / spec | Se aceptó / descartó |
|---|---|---|---|

## Parte 2 — Laboratorio EXPLAIN (02_optimizacion_explain)

| Herramienta | Para qué se usó | Prompt / spec | Se aceptó / descartó |
|---|---|---|---|

### Registro cronológico de decisiones

1. Primer intento con OpenCode (modo Plan -> Build): se redacto una spec
   propia con los requisitos de carga masiva adaptada a los nombres reales
   del esquema. OpenCode genero seed_masivo.sql leyendo antes schema.sql.

2. Cambio de consigna: la catedra distribuyo un script propio
   (Genera_registros.sql) con datos y logica especificos que todo el curso
   debia cargar igual, no una version libre generada por IA.

3. Adaptacion del script de la catedra: se descarto el seed_masivo.sql
   generado por OpenCode y se reemplazo por una traduccion literal de
   Genera_registros.sql al esquema real, realizada con ayuda de Claude
   (asistente conversacional) para resolver el mapeo de nombres de
   tabla/columna y el ENUM de estado.

| Herramienta | Para que se uso | Prompt / spec | Se acepto / descarto |
|---|---|---|---|
| OpenCode (Plan->Build) | Generar script de carga masiva propio | Spec con reglas de volumen y nombres del esquema propio | Descartado: no correspondia al dataset especifico pedido por la catedra |
| Claude (asistente) | Traducir Genera_registros.sql al esquema real y mapear el ENUM estado | Adaptacion literal, documentando cada cambio de nombre | Aceptado: mapeo usuario->cliente, categoria_id->id_categoria, precio->precio_lista, usuario_id->id_cliente, CONFIRMADO->EN_PREPARACION, TERMINADO->ENTREGADO, precio_unitario completado con precio_lista |

### Verificacion pendiente
seed_masivo.sql (version catedra) todavia no se ejecuto contra
foodstore_tp3_carga. Pendiente correrlo y registrar el resultado.
