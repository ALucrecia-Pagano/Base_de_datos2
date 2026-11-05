# Requirements Document

## Introduction

El sistema de sincronización offline de la tablet (Food Store en feria) permite
registrar solicitudes de venta en una base SQLite local mientras el dispositivo
no tiene conectividad con el servidor PostgreSQL. Cuando la conectividad se
restituye, un componente denominado **Semáforo** evalúa cada solicitud pendiente
contra una instantánea del servidor (`snapshot_servidor`) y le asigna uno de
tres estados: `RECHAZADO`, `CONFLICTO` o `SIMULADO_APROBADO`.

El principio rector es **"el móvil propone, el servidor dispone"**: la tablet
nunca modifica stock, precios ni ningún dato del servidor. El estado
`SIMULADO_APROBADO` indica únicamente que la solicitud es coherente con la
instantánea local; la venta real queda pendiente de confirmación del servidor.

El Semáforo es **idempotente**: solo procesa solicitudes en estado `PENDIENTE`
y no vuelve a evaluar solicitudes ya resueltas.

## Glossary

- **Semáforo**: componente SQLite (archivo `semaforo.sql`) que evalúa las
  solicitudes de `cola_sync` en estado `PENDIENTE` contra `snapshot_servidor` y
  actualiza su estado y motivo.
- **Cola_Sync**: tabla SQLite `cola_sync` que registra las solicitudes de venta
  con su UUID único, referencia al pedido local, estado actual y motivo.
- **Snapshot_Servidor**: tabla SQLite `snapshot_servidor` que contiene la última
  instantánea conocida de productos del servidor (precio, stock, disponibilidad,
  baja lógica).
- **Item_Borrador**: tabla SQLite `item_borrador` que contiene los ítems
  (producto, cantidad, precio visto) asociados a un pedido local.
- **Solicitud_UUID**: identificador único (`PRIMARY KEY`) de cada solicitud en
  `cola_sync`; impide duplicados a nivel de base de datos.
- **Estado_PENDIENTE**: estado inicial de toda solicitud recién insertada en
  `cola_sync`; única condición para que el Semáforo la evalúe.
- **Estado_RECHAZADO**: estado final que indica que la solicitud no puede
  procesarse por alguna condición bloqueante: producto inexistente en la
  instantánea, producto no disponible (`disponible = 0`), producto dado de baja
  (`eliminado = 1`), stock insuficiente (`cantidad > stock`), o solicitud sin
  ítems (`cantidad_items = 0`).
- **Estado_CONFLICTO**: estado final que indica discrepancia de precio sin
  condición bloqueante; requiere revisión del operador.
- **Estado_SIMULADO_APROBADO**: estado final que indica coherencia total con la
  instantánea; no constituye una venta real ni descuenta stock.

## Requirements

### Requirement 1: CONFLICTO por cambio de precio

**User Story:** Como operador de la tablet en feria, quiero saber cuando el
precio de un producto cambió en el servidor desde que armé el pedido, para poder
informar al cliente antes de confirmar la venta.

#### Acceptance Criteria

1. IF el Semáforo evalúa una solicitud en estado `PENDIENTE` Y el
   `precio_centavos_visto` de algún ítem en Item_Borrador difiere —en cualquier
   dirección— del `precio_centavos` del producto con el mismo `producto_id` en
   Snapshot_Servidor, THEN el Semáforo SHALL asignar el estado `CONFLICTO` a la
   solicitud en Cola_Sync.
2. WHEN el Semáforo asigna estado `CONFLICTO`, THEN el Semáforo SHALL registrar
   el motivo `'Cambió el precio observado'` en el campo `motivo` de Cola_Sync.
3. WHILE ningún ítem de la solicitud presenta alguna de las condiciones de
   rechazo exhaustivas (stock insuficiente, baja lógica, producto no disponible
   o producto inexistente) Y existe al menos un ítem con conflicto de precio,
   THE Semáforo SHALL asignar `CONFLICTO` con precedencia sobre
   `SIMULADO_APROBADO` y con precedencia inferior a `RECHAZADO`.

