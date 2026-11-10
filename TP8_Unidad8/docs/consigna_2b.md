# Consigna 2.b — Semáforo de sincronización

El script [`semaforo.sql`](../movil/semaforo.sql) compara cada solicitud
`PENDIENTE` con `snapshot_servidor`. No modifica PostgreSQL, el stock ni el
precio del servidor.

La clasificación se realiza con esta prioridad:

1. **RECHAZADO**: algún producto no existe, no está disponible, fue dado de
   baja o no alcanza el stock solicitado.
2. **CONFLICTO**: no hay una condición roja, pero cambió algún precio.
3. **SIMULADO_APROBADO**: todos los productos y cantidades son compatibles y
   los precios coinciden.

El `UPDATE` filtra por `estado = 'PENDIENTE'`. Por lo tanto, repetir el script
no reevalúa solicitudes ya clasificadas y no cambia su resultado. La operación
solo actualiza `cola_sync`; los borradores y la instantánea permanecen sin
modificaciones.

El motivo conserva la primera condición detectada según la misma prioridad:
producto inexistente, no disponible, baja lógica, stock insuficiente, cambio de
precio o coincidencia completa.
