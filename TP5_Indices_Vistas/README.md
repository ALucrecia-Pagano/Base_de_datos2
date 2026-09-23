# TP5 — Índices, Vistas y Vistas Materializadas (Unidad 3, Semana 5)

Continúa el proyecto integrador **Food Store** sobre la base masiva
`foodstore_tp3_carga` (poblada en TP3, ~200.000 pedidos, 499.571
líneas de detalle).

## Estado actual

- **Parte A**: cinco casos documentados (Q2, Q4, Q5, Q6 + segundo
  descarte por sobreindexación), dos índices aceptados en firme
  (`idx_producto_categoria_precio_activo`, `idx_producto_categoria_precio`),
  y Q1/Q3 confirmadas sin necesidad de índice nuevo (Punto 7).
- **Parte B**: vistas, seguridad por roles con usuarios de prueba reales,
  y verificación ejecutable de equivalencia (`EXCEPT` + `count(*)`).
- **Parte C**: `mv_resumen_ventas_categoria_mes` con `WITH DATA`, índice único
  y medición documentada.

## Estructura

TP5_Indices_Vistas/
├── schema.sql                    # heredado de TP1, sin modificar
├── data.sql                      # referencia al script de carga de TP3
├── queries.sql                   # consultas reales de TP3/TP4
├── indices.sql                   # wrapper del entregable de la Parte A
├── views.sql                     # wrapper de las Partes B y C
├── specs/                        # indice de las especificaciones Kiro
├── duia.md                       # bitácora de uso de IA
├── informe_mediciones.md         # planes, escritura y materializada
├── README.md
├── Parte_A_Indices/
│   ├── indices.sql
│   ├── plan_q2_antes.txt                # Caso 5
│   ├── medir_q2_rondas.sql
│   ├── plan_q2_rondas_salida.txt
│   ├── plan_q4_antes.txt
│   ├── plan_q4_despues.txt
│   ├── plan_q4_brin.txt
│   ├── medir_brin_q4.sql
│   ├── plan_q4_rondas_salida.txt        # Punto 4: remedicion 3 rondas, DROP/CREATE real
│   ├── medir_q4_rondas.sql
│   ├── plan_q5_antes.txt
│   ├── plan_q5_despues_workmem.txt
│   ├── plan_q5_despues_indice_descartado.txt
│   ├── plan_q5_indice_redundante.txt    # Punto 5: segundo descarte por sobreindexacion
│   ├── medir_indice_redundante_q5.sql
│   ├── plan_q6_antes.txt
│   ├── plan_q6_despues.txt
│   ├── medir_escritura_detalle.sql
│   ├── medicion_escritura_detalle_salida.txt
│   ├── medir_escritura_indices_reales.sql        # Punto 6: costo real con indices aceptados
│   ├── medicion_escritura_indices_reales_salida.txt
│   ├── medir_q1_q3_actual.sql           # Punto 7: tercera consulta con cambio de plan
│   ├── plan_q1_q3_actual.txt
│   ├── plan_q3_sin_indice_btree.txt
│   └── specs/
├── Parte_B_Vistas/
│   ├── usuarios.sql
│   ├── usuarios_datos.sql               # Punto 2: usuarios de prueba (matchean con clientes reales)
│   ├── vistas.sql
│   ├── seguridad_roles.sql
│   ├── evidencia_grant_punto1.txt       # Punto 1: verificacion real del GRANT corregido
│   ├── verificacion_equivalencia.sql
│   ├── verificacion_equivalencia_salida.txt
│   ├── verificacion_vistas.sql
│   ├── verificacion_vistas_salida.txt
│   └── specs/
└── Parte_C_Vista_Materializada/
    ├── vista_materializada.sql
    ├── README.md
    └── specs/

## Cómo reproducir las pruebas de la Parte A

### 1. Confirmar que la base existe y tiene el volumen esperado

```bash
psql -U postgres -d foodstore_tp3_carga -c "SELECT count(*) FROM detalle_pedido;"
```

Si no existe, recrearla desde TP3:
```bash
createdb -U postgres -T foodstore_dev foodstore_tp3_carga
psql -U postgres -d foodstore_tp3_carga -f "../TP3_Optimizacion/Parte 1 - Poblar la base masivamente con datos generados por IA/seed_masivo.sql"
```

