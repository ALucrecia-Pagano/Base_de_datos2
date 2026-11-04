# Verificación de la guía del README desde cero — Lucas Ávila

Fecha: 03/11/2026, 17:13 a 17:16 (hora de Mendoza).
Equipo: PC con Windows, SQLite CLI 3.54.1 (2026-10-16), ejecutado desde el Símbolo del sistema en la raíz del repositorio, sobre la rama `lucas/tp8-spec-bitacora`.

Se siguió la guía del README (pasos 2, 3 y 5) sobre una base nueva y vacía, fuera del repositorio (`%TEMP%\prueba_readme.db`). No se tocó PostgreSQL ni MongoDB. La guía fue indicada paso a paso por Claude (Anthropic); cada comando lo ejecutó Lucas.

## Comandos ejecutados

```text
sqlite3 "%TEMP%\prueba_readme.db"
.read TP8_Unidad8\movil\schema_sqlite.sql
.mode csv
.import --csv --skip 1 TP8_Unidad8\movil\servidor_snapshot.csv snapshot_servidor_import
.read TP8_Unidad8\movil\importar_snapshot.sql
SELECT id, precio_centavos, stock, disponible, eliminado FROM snapshot_servidor;
.read TP8_Unidad8\movil\casos_2c.sql
```

## Salida observada

Instantánea importada (3 productos, booleanos `t/f` convertidos a `1/0`):

```text
1,105000,50,1,0
2,150000,35,1,0
3,80000,100,1,0
```

Ejecución de `casos_2c.sql` (las primeras dos listas son parciales: `semaforo.sql` termina con un `SELECT`):

```text
c2-solicitud-1,c2-original,CONFLICTO,"Cambió el precio observado"
c3-solicitud,c3-stock,RECHAZADO,"Stock insuficiente"
c4-solicitud,c4-baja,RECHAZADO,"Producto dado de baja"
c5-solicitud,c5-sin-cambios,SIMULADO_APROBADO,"Precio, disponibilidad y stock coinciden"
c2-solicitud-1,c2-original,CONFLICTO,"Cambió el precio observado"
c2-solicitud-2,c2-aceptado,SIMULADO_APROBADO,"Precio, disponibilidad y stock coinciden"
c3-solicitud,c3-stock,RECHAZADO,"Stock insuficiente"
c4-solicitud,c4-baja,RECHAZADO,"Producto dado de baja"
c5-solicitud,c5-sin-cambios,SIMULADO_APROBADO,"Precio, disponibilidad y stock coinciden"
Error near line 68 of TP8_Unidad8\movil\casos_2c.sql: UNIQUE constraint failed: cola_sync.solicitud_uuid
c2-solicitud-1,CONFLICTO,"Cambió el precio observado"
c2-solicitud-2,SIMULADO_APROBADO,"Precio, disponibilidad y stock coinciden"
c3-solicitud,RECHAZADO,"Stock insuficiente"
c4-solicitud,RECHAZADO,"Producto dado de baja"
c5-solicitud,SIMULADO_APROBADO,"Precio, disponibilidad y stock coinciden"
```

## Lectura

| Caso | Requisito | Resultado |
|---|---|---|
| C2 | REQ-01 | `CONFLICTO` por cambio de precio; la solicitud nueva con el precio aceptado queda `SIMULADO_APROBADO` |
| C3 | REQ-02 | `RECHAZADO`, stock insuficiente |
| C4 | REQ-03 | `RECHAZADO`, producto dado de baja |
| C5 | — | `SIMULADO_APROBADO`, sin cambios |
| C6 | REQ-04 | error `UNIQUE constraint failed: cola_sync.solicitud_uuid`; los cinco estados anteriores no cambian |

`SIMULADO_APROBADO` no es una venta: la tablet no modifica stock ni precio del servidor.

## Límites

- Solo se verificó la parte SQLite (pasos 2, 3 y 5). El paso 1 (exportar desde PostgreSQL) y la consulta de "pedidos y stock no cambiaron" de la consigna 2.c no se ejecutaron en esta prueba.
- Esta ejecución usó el `semaforo.sql` actual del repositorio, por lo que sirve de evidencia para la reejecución pendiente indicada en `resultado_semaforo_2b.md` solo en lo que respecta a C2 a C6. El camino verde simple de 2.b con idempotencia sigue documentado en ese archivo.
