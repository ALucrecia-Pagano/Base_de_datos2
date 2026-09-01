# Declaración de Uso de IA — TP3 Optimización

## Parte 1 — Carga masiva (parte1_carga_masiva)

| Herramienta | Para qué se usó | Prompt / spec | Se aceptó / descartó |
|---|---|---|---|

## Parte 2 — Laboratorio EXPLAIN (parte2_optimizacion_explain)

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


### Resultado de la ejecucion (confirmado en el motor)

Ejecutado contra `foodstore_tp3_carga` con:
`psql -U postgres -d foodstore_tp3_carga -f TP3_Optimizacion/parte1_carga_masiva/seed_masivo.sql`

- producto: 50.000 filas insertadas
- cliente: 20.000 filas insertadas
- pedido: 200.000 filas insertadas
- detalle_pedido: 621.794 filas insertadas (promedio ~3.1 lineas/pedido, dentro del rango 1-4 esperado)
- COMMIT confirmado, ANALYZE ejecutado sobre las 4 tablas afectadas.

### Verificacion independiente con Kiro

Se genero con Kiro (modo spec, solo lectura) el script
`verificacion_carga.sql`, que chequea contra `foodstore_tp3_carga`:
conteo de filas por tabla, integridad referencial (FKs huerfanas),
precios negativos, duplicados de PK compuesta en detalle_pedido, y
distribucion de pedidos por estado y forma de pago.

Resultado: 0 filas huerfanas, 0 precios negativos, 0 duplicados de PK.
Distribucion de estado y forma_pago uniforme (~25% y ~33% respectivamente).
Diferencia de conteos (3/3/5/7) coincide exactamente con el dataset de
prueba original de TP1, heredado por clonar foodstore_dev con -T.

Conclusion: carga masiva verificada como integra y consistente con
las restricciones del esquema. Respaldo generado
(respaldo_foodstore_tp3_carga.sql) antes de iniciar la Parte 2, que
va a aplicar cambios DDL (CREATE INDEX) sobre la copia de trabajo.

Parte 1 cerrada.

**Nota sobre el respaldo:** se genero localmente con
`pg_dump -U postgres -d foodstore_tp3_carga -f respaldo_foodstore_tp3_carga.sql`
(~32MB). No se versiona en Git por su peso — se excluyo via `.gitignore`.
Es reproducible en cualquier momento con el mismo comando, ya que la base
foodstore_tp3_carga sigue existiendo localmente.
