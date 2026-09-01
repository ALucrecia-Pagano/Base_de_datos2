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
## Correccion critica post-cierre: bug de aleatorizacion no correlacionada

**Contexto:** durante la Parte 2 (al analizar la selectividad real de Q2
antes de aplicar indices), se detecto que producto.id_categoria estaba
degenerado: 50.002 de 50.003 productos en una sola categoria. Esto llevo
a una investigacion mas profunda que revelo un bug de fondo en el script
Genera_registros.sql original de la catedra (no introducido por la
adaptacion de nombres hecha en este proyecto).

**Causa tecnica:** las subconsultas escalares del tipo
`(SELECT id FROM tabla ORDER BY random() LIMIT 1)`, al no hacer referencia
a ninguna columna de la fila externa, pueden ser resueltas por PostgreSQL
una unica vez para toda la sentencia en vez de una vez por fila. Lo mismo
ocurrio con un CROSS JOIN LATERAL cuya subconsulta interna tampoco
referenciaba la fila externa -- el motor lo trato como no correlacionado
en la practica, pese a la palabra clave LATERAL.

**Impacto medido (version v1, base foodstore_tp3_carga antes del arreglo):**
- producto.id_categoria: 50.002 de 50.003 filas en una sola categoria
  (esperado: reparto ~50/50 entre las 2 categorias)
- pedido.id_cliente: 200.000 de 200.005 pedidos pertenecientes a un
  UNICO cliente (id 7481) (esperado: reparto entre ~20.000 clientes)
- detalle_pedido.id_producto: solo 7 productos distintos en 621.801
  filas (esperado: cercano a 50.000 productos distintos)

**Correccion aplicada (version v2 de seed_masivo.sql):** se reemplazaron
las subconsultas escalares y el CROSS JOIN LATERAL por indexado de
arrays (array_agg de IDs + floor(random()*n) como expresion directa en
la lista de columnas del SELECT), que si se evalua fila por fila. Para
detalle_pedido se elimino ademas la dependencia de dos llamadas
separadas a random() para producto y precio: se selecciona el
id_producto por indice de array y se recupera su precio_lista real
mediante un JOIN comun (no lateral) contra producto.

**Procedimiento de correccion:**
1. Base foodstore_tp3_carga recreada desde cero
   (dropdb + createdb -T foodstore_dev).
2. seed_masivo.sql v2 ejecutado exitosamente:
   producto 50.000, cliente 20.000, pedido 200.000,
   detalle_pedido 499.564 filas insertadas.
3. Re-verificado con verificacion_carga.sql (actualizado con una nueva
   seccion 6 de distribucion de FKs, agregada especificamente para
   detectar este tipo de problema a futuro):
   - producto.id_categoria: 24.922 / 25.081 (~50/50) -- CORREGIDO
   - clientes distintos con pedidos: 20.003 de 20.003 -- CORREGIDO
   - productos distintos vendidos: 50.001 de 50.003 -- CORREGIDO
   - integridad referencial, precios negativos, duplicados de PK:
     0 filas en todos los casos (igual que en la version v1)
   - distribucion de estado y forma_pago: se mantiene uniforme
     (~25% y ~33% respectivamente, no estaban afectados por este bug)
4. Nota sobre el conteo de detalle_pedido: bajo de 621.801 (v1, con
   bug) a 499.571 (v2, corregido). Este numero mas bajo es el
   CORRECTO: 499.571 / 200.005 pedidos = ~2.5 lineas por pedido en
   promedio, que coincide exactamente con el promedio esperado de una
   eleccion uniforme entre 1 y 4 lineas ((1+2+3+4)/4 = 2.5). El
   numero viejo (621.801, ~3.1 promedio) era en si mismo otro sintoma
   del mismo bug, no un dato mas confiable.
5. Respaldo (pg_dump) regenerado sobre la base corregida; el respaldo
   anterior (generado sobre la base con el bug) quedo obsoleto y fue
   reemplazado (no se versiona en git, ver .gitignore).
6. Los planes de EXPLAIN ANALYZE de la Parte 2 (Q1, Q2, Q3) que se
   habian medido sobre la base con el bug se descartaron sin
   conservar, porque no representan el comportamiento real del
   esquema. Se vuelven a medir desde cero sobre la base ya corregida.

**Alcance para el resto del curso:** el bug esta en el script original
distribuido por la catedra (Genera_registros.sql), no en la adaptacion
de nombres propia. Es probable que cualquier companero que haya usado
el mismo script tenga el mismo problema en su base. Se genero un
documento de hallazgo (Word) para compartir con companeros y catedra.

**Herramientas usadas para este hallazgo y correccion:**

| Herramienta | Para que se uso | Se acepto / descarto |
|---|---|---|
| Claude (asistente) | Diagnosticar la causa raiz del sesgo detectado en Q2, verificar el alcance sobre las 3 relaciones, proponer y redactar la correccion (indexado de arrays en vez de subconsultas no correlacionadas) | Aceptado, verificado empiricamente en el motor tras cada cambio |

**Estado: correccion aplicada y verificada. Carga masiva v2 confirmada
como integra, con distribucion de claves foraneas correcta. Parte 1
re-cerrada.**