### 2. Medir un plan "antes" de cualquiera de los 3 casos

```bash
psql -U postgres -d foodstore_tp3_carga -c "EXPLAIN ANALYZE <consulta de queries.sql>"
```

### 3. Probar un índice sin aplicarlo en firme (dentro de transacción reversible)

```bash
psql -U postgres -d foodstore_tp3_carga -c "
BEGIN;
CREATE INDEX ...;
ANALYZE <tabla>;
EXPLAIN ANALYZE <consulta>;
ROLLBACK;
"
```

### 4. Estado real de índices aplicados en firme sobre `foodstore_tp3_carga`

**Dos** de los candidatos probados en la Parte A quedan aplicados en
firme (ver `indices.sql` y `duia.md` para el detalle completo de por
qué se aceptaron y por qué los demás se descartaron):

```sql
-- Caso 2 (Q6): covering index parcial, mejora final ~41% real (271.2s -> 158.7s tras
-- VACUUM ANALYZE; medicion inicial fue ~19%)
CREATE INDEX idx_producto_categoria_precio_activo
    ON producto (id_categoria, precio_lista DESC)
    WHERE activo = TRUE;

-- Caso 5 (Q2): sin condicion parcial (Q2 no filtra por activo), aceptado
-- tras remedicion con 3 rondas (~37% real), plan Seq Scan -> Bitmap Heap Scan
CREATE INDEX idx_producto_categoria_precio ON producto (id_categoria, precio_lista);
```

`idx_pedido_fecha_hora_btree` (Caso 3, Q4) tuvo un historial de idas y
vueltas: descartado por corrida única → aceptado por una medición de 3
rondas que nunca se archivó → **descartado de nuevo** (auditoría
2026-09-23) tras remedir con salida real archivada
(`Parte_A_Indices/plan_q4_rondas_salida.txt`): la dirección resultó
inconsistente entre rondas y el promedio final es levemente peor con
el índice, por pérdida de paralelismo (y además perjudicaba a Q3, ver
Punto 7). Queda comentado en `indices.sql`. **Eliminado en firme**:
`DROP INDEX idx_pedido_fecha_hora_btree` + `ANALYZE pedido` ejecutados,
verificado con `pg_indexes` que ya no existe.

Para verificar qué índices existen realmente en la base:
```bash
psql -U postgres -d foodstore_tp3_carga -c "SELECT tablename, indexname FROM pg_indexes WHERE schemaname='public' ORDER BY tablename;"
```

### 5. Segundo descarte por sobreindexación (índice redundante con la PK)

```bash
psql -U postgres -d foodstore_tp3_carga -f Parte_A_Indices/medir_indice_redundante_q5.sql
```

Crea `idx_detalle_pedido_id_pedido` dentro de `BEGIN...ROLLBACK`, mide
Q5 con y sin el candidato, y confirma que el plan es idéntico en ambos
casos (`pk_detalle_pedido` ya cubre `id_pedido` como su primera
columna). Salida en `plan_q5_indice_redundante.txt`.

### 6. Remedición de Q4 con salida archivada (Caso 3)

```bash
psql -U postgres -d foodstore_tp3_carga -f Parte_A_Indices/medir_q4_rondas.sql
```

`DROP`/`CREATE` real de `idx_pedido_fecha_hora_btree` dentro de
transacciones, 3 rondas intercaladas, `EXPLAIN (ANALYZE, BUFFERS)`.
Requiere respaldo previo (el script hace DDL real, no solo prueba
reversible de lectura). Salida en `plan_q4_rondas_salida.txt`.

### 7. Costo de escritura con los índices realmente aceptados

```bash
psql -U postgres -d foodstore_tp3_carga -f Parte_A_Indices/medir_escritura_indices_reales.sql
```

3 rondas de `INSERT` en `producto`, `DROP`/`CREATE` real de
`idx_producto_categoria_precio_activo`, `\timing`. Salida en
`medicion_escritura_indices_reales_salida.txt`. Requiere respaldo
previo (DDL real sobre un índice aplicado en firme).

### 8. Tercera consulta con cambio de plan real (Q1 y Q3)

