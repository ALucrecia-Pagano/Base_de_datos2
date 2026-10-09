# TP6 — FNBC y desnormalización controlada
## Parte 2 — Top diario de categorías

### 1. Objetivo y adaptación a FoodStore

La consigna solicita mostrar el top cinco de categorías por monto vendido en el día, con actualización frecuente y datos disponibles en tiempo real.

La consulta normalizada se adaptó a los nombres reales del esquema:

| Nombre de la consigna | Nombre en FoodStore |
|---|---|
| `dp.producto_id` | `dp.id_producto` |
| `dp.pedido_id` | `dp.id_pedido` |
| `pr.categoria_id` | `pr.id_categoria` |
| `ped.fecha` | `ped.fecha_hora`, de tipo TIMESTAMPTZ |

Se utilizó el **25 de junio de 2026**, en la zona horaria **America/Buenos_Aires**, como fecha histórica reproducible. Sustituye a `CURRENT_DATE` porque la carga no contiene pedidos de hoy. El filtro utiliza un intervalo semiabierto: incluye las 00:00 del día elegido y excluye las 00:00 del día siguiente.

Se conservaron `SUM(dp.subtotal)`, `GROUP BY c.nombre`, orden descendente por monto y `LIMIT 5`. Como `pedido` y `detalle_pedido` no tienen columnas `eliminado`, se omitieron ambos filtros y se consideran todos los registros existentes del día. No se agregaron filtros por estado ni por `activo`; `CANCELADO` no se interpreta como eliminado.

### 2. Volumen y alcance del ensayo

La copia de trabajo contiene:

| Tabla | Filas |
|---|---:|
| pedido | 200005 |
| detalle_pedido | 499571 |
| producto | 50003 |
| categoria | 2 |

El límite de cinco se conserva, pero el resultado tiene solo dos categorías. Por ello, el ensayo permite evaluar los recorridos sobre pedidos, detalles y productos, aunque no representa un escenario con muchas categorías ni permite evaluar ampliamente la selección de un top cinco entre numerosos grupos.

La comprobación previa de la copia informó 5132 detalles cuya cantidad supera el stock actual y ningún trigger de usuario instalado en pedido, detalle_pedido o producto. Los scripts de TP2 presentes en el repositorio no equivalen a triggers instalados en esta base. La adaptación no corrige cantidades ni stock y no instala esas reglas anteriores.

### 3. Medición inicial

La evidencia `evidencia_top_antes_20261008_225517.txt` registra:

- **Execution Time:** 47.151 ms.
- **Buffers:** `shared hit=8455`.
- Recorrido `Parallel Seq Scan` sobre pedido.
- Búsquedas mediante `Nested Loop` hacia detalle_pedido y producto.
- 1539 búsquedas en producto, con 4617 buffers compartidos encontrados en caché.

Esta medición permitió identificar los recorridos que se buscaba evitar. Se conserva como referencia inicial, pero **no se utiliza para calcular la mejora de la comparación directa**, realizada después de la carga e indexación.

### 4. Justificación del patrón elegido

Se eligieron columnas precalculadas con disparadores porque el plan inicial mostraba un recorrido de pedido y búsquedas repetidas en producto que podían evitarse copiando sus atributos de consulta al detalle; además, la sincronización dentro de la misma transacción permite mantener los datos vigentes al confirmar cada escritura, sin esperar un refresco periódico. Una vista materializada con actualización nocturna no satisface el requisito de actualización frecuente, y un refresco frecuente exigiría aceptar y medir una demora entre cambios y consultas. La adaptación es reversible porque conserva los atributos originales y permite retirar únicamente las columnas, el índice y los mecanismos de sincronización añadidos.

### 5. Estructura redundante y sincronización

El script `tp_desnormalizacion_top_categorias.sql` agrega a detalle_pedido:

| Columna | Tipo | Fuente original |
|---|---|---|
| fecha_hora_pedido_cache | TIMESTAMPTZ | pedido.fecha_hora |
| id_categoria_cache | BIGINT | producto.id_categoria |

