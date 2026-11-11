# Implementation Plan: Food Store — Semáforo de Sincronización Offline

## Overview

El sistema de sincronización offline de la tablet (Food Store en feria) está
**completamente implementado**. Este documento registra retrospectivamente las
tareas de codificación que constituyeron la construcción del sistema, con todos
los ítems marcados como completados.

Los cuatro archivos SQL que componen el sistema son:

| Archivo | Rol |
|---|---|
| `movil/schema_sqlite.sql` | Esquema SQLite con 6 tablas y restricciones |
| `movil/importar_snapshot.sql` | Importación del CSV del servidor a SQLite |
| `movil/semaforo.sql` | Evaluador offline con tabla temporal y UPDATE |
| `movil/casos_2c.sql` | Script de pruebas de integración C2–C6 |

## Tasks

- [x] 1. Definir el esquema de la base de datos SQLite
  - [x] 1.1 Crear las tablas de caché y snapshot del servidor
    - Implementar `producto_cache` con restricciones CHECK y modo STRICT
    - Implementar `snapshot_servidor` con restricciones CHECK y modo STRICT
    - Implementar `snapshot_servidor_import` como staging de CSV (booleanos como `t`/`f`)
    - _Requirements: 4.1 (unicidad de UUID), 2.1, 3.1_

  - [x] 1.2 Crear las tablas de pedido y cola de sincronización
    - Implementar `pedido_borrador` con PK `id_local` y CHECK en `forma_pago`
    - Implementar `item_borrador` con PK compuesta `(id_local, producto_id)` y FK a `pedido_borrador` y `producto_cache`
    - Implementar `cola_sync` con `solicitud_uuid TEXT PRIMARY KEY` (garantía de unicidad por motor), CHECK de estados válidos y FK a `pedido_borrador`
    - _Requirements: 4.1_

- [x] 2. Implementar la importación de la instantánea del servidor
  - [x] 2.1 Escribir la lógica de conversión y carga en `importar_snapshot.sql`
    - INSERT desde `snapshot_servidor_import` hacia `snapshot_servidor` convirtiendo booleanos PostgreSQL `t`/`f` a enteros `1`/`0` con expresiones `CASE`
    - INSERT desde `snapshot_servidor` hacia `producto_cache` para sincronizar la caché local
    - _Requirements: 2.1, 3.1_

- [x] 3. Checkpoint — Esquema e importación completos
  - Verificar que `schema_sqlite.sql` e `importar_snapshot.sql` producen una base de datos válida con datos correctamente convertidos.

- [x] 4. Implementar el Semáforo (`semaforo.sql`)
  - [x] 4.1 Construir la tabla temporal `evaluacion_semaforo`
    - `DROP TABLE IF EXISTS temp.evaluacion_semaforo` al inicio para idempotencia
    - `CREATE TEMP TABLE evaluacion_semaforo AS SELECT ...` con LEFT JOIN `cola_sync → item_borrador → snapshot_servidor`
    - Filtro `WHERE c.estado = 'PENDIENTE'` para procesar solo solicitudes pendientes
    - Calcular contadores: `cantidad_items`, `cantidad_rojos`, `productos_inexistentes`, `productos_no_disponibles`, `productos_dados_de_baja`, `stocks_insuficientes`, `conflictos_precio`
    - _Requirements: 4.2, 4.3_

  - [x] 4.2 Implementar la detección de CONFLICTO por cambio de precio
    - Expresión `CASE WHEN s.id IS NOT NULL AND i.precio_centavos_visto <> s.precio_centavos THEN 1 ELSE 0 END` para `conflictos_precio`
    - _Requirements: 1.1, 1.2, 1.3_

  - [x] 4.3 Implementar la detección de RECHAZADO por stock insuficiente
    - Expresión `CASE WHEN s.id IS NOT NULL AND i.cantidad > s.stock THEN 1 ELSE 0 END` para `stocks_insuficientes`
    - Incluir `stocks_insuficientes > 0` en `cantidad_rojos` (condición bloqueante)
    - _Requirements: 2.1, 2.2_

  - [x] 4.4 Implementar la detección de RECHAZADO por baja lógica y producto inexistente
    - Expresión `CASE WHEN s.id IS NULL THEN 1 ELSE 0 END` para `productos_inexistentes`
    - Expresión `CASE WHEN s.id IS NOT NULL AND s.eliminado <> 0 THEN 1 ELSE 0 END` para `productos_dados_de_baja`
    - Expresión `CASE WHEN s.id IS NOT NULL AND s.disponible <> 1 THEN 1 ELSE 0 END` para `productos_no_disponibles`
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [x] 4.5 Implementar el UPDATE con precedencia de estados y motivos
    - `UPDATE cola_sync SET estado = (...), motivo = (...)` con subconsulta a `evaluacion_semaforo`
    - Expresión `CASE` anidada para `estado`: RECHAZADO si `cantidad_items = 0 OR cantidad_rojos > 0`, CONFLICTO si `conflictos_precio > 0`, SIMULADO_APROBADO en otro caso
    - Expresión `CASE` anidada para `motivo` evaluando prioridades 1–7 en orden decreciente
    - Cláusula `WHERE c.estado = 'PENDIENTE' AND EXISTS (...)` para garantizar idempotencia
    - `DROP TABLE evaluacion_semaforo` al finalizar para limpiar la sesión
    - _Requirements: 1.1, 1.2, 1.3, 2.1, 2.2, 3.1, 3.2, 3.3, 3.4, 4.2, 4.3_

