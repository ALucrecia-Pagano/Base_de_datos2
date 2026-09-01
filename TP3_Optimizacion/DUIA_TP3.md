# Declaración de Uso de IA — TP3 Optimización

## Parte 1 — Carga masiva (parte1_carga_masiva)

### Herramientas utilizadas

| Herramienta | Para que se uso | Prompt / spec | Se acepto / descarto |
|---|---|---|---|
| OpenCode (Plan->Build) | Generar script de carga masiva propio a partir de una spec redactada segun los requisitos de la Parte 1 | Spec con reglas de volumen y nombres del esquema propio (cliente, id_categoria, precio_lista, etc.) | Descartado: cumplia la consigna original del TP, pero no correspondia al dataset especifico que la catedra pidio cargar a todo el curso el mismo dia (Genera_registros.sql) |
| Claude (asistente conversacional, no agente sobre el repo) | Traducir linea por linea Genera_registros.sql (script de la catedra) al esquema real del proyecto, y resolver el mapeo del ENUM estado_pedido_enum | Adaptacion literal, documentando cada cambio de nombre en el encabezado del script resultante | Aceptado, con el mapeo documentado en el encabezado de seed_masivo.sql: usuario->cliente, categoria_id->id_categoria, precio->precio_lista, usuario_id->id_cliente, CONFIRMADO->EN_PREPARACION, TERMINADO->ENTREGADO, precio_unitario completado explicitamente con precio_lista (el esquema propio no tiene el trigger trg_subtotal del original) |
| Kiro (modo spec, solo lectura) | Generar verificacion_carga.sql para auditar la integridad de la carga masiva ya ejecutada | "Verificar conteos, integridad referencial, precios negativos, duplicados de PK y distribucion de estado/forma_pago contra foodstore_tp3_carga, sin modificar nada" | Aceptado sin cambios; resultado documentado abajo |
| Kiro (auditoria final, solo lectura) | Auditar seed_masivo.sql y este mismo DUIA contra la consigna oficial y contra Genera_registros.sql (textos completos pegados en el prompt) | "Comparar fidelidad al script del profesor, cumplimiento de los 4 puntos de la Parte 1, y calidad del DUIA; listar discrepancias" | Aceptado: encontro 6 discrepancias (D1-D6), documentadas y resueltas en este mismo archivo |
| Claude (asistente) | Diagnosticar la causa raiz de un sesgo detectado al preparar la Parte 2, verificar el alcance del problema sobre las 3 relaciones afectadas, y proponer/redactar la correccion del script de carga | Diagnostico + reescritura de seed_masivo.sql v2 | Aceptado, verificado empiricamente en el motor tras cada cambio (ver seccion "Correccion critica" mas abajo) |

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

4. (Ver seccion "Correccion critica" mas abajo) durante la preparacion de
   la Parte 2 se detecto un bug de fondo en la logica de aleatorizacion
   del script, heredado del original de la catedra. Se corrigio, se
   recargo la base y se re-verifico todo antes de avanzar a Parte 2.

### Verificacion de restricciones antes de ejecutar (consigna, punto 2)

Antes de correr seed_masivo.sql (v1) contra foodstore_tp3_carga se
verifico explicitamente:

- CHECK: los rangos generados (precio_lista 500-5000, stock 0-200,
  cantidad 1-4) caen dentro de los CHECK del esquema
  (chk_producto_precio_positivo, chk_producto_stock_no_negativo,
  chk_detalle_cantidad_positiva, chk_detalle_precio_unitario_positivo).
- UNIQUE: el email generado (cliente<i>@test.com) es unico por
  construccion (i va de 1 a 20.000 sin repetirse), cumple
  chk_cliente_email_valido y la restriccion UNIQUE de cliente.email.
- FK: id_categoria, id_cliente e id_producto se toman siempre sobre IDs
  ya existentes; no hay insercion de FKs "a mano".
- No toca produccion: se ejecuto exclusivamente contra
  foodstore_tp3_carga (copia dedicada, creada con
  createdb -T foodstore_dev foodstore_tp3_carga), nunca contra
  foodstore_dev ni foodstore_copia_trabajo (esta ultima usada en TP2).