Ambas columnas son obligatorias después de la carga inicial. La categoría copiada tiene una FK hacia categoria. El índice `idx_tp6_detalle_fecha_cache` se crea sobre fecha_hora_pedido_cache para permitir la búsqueda diaria directamente en detalle_pedido.

Las copias representan los valores actuales de las tablas originales, no datos históricos congelados. Se conserva subtotal, que ya es generado como cantidad por precio unitario. El nombre de categoría no se copia: la consulta mantiene un JOIN con categoria para mostrar su nombre vigente.

Los disparadores funcionan de la siguiente manera:

- **BEFORE INSERT OR UPDATE de detalle:** obtiene la fecha del pedido y la categoría del producto y recalcula ambas copias, incluso si se intenta escribir un valor arbitrario en ellas.
- **AFTER UPDATE de pedido:** cuando cambia fecha_hora, propaga la nueva fecha a sus detalles.
- **AFTER UPDATE de producto:** cuando cambia id_categoria, propaga la nueva categoría a sus detalles.

Eliminar un detalle elimina también sus copias. La eliminación de un pedido conserva el CASCADE existente hacia sus detalles. Cambiar el nombre de una categoría no requiere propagación porque se consulta mediante JOIN.

La carga inicial completó las dos columnas para **499571 detalles**. No se sobrescribieron funciones, triggers, columnas o índices existentes.

### 6. Condiciones de comparación

Ambas consultas se midieron después de completar la carga inicial, crear el índice y ejecutar ANALYZE. Primero se consultaron sus resultados para calentar ambos recorridos. Después se realizaron dos rondas:

1. Normalizada y luego desnormalizada.
2. Desnormalizada y luego normalizada.

Las vistas temporales utilizadas para repetir las consultas son vistas normales que el planificador expande; no son vistas materializadas ni almacenan resultados precalculados.

### 7. Resultados de rendimiento

La evidencia `evidencia_top_desnormalizacion_20261008_232126.txt` registra:

| Medición | Normalizada: tiempo (ms) | Desnormalizada: tiempo (ms) | Normalizada: shared hit | Desnormalizada: shared hit |
|---|---:|---:|---:|---:|
| Ronda 1 | 42.807 | 1.855 | 10942 | 564 |
| Ronda 2 | 41.920 | 1.815 | 10942 | 564 |
| Promedio | 42.3635 | 1.835 | 10942 | 564 |

| Antes: normalizada | Después: desnormalizada |
|---|---|
| Promedio: 42.3635 ms | Promedio: 1.835 ms |
| shared hit: 10942 | shared hit: 564 |
| Trabajo principal: Parallel Seq Scan de pedido y Nested Loop con búsquedas en detalle/producto | Trabajo principal: Bitmap Heap Scan de detalle mediante el índice de fecha y Nested Loop con categoria |

El cociente entre los tiempos promedio es aproximadamente **23.09**. La reducción del tiempo de ejecución observada es de aproximadamente **95.67 %**, y la reducción de accesos a buffers compartidos es de aproximadamente **94.85 %**.

Estos resultados corresponden al **conjunto columnas redundantes más índice**. El ensayo no separa el aporte individual de cada componente. Los 47.151 ms iniciales no intervienen en estos cálculos.

Los valores `shared hit` representan accesos resueltos en caché compartida; no equivalen a páginas únicas ni a lecturas físicas de disco.

### 8. Interpretación de los planes

**Consulta normalizada.** Mantiene el recorrido secuencial paralelo de pedido para filtrar la fecha. Para los 588 pedidos del día realiza búsquedas por la PK de detalle_pedido y luego 1539 búsquedas por la PK de producto. En ambas rondas, pedido utiliza 1472 buffers, las búsquedas de detalle 4844 y las de producto 4617. Finalmente se incorpora categoria mediante Hash Join y se realiza agregación parcial, Gather Merge y agregación final. El recorrido y las búsquedas repetidas constituyen el trabajo principal; el ordenamiento final procesa solamente dos grupos. Los tiempos de los nodos son inclusivos y no deben sumarse como costos independientes.

