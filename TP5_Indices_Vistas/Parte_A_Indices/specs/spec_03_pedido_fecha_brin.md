# spec: indice_pedido_fecha_brin

Objetivo: acelerar el filtro de fecha en la consulta de facturacion por
categoria (Q4 de queries.sql), sin repetir el error de TP3 (un indice
B-tree simple sobre fecha_hora ya empeoro un caso similar por perdida
de paralelismo).

Consulta afectada: Q4 completa (top 3 productos por facturacion por
categoria, ultimos 6 meses) -- ver queries.sql.

Frecuencia: reporte analitico mensual, con consultas exploratorias
ocasionales durante el cierre y la revision de ventas.

Filtro relevante en pedido:
  WHERE estado <> 'CANCELADO' AND fecha_hora >= now() - interval '6 months'
Selectividad real medida: retiene ~35.5% de las filas (23.655 de 66.668
examinadas por worker) -- mas selectivo que en Q5 (75%), pero con el
mismo riesgo estructural que en TP3-Q3 (selectividad ~33%, un indice
btree simple sobre fecha_hora empeoro el tiempo real por perdida de
paralelismo, ver TP3_Optimizacion/.../tabla_comparativa.md).

Columnas candidatas: fecha_hora (correlacionada con el orden fisico de
insercion, ya que se carga con generate_series creciente -- candidata
natural para BRIN en vez de B-tree).

Criterio de aceptacion inicial: comparar EXPLICITAMENTE dos tipos de
indice sobre la misma columna (B-tree vs BRIN), midiendo el tiempo real
de cada uno con EXPLAIN ANALYZE, en vez de asumir que B-tree es la unica
opcion. Si ambos empeoran o no cambian nada, documentar el descarte
igual -- no forzar un indice que no ayuda.

Nota posterior (tras medir): la hipotesis de arriba sobre la
correlacion de fecha_hora resulto ser INCORRECTA. Se verifico
directamente con pg_stats.correlation antes de crear el BRIN:

  SELECT correlation FROM pg_stats
  WHERE tablename = 'pedido' AND attname = 'fecha_hora';
  -> resultado real: 0.013024098 (practicamente nula)

fecha_hora en realidad se genero con random() en el seed masivo (ver
TP3), no correlacionada con el orden fisico de insercion como asumia
esta spec original. Se registro la correlacion y se midio igualmente el
BRIN dentro de una transaccion reversible para validar la hipotesis:
el plan mantuvo Seq Scan, no uso el BRIN y termino en 571.123 ms
(ver `plan_q4_brin.txt`). El candidato B-tree se midio por separado con
EXPLAIN ANALYZE y control de ruido. La decision final conserva el BRIN
descartado por sobreindexacion: la medicion confirma que no aporta una
mejora frente al B-tree.
