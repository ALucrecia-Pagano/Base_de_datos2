# Contraste de IA — consignas 6 y 7

Responsable: Lucas Ávila. Referencias: [plan](plan_trabajo.md) y [reglas](../../AGENTS.md). Revisión grupal de la conclusión pendiente.

## Registro de la asistencia de IA

- **Consulta de la consigna 6:** Gemini, modelo informado por Lucas como Flash-Lite (no comprobado por otro medio), el 29/10/2026. Se usó un chat nuevo, sin contexto previo.
- **Asistencia en la preparación:** Claude (Anthropic) ayudó a Lucas a redactar la pregunta, a elegir las dos afirmaciones a contrastar, a leer la documentación oficial y a preparar los scripts de laboratorio (PostgreSQL y MongoDB) y este texto. Lucas ejecutó el script en su equipo y revisó cada resultado. Claude no tuvo acceso a ningún motor de bases de datos.
- La respuesta completa de Gemini se conserva en el historial de Lucas; aquí se reproducen solo los fragmentos pertinentes.

## Consigna 6 — consulta a la IA

**Pregunta enviada (texto exacto):**

> Soy estudiante de una tecnicatura en programación y trabajo con un proyecto llamado Food Store (tienda de comida). Necesito comparar PostgreSQL y MongoDB respecto del almacenamiento y la consulta de pedidos.
>
> Modelo actual en PostgreSQL: tablas pedido (id, fecha_hora, forma_pago, estado, id_cliente con clave foránea a cliente), detalle_pedido (clave primaria compuesta id_pedido + id_producto, con cantidad y precio_unitario histórico, claves foráneas a pedido y producto), cliente y producto.
>
> Alternativa en MongoDB: una colección pedidos con un documento por pedido, que embebe un objeto cliente (id y alias) y un arreglo lineas (id_producto, nombre_producto, cantidad, precio_unitario, subtotal), más el campo total (Decimal128).
>
> Contexto de uso: se consultan con mucha frecuencia pedidos completos (cabecera, cliente y líneas juntos) y es imprescindible conservar la coherencia de cantidades y precios (subtotal = cantidad × precio, total = suma de subtotales).
>
> Compará ambos motores para este caso: almacenamiento, consulta de un pedido completo, integridad y coherencia de cantidades y precios. Al final recomendá si conviene mantener PostgreSQL, usar MongoDB para este subconjunto o combinar ambos. Respondé en español, en un máximo de 400 palabras, y enunciá cada afirmación técnica de forma concreta y verificable.

**Respuesta pertinente (resumen fiel):** Gemini describió PostgreSQL como un modelo normalizado con `precio_unitario` histórico y MongoDB como un documento que embebe cliente y líneas, con redundancia. Afirmó que recuperar un pedido completo en MongoDB requiere una sola lectura y en PostgreSQL varios `JOIN`. Recomendó mantener PostgreSQL y, si la lectura fuera un cuello de botella, usar `json_agg` o una vista materializada. Las dos afirmaciones contrastadas son las siguientes.

## Afirmación 1 — validación entre campos en MongoDB