**Consulta desnormalizada.** Utiliza Bitmap Index Scan sobre el índice de fecha y Bitmap Heap Scan para obtener los 1539 detalles visibles del día, accediendo a 558 bloques de tabla. Después combina esos detalles con las dos categorías mediante Nested Loop, reutilizando el conjunto de detalles con un nodo Materialize, y realiza GroupAggregate y el ordenamiento final. Ese Materialize es un nodo de ejecución, no una vista materializada. Desaparecen tanto el recorrido de pedido como las búsquedas individuales en producto. El acceso por fecha a detalle_pedido pasa a ser el recorrido principal.

### 9. Equivalencia, auditoría y pruebas

Ambas consultas devolvieron los mismos resultados:

| categoria | total_vendido |
|---|---:|
| Bebidas | 5589534.40 |
| Pizzas | 5215387.22 |

La comparación con EXCEPT en ambos sentidos produjo cero filas. No hubo categorías o montos presentes en un resultado y ausentes en el otro.

La auditoría completa comparó las columnas redundantes de todos los detalles contra pedido.fecha_hora y producto.id_categoria, utilizando `IS DISTINCT FROM`. También verificó la existencia de sus padres y de la categoría copiada. Tanto la auditoría inicial como la posterior a las pruebas devolvieron **cero filas**, y sus aserciones finalizaron sin error.

Las pruebas secuenciales verificaron inserción de detalles, modificación de cantidad y precio, corrección de copias arbitrarias, cambio de pedido y producto asociados, propagación de fecha, propagación de categoría, cambio de nombre de categoría, eliminación directa y eliminación mediante CASCADE del pedido.

Se utilizaron IDs negativos explícitos con `OVERRIDING SYSTEM VALUE`, sin consumir secuencias. Las filas de prueba se deshicieron mediante `ROLLBACK TO SAVEPOINT` antes de medir. La evidencia registra que las pruebas secuenciales fueron superadas; **no fueron pruebas concurrentes**.

### 10. Costos de escritura y límites

La adaptación aumenta el tamaño de los detalles y agrega búsquedas de padres, bloqueos de filas y mantenimiento del índice durante las escrituras. Cambiar la fecha de un pedido o la categoría de un producto puede actualizar numerosos detalles, generando más versiones de filas, WAL y trabajo posterior de mantenimiento. El costo de escritura no fue cuantificado por estas mediciones de lectura.

La sincronización soporta **READ COMMITTED**. Sus funciones rechazan otros niveles cuando se ejecutan. El disparador de detalle toma bloqueos FOR SHARE sobre el pedido y luego sobre el producto para proteger los atributos que copia. Los bloqueos de padres y detalles pueden producir interbloqueos; la transacción abortada deberá reintentarse completa. La corrección ante carreras entre sesiones aún requiere pruebas concurrentes.

La instalación, carga inicial y medición se realizaron dentro de una misma transacción, manteniendo bloqueos ACCESS EXCLUSIVE que impiden escrituras y lecturas concurrentes sobre las tablas bloqueadas. Esto corresponde a un ensayo de laboratorio, no a una instalación en línea.

La carga inicial genera versiones de filas y modifica el estado físico de la tabla. No se ejecutó VACUUM dentro de la transacción. Aunque ambas consultas se compararon bajo el mismo estado y con orden alternado, dos rondas no constituyen un benchmark exhaustivo ni garantizan los mismos tiempos bajo carga concurrente o después de mantenimiento.

### 11. Reversibilidad y cierre

La información original permanece en pedido, producto, categoria y detalle_pedido. Una reversión posterior podría retirar los triggers y funciones TP6, el índice, la FK añadida y las dos columnas cache, y volver a la consulta normalizada sin perder información original.

En este ensayo, el script terminó con **ROLLBACK**, registrado en la evidencia. Por tanto, la instalación de columnas, índice y sincronización **no quedó persistida**.