- [x] 5. Checkpoint — Semáforo implementado
  - Verificar que `semaforo.sql` produce los estados correctos sobre una base de datos con datos de prueba básicos.

- [x] 6. Implementar las pruebas de integración (`casos_2c.sql`)
  - [x] 6.1 Implementar el caso C2 — CONFLICTO por cambio de precio
    - Insertar pedido `c2-original` con precio visto 105 000 y modificar `snapshot_servidor` a 110 000
    - Insertar solicitud con estado `PENDIENTE` y ejecutar `semaforo.sql`
    - Verificar: `estado = 'CONFLICTO'`, `motivo = 'Cambió el precio observado'`
    - _Requirements: 1.1, 1.2_

  - [x] 6.2 Implementar el caso C2 — SIMULADO_APROBADO tras aceptar el precio nuevo
    - Actualizar el precio del borrador `c2-original` y enviar la solicitud nueva `c2-solicitud-2`
    - Ejecutar `semaforo.sql` y verificar: `estado = 'SIMULADO_APROBADO'`
    - _Requirements: 1.3_

  - [x] 6.3 Implementar el caso C3 — RECHAZADO por stock insuficiente
    - Insertar pedido `c3-stock` con `cantidad = 36` cuando el stock del producto es inferior
    - Verificar: `estado = 'RECHAZADO'`, `motivo = 'Stock insuficiente'`
    - _Requirements: 2.1, 2.2_

  - [x] 6.4 Implementar el caso C4 — RECHAZADO por baja lógica
    - Insertar pedido `c4-baja`, dar de baja el producto 3 en la copia de PostgreSQL (`activo = false`) y recargar la instantánea `servidor_snapshot_2c.csv`
    - Verificar: `estado = 'RECHAZADO'`, `motivo = 'Producto no disponible'`; al recargar el catálogo el producto no aparece, pero su fila queda en `producto_cache`
    - _Requirements: 3.1, 3.2_

  - [x] 6.5 Implementar el caso C5 — SIMULADO_APROBADO sin cambios
    - Insertar pedido `c5-sin-cambios` con precio, stock y disponibilidad coincidentes
    - Verificar: `estado = 'SIMULADO_APROBADO'`, `motivo = 'Precio, disponibilidad y stock coinciden'`
    - _Requirements: 1.3_

  - [x] 6.6 Implementar el caso C6 — Idempotencia y UUID duplicado
    - Intentar re-insertar `c5-solicitud` (UUID ya existente) y verificar error `UNIQUE constraint failed`
    - Verificar que la solicitud original mantiene su estado sin alteración tras segunda ejecución de `semaforo.sql`
    - _Requirements: 4.1, 4.2, 4.3_

- [x] 7. Checkpoint final — Sistema completo y verificado
  - Todos los casos C2–C6 producen los estados y motivos esperados.
  - La idempotencia está verificada: dos ejecuciones consecutivas de `semaforo.sql` producen el mismo resultado.
  - Resultados documentados en `docs/resultado_semaforo_2b.md` y `docs/resultado_casos_2c.md`.

## Notes

- Este documento es **retroactivo**: todos los ítems están marcados como completados porque el sistema ya existe y está verificado.
- Las tareas reflejan el orden lógico de construcción, no un plan de trabajo futuro.
- No hay sub-tareas opcionales con `*` porque el diseño no define propiedades universales susceptibles de property-based testing; el sistema es SQL puro y las pruebas son casos de integración concretos.
- Los resultados de las pruebas están disponibles en `docs/resultado_casos_2c.md` y `docs/resultado_semaforo_2b.md`.
- PostgreSQL y MongoDB no son modificados en ningún caso de prueba; todas las pruebas operan sobre copias locales de la base SQLite.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "2.1"] },
    { "id": 2, "tasks": ["4.1"] },
    { "id": 3, "tasks": ["4.2", "4.3", "4.4"] },
    { "id": 4, "tasks": ["4.5"] },
    { "id": 5, "tasks": ["6.1", "6.2", "6.3", "6.4", "6.5", "6.6"] }
  ]
}
```