- **Afirmación de la IA (textual):** en MongoDB, «la coherencia matemática (`subtotal = cantidad × precio` y `total = suma de subtotales`) debe ser impuesta estrictamente por la lógica de la aplicación o mediante validadores de esquema (`$jsonSchema`), ya que MongoDB no valida dependencias cruzadas entre campos internos de forma automática».
- **Fuente oficial:** MongoDB Manual, [Specify Validation With Query Operators](https://www.mongodb.com/docs/manual/core/schema-validation/specify-query-expression-rules/) (manual vigente, que el selector de versión muestra como 9.0), consultada el 29/10/2026.
- **Contraste:** la página indica que se pueden usar operadores de consulta como `$eq` y `$gt` para comparar campos, y que un uso habitual es crear reglas dinámicas que comparan varios campos a la vez. Su ejemplo define un validador con `$expr` que exige `totalWithVAT = total × (1 + VAT)` y rechaza con «Document failed validation» el documento que no cumple. Por lo tanto, **la afirmación es imprecisa**: existe validación entre campos dentro del mismo documento, mediante `$expr`, aunque `$jsonSchema` por sí solo no la expresa. No se permiten `$expr` con `$function`, `$near`, `$nearSphere`, `$text` ni `$where`.
- **Procedimiento (laboratorio, ejecutado por Lucas el 29/10/2026):** [prueba_validacion_expr_mongodb.js](../mongodb/prueba_validacion_expr_mongodb.js), ejecutado con `mongosh` 2.14.1 sobre MongoDB Server 9.0.4, instalado en el equipo de Lucas. Crea una colección de ensayo, `pedidos_validados`, en una base propia (`prueba_validacion_lucas`), con un validador `$expr` que exige dos reglas: `total` igual a la suma de los subtotales de `lineas`, y cada subtotal igual a `cantidad × precio_unitario`. Usa documentos sintéticos con los mismos tipos del modelo (Long, Int32 y Decimal128) y no toca `foodstore_unidad7`. Salida: [prueba_validacion_expr_salida.txt](../evidencias/prueba_validacion_expr_salida.txt).
- **Resultados observados:**

| Pedido de ensayo | Resultado |
|---|---|
| A. Subtotales y total correctos | Aceptado |
| B. Total 2900.00 con subtotales correctos (suma 2800.00) | Rechazado: código 121, «Document failed validation» |
| C. Subtotal 1999.00 en una línea (2 × 1000.00) y total igual a la suma de subtotales | Rechazado: código 121, «Document failed validation» |

- **Contraste adicional:** la prueba confirma lo que indica la documentación y lo extiende a las reglas de Food Store: MongoDB rechazó los pedidos incoherentes mediante `$expr` sobre el arreglo `lineas`. **La afirmación es, por lo tanto, imprecisa**, aunque tiene parte de razón: la regla no existe por defecto, hay que definirla en la colección y mantenerla.
- **Límites:** documentos sintéticos y una sola ejecución en el equipo de Lucas. El validador se probó en una colección de ensayo; no está instalado en `foodstore_unidad7`, donde, según la documentación del repositorio, no hay validadores permanentes. Se probaron inserciones, no actualizaciones de documentos existentes.

## Afirmación 2 — integridad en PostgreSQL

- **Afirmación de la IA (textual):** PostgreSQL «ofrece garantías ACID estrictas mediante restricciones de clave foránea (`FOREIGN KEY`), garantizando que un pedido no pueda apuntar a un cliente o producto inexistente».
- **Procedimiento (laboratorio, ejecutado por Lucas el 29/10/2026):** [contraste_integridad_postgresql.sql](../postgresql/contraste_integridad_postgresql.sql), ejecutado con `psql` sobre PostgreSQL 17.11 en la copia descartable `foodstore_restore_test`, restaurada desde un respaldo de `foodstore_dev` (TP8). Cada prueba corre dentro de `BEGIN ... ROLLBACK`. Salida: [contraste_integridad_postgresql_salida.txt](../evidencias/contraste_integridad_postgresql_salida.txt).
- **Resultados observados:**

| Prueba | Resultado |
|---|---|
| Pedido con `id_cliente = 999999` (inexistente) | Rechazado: viola la clave foránea `fk_pedido_cliente` |
| Escribir un `subtotal` a mano | Rechazado: `subtotal` es una columna generada (`cantidad * precio_unitario`) |
| Línea con `cantidad = 0` | Rechazada: viola `chk_detalle_cantidad_positiva` |
| Línea con `id_producto = 999999` (inexistente) | Rechazada: viola la clave foránea `fk_detalle_pedido_producto` |
| Línea válida (2 × 100.00) | Aceptada, subtotal calculado por el motor: 200.00 |
| Conteos antes y después | 5 pedidos y 7 líneas en ambos momentos; nada quedó guardado |

- **Contraste:** **la afirmación se confirma tanto para el cliente como para el producto.** El laboratorio mostró además algo que la IA no mencionó, porque no conocía el esquema real: PostgreSQL también impone `CHECK` sobre cantidades y calcula el subtotal con una columna generada. Además, la tabla `pedido` no tiene columna `total`, de modo que el total se obtiene sumando los subtotales y no puede quedar desactualizado. En el modelo documental propuesto, en cambio, `total` y `subtotal` se almacenan.
- **Límites:** una sola ejecución, sobre una copia con 5 pedidos y 7 líneas, en el equipo de Lucas. Solo prueba el comportamiento de PostgreSQL 17.11 con este esquema. No es una medición de rendimiento.

## Aporte al informe — conclusión (188 palabras)

Conviene mantener PostgreSQL como base principal de pedidos, sin reemplazarlo por MongoDB para este subconjunto. Primer criterio, integridad y coherencia: en PostgreSQL el motor rechazó un pedido con cliente inexistente, una cantidad igual a cero y la escritura manual de un subtotal, que es una columna generada; además no almacena el total, por lo que no puede quedar desactualizado. MongoDB también puede validar reglas entre campos con $expr, como se comprobó en el laboratorio, pero esa regla debe definirse y mantenerse, y el modelo documental almacena total y subtotales derivados. Segundo criterio, atomicidad: MongoDB garantiza atomicidad por documento, y un pedido embebido es un solo documento; las operaciones que involucran varios documentos, como actualizar stock y pedido, requieren transacciones distribuidas, que la documentación oficial describe con mayor costo de rendimiento que una escritura de un solo documento. Con cinco pedidos no se midió rendimiento, por lo que la ventaja de leer un pedido completo en una sola lectura no está probada aquí. Si en el futuro esa lectura fuera un cuello de botella, convendría combinar: PostgreSQL como fuente de verdad y MongoDB solo como copia de lectura derivada.

## Distinción entre propuesta, ejecución y verificación

- **Propuesta de IA:** la comparación y la recomendación de Gemini.
- **Verificado con documentación oficial:** el mecanismo `$expr` en validadores de MongoDB y la atomicidad por documento (MongoDB Manual, [Atomicity and Transactions](https://www.mongodb.com/docs/manual/core/write-operations-atomicity/), consultado el 29/10/2026).
- **Ejecutado y verificado en laboratorio:** el comportamiento de las restricciones de PostgreSQL 17.11 (afirmación 2) y el de un validador `$expr` en MongoDB 9.0.4 sobre una colección de ensayo con documentos sintéticos (afirmación 1).
- **No ejecutado ni medido:** el rendimiento de ambos motores, la aplicación del validador a la colección migrada `foodstore_unidad7.pedidos` y su comportamiento en actualizaciones.
