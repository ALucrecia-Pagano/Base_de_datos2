# Declaración de Uso de IA — TP3 Optimización

## Parte 1 — Carga masiva (parte1_carga_masiva)

### Herramientas utilizadas

| Herramienta | Para que se uso | Prompt / spec | Se acepto / descarto |
|---|---|---|---|
| OpenCode (Plan->Build) | Generar script de carga masiva propio a partir de una spec redactada segun los requisitos de la Parte 1 | Spec con reglas de volumen y nombres del esquema propio (cliente, id_categoria, precio_lista, etc.) | Descartado: cumplia la consigna original del TP, pero no correspondia al dataset especifico que la catedra pidio cargar a todo el curso el mismo dia (Genera_registros.sql) |
| Claude (asistente conversacional, no agente sobre el repo) | Traducir linea por linea Genera_registros.sql (script de la catedra) al esquema real del proyecto, y resolver el mapeo del ENUM estado_pedido_enum | Adaptacion literal, documentando cada cambio de nombre en el encabezado del script resultante | Aceptado, con el mapeo documentado en el encabezado de seed_masivo.sql: usuario->cliente, categoria_id->id_categoria, precio->precio_lista, usuario_id->id_cliente, CONFIRMADO->EN_PREPARACION, TERMINADO->ENTREGADO, precio_unitario completado explicitamente con precio_lista (el esquema propio no tiene el trigger trg_subtotal del original) |
| Kiro (modo spec, solo lectura) | Generar verificacion_carga.sql para auditar la integridad de la carga masiva ya ejecutada | "Verificar conteos, integridad referencial, precios negativos, duplicados de PK y distribucion de estado/forma_pago contra foodstore_tp3_carga, sin modificar nada" | Aceptado sin cambios; resultado documentado abajo |
| Kiro (auditoria final, solo lectura) | Auditar seed_masivo.sql y este mismo DUIA contra la consigna oficial y contra Genera_registros.sql (textos completos pegados en el prompt) | "Comparar fidelidad al script del profesor, cumplimiento de los 4 puntos de la Parte 1, y calidad del DUIA; listar discrepancias" | Aceptado: encontro 6 discrepancias (D1-D6), documentadas y resueltas en este mismo archivo |

### Registro cronologico de decisiones

1. Primer intento con OpenCode (modo Plan -> Build): se redacto una spec
   propia con los requisitos de carga masiva adaptada a los nombres reales
   del esquema. OpenCode genero seed_masivo.sql leyendo antes schema.sql.

2. Cambio de consigna: la catedra distribuyo un script propio
   (Genera_registros.sql) con datos y logica especificos que todo el curso
   debia cargar igual, no una version libre generada por IA.

3. Adaptacion del script de la catedra: se descarto el seed_masivo.sql
   generado por OpenCode y se reemplazo por una traduccion literal de
   Genera_registros.sql al esquema real, realizada con ayuda de Claude
   para resolver el mapeo de nombres de tabla/columna y el ENUM de estado.

### Verificacion de restricciones antes de ejecutar (consigna, punto 2)

Antes de correr seed_masivo.sql contra foodstore_tp3_carga se verifico
explicitamente:

- CHECK: los rangos generados (precio_lista 500-5000, stock 0-200,
  cantidad 1-4) caen dentro de los CHECK del esquema
  (chk_producto_precio_positivo, chk_producto_stock_no_negativo,
  chk_detalle_cantidad_positiva, chk_detalle_precio_unitario_positivo).
- UNIQUE: el email generado (cliente<i>@test.com) es unico por
  construccion (i va de 1 a 20.000 sin repetirse), cumple
  chk_cliente_email_valido y la restriccion UNIQUE de cliente.email.
- FK: id_categoria, id_cliente e id_producto se toman siempre con
  SELECT ... FROM <tabla> ORDER BY random(), es decir sobre IDs ya
  existentes; no hay insercion de FKs "a mano".
- No toca produccion: se ejecuto exclusivamente contra
  foodstore_tp3_carga (copia dedicada, creada con
  createdb -T foodstore_dev foodstore_tp3_carga), nunca contra
  foodstore_dev ni foodstore_copia_trabajo (esta ultima usada en TP2).

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

### Respaldo (protocolo de seguridad, punto 3 de la consigna)

**Aclaracion sobre el momento del respaldo:** no se genero un pg_dump de
la copia foodstore_tp3_carga *antes* de correr seed_masivo.sql, porque en
ese momento la copia solo contenia el dataset base de TP1 (3 clientes, 3
productos, 5 pedidos, 7 detalles), trivialmente reproducible en cualquier
momento con `createdb -T foodstore_dev foodstore_tp3_carga`. En cambio,
se genero el respaldo *despues* de la carga masiva
(`respaldo_foodstore_tp3_carga.sql`, ~32MB) y *antes* de iniciar la Parte
2, que va a aplicar cambios DDL (CREATE INDEX) sobre esta misma copia —
que es el momento en que el protocolo de seguridad propio
(protocolo_seguridad.md, Paso 3) exige respaldo sin excepcion. El seed en
si corrio dentro de una transaccion (BEGIN/COMMIT), lo que ya daba
capacidad de revertir sin costo si algo hubiera fallado a mitad de camino.

No se versiona en Git por su peso (~32MB, excluido via `.gitignore`). Es
reproducible en cualquier momento con:
`pg_dump -U postgres -d foodstore_tp3_carga -f respaldo_foodstore_tp3_carga.sql`

### Conclusion

Carga masiva verificada como integra y consistente con las restricciones
del esquema, con doble verificacion (ejecucion directa + auditoria
independiente de Kiro) y respaldo generado antes de iniciar cambios DDL.

**Parte 1 cerrada.**

## Parte 2 — Laboratorio EXPLAIN (parte2_optimizacion_explain)

**Estado: pendiente, aun no iniciada.**