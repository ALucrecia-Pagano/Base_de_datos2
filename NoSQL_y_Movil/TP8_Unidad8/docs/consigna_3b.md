# Consigna 3.b — Plan de mantenimiento (agregado al plan de la Unidad 6)

Este agregado amplía el [plan de mantenimiento, respaldo y recuperación de la Unidad 6](https://github.com/ALucrecia-Pagano/Base_de_datos2/tree/main/TP8_Mantenimiento_Respaldo_Recuperacion)
para incluir MongoDB y las tablets. El plan original no se modifica: sigue
vigente para PostgreSQL (respaldo diario con `pg_dump -Fc`, restauración
ensayada en `foodstore_restore_test`, RTO ≤ 15 min y RPO ≤ 24 h).

## ¿Qué se respalda y cómo se prueba la restauración?

| Motor | Qué se respalda | Cómo se prueba |
|---|---|---|
| PostgreSQL | La base completa, todos los días, con `pg_dump -Fc` (plan de la Unidad 6). Mejora pendiente del mismo plan: roles y permisos con `pg_dumpall --globals-only`. | Restaurar en `foodstore_restore_test` y comparar conteos por tabla y los nueve indicadores de integridad (`restore_test.ps1`). |
| MongoDB | `foodstore_unidad7` con `mongodump`. No es crítico: es una copia derivada y se puede reconstruir desde PostgreSQL con el script de migración de la Unidad 7. | Restaurar con `mongorestore` en una base descartable y comprobar que haya 5 documentos y que cada `total` coincida con la suma de sus `lineas`. |
| SQLite (tablet) | Solo lo que no existe en otro lado: borradores y solicitudes sin enviar. Al cerrar cada jornada se copia la base con `.backup` de `sqlite3`, que genera una copia consistente aunque la base esté abierta. El catálogo no se respalda: se recarga con una instantánea nueva. | Abrir la copia, ejecutar `PRAGMA integrity_check;` (debe responder `ok`) y contar las solicitudes `PENDIENTE`. |

## Si se restaura un respaldo viejo de PostgreSQL, ¿qué hacen las tablets?

El servidor vuelve a un estado anterior, y la tablet puede tener una
instantánea más nueva que él. Como el servidor manda, la tablet se adapta:

1. **Descarta su catálogo y pide una instantánea nueva** al servidor restaurado.
   No conserva precios ni stock propios: la `fecha_copia` de su copia puede ser
   posterior a la del respaldo restaurado.
2. **Vuelve a evaluar sus solicitudes `PENDIENTE`** con el semáforo contra esa
   instantánea. Si el precio volvió a un valor anterior, la solicitud pasa a
   `CONFLICTO` y se resuelve como en C2.
3. **Reenvía las solicitudes que se enviaron después del respaldo**, con su
   mismo `solicitud_uuid`. El servidor restaurado ya no las tiene, así que las
   evalúa de nuevo. Con la protección de C6 en el servidor, un reenvío nunca
   genera un pedido duplicado.

## ¿Cada cuánto y quién revisa las solicitudes en CONFLICTO o RECHAZADO?

- **`CONFLICTO`:** el vendedor, en el momento de sincronizar, con el cliente
  presente. Si el cliente acepta el precio nuevo, se actualiza el borrador y se
  envía una solicitud nueva (C2).
- **`RECHAZADO`:** el encargado del puesto, al cierre de cada jornada de feria.
  Avisa al cliente o anula el borrador.
- **Una vez por semana**, el administrador de la base revisa los motivos que se
  repiten. Por ejemplo, muchos "Stock insuficiente" indican que la tablet
  sincroniza poco y hay que actualizar la instantánea más seguido.

Consulta de revisión en la tablet:

```sql
SELECT estado, motivo, COUNT(*) AS solicitudes
FROM cola_sync
WHERE estado IN ('CONFLICTO', 'RECHAZADO')
GROUP BY estado, motivo
ORDER BY estado, motivo;
```

Con los datos de la consigna 2.c devuelve una solicitud en `CONFLICTO` por
cambio de precio y dos en `RECHAZADO`: una por producto no disponible y otra
por stock insuficiente.