Se prueba con: C2.

### Requirement 2: RECHAZADO por stock insuficiente

**User Story:** Como operador de la tablet en feria, quiero que el sistema
detecte pedidos con cantidad mayor al stock disponible en la instantánea, para
no registrar ventas que el servidor no puede satisfacer.

#### Acceptance Criteria

1. WHEN el Semáforo evalúa una solicitud en estado `PENDIENTE` Y al menos un
   ítem en Item_Borrador tiene una `cantidad` que supera el `stock` del producto
   correspondiente en Snapshot_Servidor, THEN el Semáforo SHALL asignar el
   estado `RECHAZADO` a la solicitud en Cola_Sync.
2. WHEN el Semáforo asigna estado `RECHAZADO` por stock insuficiente Y ningún
   ítem de la solicitud presenta condición de mayor prioridad (producto
   inexistente, no disponible o dado de baja), THEN el Semáforo SHALL registrar
   el motivo `'Stock insuficiente'` en el campo `motivo` de Cola_Sync.

Se prueba con: C3.

### Requirement 3: RECHAZADO por baja lógica

**User Story:** Como operador de la tablet en feria, quiero que el sistema
rechace pedidos que contienen productos dados de baja en el servidor, para no
gestionar ventas de productos que ya no se comercializan.

#### Acceptance Criteria

1. WHEN el Semáforo evalúa una solicitud en estado `PENDIENTE` Y algún ítem en
   Item_Borrador referencia un producto con `eliminado = 1` en
   Snapshot_Servidor, THEN el Semáforo SHALL asignar el estado `RECHAZADO` a
   la solicitud en Cola_Sync.
2. WHEN el Semáforo asigna estado `RECHAZADO` por baja lógica Y ningún
   ítem de la solicitud presenta condición de mayor prioridad (producto
   inexistente o producto no disponible), THEN el Semáforo SHALL registrar
   el motivo `'Producto dado de baja'` en el campo `motivo` de Cola_Sync.
3. IF la solicitud en estado `PENDIENTE` contiene al menos un ítem con
   `eliminado = 1` Y también ítems con `eliminado = 0` en Snapshot_Servidor,
   THEN el Semáforo SHALL igualmente asignar el estado `RECHAZADO` a la
   solicitud completa en Cola_Sync, sin aprobar los ítems válidos parcialmente.
4. IF el `producto_id` de un ítem en Item_Borrador no existe en
   Snapshot_Servidor, THEN el Semáforo SHALL asignar el estado `RECHAZADO` a
   la solicitud en Cola_Sync con motivo `'Producto inexistente en la
   instantánea'`, distinto del motivo por baja lógica.

Se prueba con: C4. En C4 la baja se hace en PostgreSQL (`activo = false`), por lo que la instantánea trae también `disponible = 0`: se cumple el criterio 1 (estado `RECHAZADO`) y, como el producto no disponible tiene mayor prioridad (criterio 2), el motivo registrado es `'Producto no disponible'`.

### Requirement 4: Idempotencia — UUID no se duplica ni reevalúa

**User Story:** Como operador de la tablet en feria, quiero que cada solicitud
se evalúe exactamente una vez y que no pueda enviarse dos veces con el mismo
identificador, para mantener la integridad de la cola de sincronización.

#### Acceptance Criteria

1. THE Cola_Sync SHALL rechazar con error de unicidad cualquier intento de
   insertar una solicitud cuyo `solicitud_uuid` ya exista en la tabla.
2. WHEN el Semáforo ejecuta el proceso de evaluación, THE Semáforo SHALL
   evaluar y actualizar el estado únicamente de las solicitudes cuyo estado sea
   `PENDIENTE`, sin leer ni modificar las solicitudes con estado
   `SIMULADO_APROBADO`, `CONFLICTO` o `RECHAZADO`.
3. WHILE una solicitud tiene un estado distinto de `PENDIENTE`, WHEN el Semáforo
   vuelve a ejecutarse, THE Semáforo SHALL mantener el estado y motivo previos
   de dicha solicitud sin alteración.

Se prueba con: C6.
