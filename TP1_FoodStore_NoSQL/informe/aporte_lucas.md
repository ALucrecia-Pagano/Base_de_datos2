# Aporte de Lucas — consulta a IA, contraste y conclusión

Borrador para integrar al PDF grupal, consignas 6 y 7 (secciones 4 y 5 del esquema). La conclusión está pendiente de revisión grupal. Detalle completo, pregunta exacta y límites: [contraste_ia.md](../docs/contraste_ia.md).

## 4. Consulta a IA y contraste de afirmaciones

**Consulta (consigna 6).** El 29/10/2026 se consultó a Gemini (modelo informado como Flash-Lite, sin comprobar por otro medio) en un chat nuevo. La pregunta describió el modelo relacional real (`pedido`, `detalle_pedido` con clave compuesta y precio unitario histórico, `cliente`, `producto`), la colección documental con cliente y líneas embebidos y `total` Decimal128, el acceso frecuente a pedidos completos y la necesidad de conservar la coherencia de cantidades y precios. La IA recomendó mantener PostgreSQL.

**Contraste (consigna 7).** Se seleccionaron dos afirmaciones de la respuesta.

| Afirmación de la IA | Fuente o prueba | Resultado |
|---|---|---|
| 1. En MongoDB la coherencia entre `subtotal`, `cantidad`, `precio` y `total` debe imponerla la aplicación o `$jsonSchema`, porque no valida dependencias cruzadas entre campos. | MongoDB Manual, *Specify Validation With Query Operators* (consultado el 29/10/2026) y prueba en MongoDB 9.0.4, en una colección de ensayo con documentos sintéticos: un validador `$expr` aceptó el pedido coherente y rechazó el de total incorrecto y el de subtotal incorrecto (código 121). | **Imprecisa.** MongoDB valida entre campos con `$expr`, pero la regla debe definirse y mantenerse. |
| 2. Las claves foráneas de PostgreSQL garantizan que un pedido no apunte a un cliente o producto inexistente. | Prueba en PostgreSQL 17.11 sobre la copia restaurada, con transacciones terminadas en `ROLLBACK`. | **Confirmada.** Se rechazaron cliente y producto inexistentes. Además se rechazaron `cantidad = 0` (`CHECK`) y la escritura manual del subtotal (columna generada); `pedido` no almacena `total`. |

**Límites.** Documentos sintéticos, una sola ejecución por motor, solo inserciones; el validador no está instalado en `foodstore_unidad7`; no se midió rendimiento.

## 5. Fundamentación tecnológica y conclusión

Conviene mantener PostgreSQL como base principal de pedidos, sin reemplazarlo por MongoDB para este subconjunto. Primer criterio, integridad y coherencia: en PostgreSQL el motor rechazó un pedido con cliente inexistente, una cantidad igual a cero y la escritura manual de un subtotal, que es una columna generada; además no almacena el total, por lo que no puede quedar desactualizado. MongoDB también puede validar reglas entre campos con $expr, como se comprobó en el laboratorio, pero esa regla debe definirse y mantenerse, y el modelo documental almacena total y subtotales derivados. Segundo criterio, atomicidad: MongoDB garantiza atomicidad por documento, y un pedido embebido es un solo documento; las operaciones que involucran varios documentos, como actualizar stock y pedido, requieren transacciones distribuidas, que la documentación oficial describe con mayor costo de rendimiento que una escritura de un solo documento. Con cinco pedidos no se midió rendimiento, por lo que la ventaja de leer un pedido completo en una sola lectura no está probada aquí. Si en el futuro esa lectura fuera un cuello de botella, convendría combinar: PostgreSQL como fuente de verdad y MongoDB solo como copia de lectura derivada.

**Evidencias:** [contraste_integridad_postgresql.sql](../postgresql/contraste_integridad_postgresql.sql) y su [salida](../evidencias/contraste_integridad_postgresql_salida.txt); [prueba_validacion_expr_mongodb.js](../mongodb/prueba_validacion_expr_mongodb.js) y su [salida](../evidencias/prueba_validacion_expr_salida.txt).

**Asistencia de IA:** consulta de la consigna 6 en Gemini; Claude (Anthropic) asistió en la selección de afirmaciones, la lectura de documentación, los scripts y la redacción. Lucas ejecutó los scripts y revisó los resultados.