```bash
psql -U postgres -d foodstore_tp3_carga -f Parte_A_Indices/medir_q1_q3_actual.sql
```

Mide el plan actual de Q1 y Q3. Salida en `plan_q1_q3_actual.txt`. Para
ver a Q3 sin `idx_pedido_fecha_hora_btree` (estado post Caso 3), correr
manualmente dentro de `BEGIN...DROP INDEX...ROLLBACK` — ver
`plan_q3_sin_indice_btree.txt` para la salida ya archivada.

### 9. Caso 5 — Q2 (productos de una categoría en un rango de precio)

```bash
psql -U postgres -d foodstore_tp3_carga -f Parte_A_Indices/medir_q2_rondas.sql
```

3 rondas intercaladas dentro de `BEGIN...ROLLBACK` del candidato
`idx_producto_categoria_precio (id_categoria, precio_lista)`, sin
condición parcial (los índices parciales existentes sobre `producto`
no aplican porque Q2 no filtra por `activo`). Salida en
`plan_q2_rondas_salida.txt`. Aceptado y aplicado en firme.

## Flujo de trabajo con IA

El repositorio conserva las specs de Kiro junto a cada parte. Los scripts
reversibles de medicion y equivalencia son los artefactos ejecutables que
permiten verificar el resultado sin depender de una afirmacion en la DUIA.
La DUIA identifica la herramienta usada en cada parte; en particular, la
vista materializada fue generada con GitHub Copilot y no debe presentarse
como generada por OpenCode.

## Cómo reproducir/verificar Parte B

```bash
psql -U postgres -d foodstore_tp3_carga -f Parte_B_Vistas/usuarios.sql
psql -U postgres -d foodstore_tp3_carga -f Parte_B_Vistas/usuarios_datos.sql
psql -U postgres -d foodstore_tp3_carga -f Parte_B_Vistas/vistas.sql
psql -U postgres -d foodstore_tp3_carga -f Parte_B_Vistas/seguridad_roles.sql
psql -U postgres -d foodstore_tp3_carga -f Parte_B_Vistas/verificacion_vistas.sql
```

`usuarios_datos.sql` (Punto 2 de la auditoría) agrega 5 usuarios de
prueba con mails que matchean clientes reales existentes, uno sin
cliente asociado y uno eliminado — sin esto, `v_pedido_usuario` y
`v_usuario_publico` se verifican contra una tabla casi vacía y no
prueban nada. Ejecutarlo **antes** de `vistas.sql`, ya que `views.sql`
(el wrapper de la raíz) ya respeta este orden.

El último script muestra las columnas de `v_usuario_publico` sin
`contrasena`, ejecuta `verificacion_equivalencia.sql` (que ahora
también compara `count(*)` vista vs. manual, no solo `EXCEPT`) y falla
si alguna vista devuelve diferencias o conteos distintos. La salida
final debe mostrar `diferencias = 0` y `conteo_vista = conteo_manual`
para cada vista. La consulta de acceso directo a `usuario` se prueba
por separado bajo `SET ROLE` y debe fallar por falta de privilegios —
y ahora también se verifica que `mv_resumen_ventas_categoria_mes` y
`v_pedido_usuario` se puedan leer con ese rol (`evidencia_grant_punto1.txt`).

### Medir escritura en `detalle_pedido`

Sobre una base de trabajo autorizada, ejecutar:

```bash
psql -U postgres -d foodstore_tp3_carga -f Parte_A_Indices/medir_escritura_detalle.sql
```

El script construye una muestra de 500 pares válidos, mide la inserción
dentro de transacciones con y sin un índice de prueba sobre
`detalle_pedido(cantidad)`, y elimina ese índice al finalizar. Registrar
las dos salidas de `\timing` en `informe_mediciones.md`; no reutilizar la
medición anterior sobre `producto` como evidencia de esta prueba.

## Cómo reproducir Parte C

```bash
psql -U postgres -d foodstore_tp3_carga -f Parte_C_Vista_Materializada/vista_materializada.sql
```

Para comparar tiempos, correr `EXPLAIN ANALYZE` de la consulta base
(ver `Parte_C_Vista_Materializada/README.md`) contra
`SELECT * FROM mv_resumen_ventas_categoria_mes;`.