(Esta misma verificacion de restricciones -CHECK/UNIQUE/FK/no produccion-
se re-confirmo para la version v2 del script tras la correccion del bug;
ningun CHECK, UNIQUE ni FK cambio entre v1 y v2, solo la logica de
aleatorizacion.)

### Resultado de la primera ejecucion, v1 (SUPERADA — ver correccion abajo)

Ejecutado contra `foodstore_tp3_carga` con:
`psql -U postgres -d foodstore_tp3_carga -f TP3_Optimizacion/parte1_carga_masiva/seed_masivo.sql`

- producto: 50.000 filas insertadas
- cliente: 20.000 filas insertadas
- pedido: 200.000 filas insertadas
- detalle_pedido: 621.794 filas insertadas
- COMMIT confirmado, ANALYZE ejecutado sobre las 4 tablas afectadas.

**Nota:** estos conteos son correctos en cantidad de filas, pero la
distribucion de claves foraneas resulto degenerada (ver "Correccion
critica" abajo). Los conteos totales por tabla no cambiaron de forma
relevante entre v1 y v2 excepto detalle_pedido, que si bajo (ver detalle
en la correccion).

### Primera verificacion con Kiro, sobre v1 (igualmente superada)

Se genero con Kiro (modo spec, solo lectura) el script
`verificacion_carga.sql`, que en su primera version chequeaba: conteo de
filas por tabla, integridad referencial (FKs huerfanas), precios
negativos, duplicados de PK compuesta en detalle_pedido, y distribucion
de pedidos por estado y forma de pago.

Resultado sobre v1: 0 filas huerfanas, 0 precios negativos, 0 duplicados
de PK. Distribucion de estado y forma_pago uniforme (~25% y ~33%
respectivamente). Estos chequeos pasaron porque **no incluian una
verificacion de distribucion de claves foraneas** — ese hueco fue
justamente lo que permitio que el bug pasara desapercibido en esta
primera ronda. Se corrigio agregando una seccion 6 al script (ver
correccion abajo).

### Respaldo (protocolo de seguridad, punto 3 de la consigna)

**Aclaracion sobre el momento del respaldo:** no se genero un pg_dump de
la copia foodstore_tp3_carga *antes* de correr seed_masivo.sql, porque en
ese momento la copia solo contenia el dataset base de TP1 (3 clientes, 3
productos, 5 pedidos, 7 detalles), trivialmente reproducible en cualquier
momento con `createdb -T foodstore_dev foodstore_tp3_carga`. El respaldo
se genero *despues* de cada carga (primero sobre v1, luego regenerado
sobre v2 tras la correccion) y *antes* de aplicar cambios DDL (CREATE
INDEX) en la Parte 2 — que es el momento en que el protocolo de
seguridad propio (protocolo_seguridad.md, Paso 3) exige respaldo sin
excepcion.

No se versiona en Git por su peso (~29-32MB, excluido via `.gitignore`).
Es reproducible en cualquier momento con:
`pg_dump -U postgres -d foodstore_tp3_carga -f respaldo_foodstore_tp3_carga.sql`

## Correccion critica: bug de aleatorizacion no correlacionada

**Contexto:** durante la preparacion de la Parte 2 (al analizar la
selectividad real de la consulta Q2 antes de aplicar indices), se
detecto que producto.id_categoria estaba degenerado: 50.002 de 50.003
productos en una sola categoria. Esto llevo a una investigacion mas
profunda que revelo un bug de fondo en el script Genera_registros.sql
original de la catedra (no introducido por la adaptacion de nombres
hecha en este proyecto).

**Causa tecnica:** las subconsultas escalares del tipo
`(SELECT id FROM tabla ORDER BY random() LIMIT 1)`, al no hacer
referencia a ninguna columna de la fila externa, pueden ser resueltas
por PostgreSQL una unica vez para toda la sentencia en vez de una vez
por fila. Lo mismo ocurrio con un CROSS JOIN LATERAL cuya subconsulta
interna tampoco referenciaba la fila externa — el motor lo trato como
no correlacionado en la practica, pese a la palabra clave LATERAL.

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
   - producto.id_categoria: 24.922 / 25.081 (~50/50) — CORREGIDO
   - clientes distintos con pedidos: 20.003 de 20.003 — CORREGIDO
   - productos distintos vendidos: 50.001 de 50.003 — CORREGIDO
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
   esquema. Se volvieron a medir desde cero sobre la base ya corregida
   (ver seccion Parte 2 mas abajo).

**Alcance para el resto del curso:** el bug esta en el script original
distribuido por la catedra (Genera_registros.sql), no en la adaptacion
de nombres propia. Es probable que cualquier companero que haya usado
el mismo script tenga el mismo problema en su base. Se genero un
documento de hallazgo (Word) para compartir con companeros y catedra.

### Conclusion Parte 1

Carga masiva (v2, corregida) verificada como integra y consistente con
las restricciones del esquema, con doble verificacion (ejecucion directa
+ auditoria independiente de Kiro) y respaldo generado antes de iniciar
cambios DDL. El proceso completo — incluyendo el hallazgo y correccion
de un bug real del script de la catedra — quedo documentado de punta a
punta.

**Parte 1 cerrada.**

## Parte 2 — Laboratorio EXPLAIN (parte2_optimizacion_explain)

### Consultas elegidas

Ver `queries_candidatas.sql`. Se eligieron 3 consultas sobre tablas
grandes del esquema, cada una tocando una relacion distinta:

- **Q1**: pedidos con estado PENDIENTE, ordenados por fecha (tabla pedido sola).
- **Q2**: productos de una categoria en un rango de precio (tabla producto sola).
- **Q3**: total facturado por cliente en un rango de fechas (join de 3 tablas: cliente, pedido, detalle_pedido).

Los planes "antes" (sin indices nuevos) estan en
`planes/plan_q1_antes.txt`, `plan_q2_antes.txt`, `plan_q3_antes.txt`,
medidos sobre la base ya corregida (v2, ver seccion anterior).

### Lectura linea por linea de los 4 indices antes de aplicar (consigna, punto 4)

Antes de ejecutar cada `CREATE INDEX` sobre `foodstore_tp3_carga` se
verifico explicitamente, para las 4 propuestas de Kiro:

- **idx_pedido_estado_fecha (estado, fecha_hora DESC)**: indice btree
  compuesto (tipo por defecto, no se pidio ningun tipo especial). Ambas
  columnas (`estado`, `fecha_hora`) existen en `pedido` con esos nombres
  exactos. No es `UNIQUE` ni parcial, por lo que no puede romper ninguna
  restriccion existente. Ataca exactamente el filtro `WHERE estado = ...`
  y el `ORDER BY fecha_hora DESC` de Q1, coherente con el nodo
  `Parallel Seq Scan + Sort` del plan real.
- **idx_producto_categoria_precio (id_categoria, precio_lista)**: mismo
  tipo de indice (btree, no unico, no parcial). Columnas existentes en
  `producto`. Se entendio que, a diferencia del indice parcial
  `idx_productos_categoria_activo` ya existente, este no filtra por
  `activo`, por lo que cubre productos activos e inactivos por igual —
  decision correcta para Q2, que tampoco filtra por `activo`.
- **idx_pedido_fecha_hora (fecha_hora)**: indice btree simple de una
  sola columna. Se entendio que este indice no afecta la relacion con
  `idx_pedidos_cliente_id` (columnas distintas) ni genera conflicto de
  nombre.
- **idx_detalle_pedido_id_pedido (id_pedido)**: indice btree simple. Se
  verifico que no colisiona con `idx_detalle_pedido_producto_id`
  (indice existente sobre `id_producto`, columna distinta) ni con la
  PK compuesta `(id_pedido, id_producto)`.

En los 4 casos se confirmo antes de ejecutar que: (a) es un `CREATE
INDEX` simple, sin `CONCURRENTLY` ni opciones no estandar que ameriten
mas revision; (b) no es una sentencia destructiva (un `CREATE INDEX` no
modifica filas, solo agrega una estructura de acceso); (c) el nombre del
indice no colisiona con ninguno de los 3 indices ya existentes de TP1.
Ninguna de las 4 propuestas fue rechazada en esta etapa de lectura —
las que no sirvieron se detectaron recien al medir con EXPLAIN ANALYZE
despues de aplicarlas (ver tabla de resultados abajo), no por lectura
previa incorrecta.

### Herramientas utilizadas

| Herramienta | Para que se uso | Prompt / spec | Se acepto / descarto |
|---|---|---|---|
| Kiro (solo propuesta, no ejecuta) | Proponer indices/reescrituras justificadas en los 3 planes reales de EXPLAIN ANALYZE | Planes completos pegados + pedido explicito de justificar por nodo, marcar indices existentes que casi cubren el caso, y estimar si la mejora seria grande o modesta | Las 4 propuestas se leyeron linea por linea antes de aplicar; resultado real de cada una documentado abajo (1 de 4 con mejora real) |

### Indices propuestos y resultado real de cada uno

Los 4 indices propuestos por Kiro (archivo `indices_propuestos.sql`) se
aplicaron **de a uno**, midiendo el efecto individual con EXPLAIN
ANALYZE antes de aplicar el siguiente. Detalle completo en
`tabla_comparativa.md`. Resumen:

| Consulta | Indice propuesto | Prediccion de Kiro | Resultado real | Decision |
|---|---|---|---|---|
| Q1 | idx_pedido_estado_fecha (estado, fecha_hora DESC) | Mejora grande | Confirmada: 33.7ms -> 0.9ms (~37x). Index Scan reemplazo Seq Scan+Sort+Gather Merge | Se mantiene |
| Q2 | idx_producto_categoria_precio (id_categoria, precio_lista) | Mejora modesta (por alta selectividad, 22% de la tabla) | Sin mejora real: 12.4ms -> 12.8ms. El planificador uso Bitmap Heap Scan (no preserva orden), asi que el Sort NO desaparecio como Kiro esperaba | Revertido (DROP INDEX) |
| Q3 (indice 1) | idx_pedido_fecha_hora (fecha_hora) | Mejora moderada | Empeoro: 160.1ms -> 203.1ms. El costo estimado bajo pero el plan perdio el paralelismo (2 workers) que tenia sin el indice | Revertido (DROP INDEX) |
| Q3 (indice 2) | idx_detalle_pedido_id_pedido (id_pedido) | Incierta, el propio Kiro lo marco como dependiente de que el planificador eligiera Nested Loop | El indice nunca fue usado por el planificador; el plan siguio con Seq Scan on detalle_pedido | Revertido (DROP INDEX) |

**Estado final de indices en foodstore_tp3_carga** (verificado con
`SELECT tablename, indexname FROM pg_indexes WHERE tablename IN
('pedido','producto','detalle_pedido')`): quedaron los 3 indices
originales de TP1 (idx_pedidos_cliente_id, idx_productos_categoria_activo,
idx_detalle_pedido_producto_id) mas las claves primarias, y un unico
indice nuevo — **idx_pedido_estado_fecha** — que fue el unico con
mejora real confirmada.

### Reflexion sobre las estimaciones de la IA

De las 4 propuestas, Kiro acerto la direccion en 3 de 4 (predijo mejora
grande para Q1 -> correcto; predijo mejora modesta para Q2 -> el signo
correcto era "no hay mejora", quedo cerca pero no exacto; marco como
incierto el indice 2 de Q3 -> correcto, nunca se uso). Donde mas se
desvio fue en Q3 indice 1: predijo mejora moderada sin anticipar la
perdida de paralelismo, que termino siendo el factor decisivo. Esto
confirma el criterio de la catedra: ninguna propuesta se aplico "porque
lo dijo la IA" — las 4 se midieron, y 3 de las 4 se revirtieron por no
sostenerse en el motor real.

**Parte 2 cerrada.**