# Consigna 3.c — Code review con IA

**Herramienta:** Antigravity (modelo Claude Sonnet 5.5), en modo Plan, de solo
lectura. La consigna menciona OpenCode; el docente autorizó usar cualquier
herramienta de IA.
**Alcance:** los 75 scripts (`.sql`, `.js`, `.ps1`, `.py`) de los dos
repositorios de la cursada: `Base_de_datos2` (TP1 a TP7 y Unidad 6) y
`Bases-de-datos-II-NoSQL` (Unidad 7 y Unidad 8). Se le dio una copia de los
scripts y los `.md` en una carpeta aparte, con la prohibición de modificar
archivos o conectarse a las bases. En una primera pasada leyó 54 scripts; se le
pidió completar los 21 restantes hasta llegar a 75 de 75.

**Criterio de decisión.** *Aceptado*: el hallazgo es correcto. Si es de un TP
ya calificado, no se modifica y queda registrado como mejora. *Corregido*: es
correcto y se corrigió en este TP. *Descartado*: no aplica, con el fundamento
indicado.

## Tabla de hallazgos

| ID | Ubicación | Hallazgo (resumido) | Decisión | Motivo |
|---|---|---|---|---|
| F01 | TP2 · `restricciones_integridad.sql` | El trigger de stock lee sin `FOR UPDATE` y no descuenta stock: dos sesiones concurrentes pueden vender más que el stock. | Aceptado | Correcto por lectura del código. TP2 calificado: mejora registrada. |
| F02 | TP1 y TP5 · `schema.sql` | `DROP ... CASCADE` sin control de base. | Aceptado (parcial) | Falta el control de base. Pero la IA leyó mal `views.sql`: indica correrse *después* de `schema.sql` para armar una base desde cero, no correr `schema.sql` sobre la base de carga. |
| F03 | TP7 · `fn_resetear_password.sql` | `rol_soporte` puede resetear la clave de un ADMIN. | Aceptado | Observación de diseño: el reseteo para soporte es un requisito del TP7, pero no excluye a los administradores. |
| F04 | TP7 · `fn_autenticar.sql` / `fn_resetear_password.sql` | Una función recorta espacios de la clave (`btrim`) y la otra no. | Aceptado | Correcto por lectura del código; no se comprobó en la base. |
| **F05** | **TP2 · `restricciones_integridad.sql` y TP1 · `schema.sql`** | **Un pedido ENTREGADO se puede borrar y arrastra su detalle.** | **Aceptado** | **Comprobado en la base (ver desarrollo).** |
| F06 | Unidad 7 · `prueba_validacion_expr_mongodb.js` | El validador solo controla la aritmética, no los rangos. | Aceptado | Correcto; ese script prueba una sola afirmación. Mejora: `$jsonSchema`. |
| **F07** | **Unidad 8 · `recargar_snapshot.sql`** | **Un error al recargar deja la tablet sin instantánea.** | **Corregido** | **Comprobado y corregido (ver desarrollo).** |
| F08 | Unidad 8 · `importar_snapshot.sql` | `CAST` de texto no numérico da 0 sin error en SQLite. | Aceptado | Riesgo bajo: el CSV sale de una columna `bigint` de la vista. Se registra como mejora. |
| **F09** | **Unidad 8 · `recargar_snapshot.sql`** | **Un producto que desaparece del CSV quedaría disponible en la tablet.** | **Descartado** | **Comprobado en la base (ver desarrollo).** |
| F10 | Unidad 6 · `backup_foodstore.ps1` | El conteo de control se mide en otra transacción que el respaldo. | Descartado | El informe de la Unidad 6 declara que no hubo escrituras durante el ensayo, condición necesaria para el problema. Válido para un servidor con uso real. |
| F11 | TP7 · `activar_auditoria_local.sql` | `log_statement = 'all'` registra claves en texto plano. | Descartado | Decisión deliberada de laboratorio, documentada en el propio script, con claves sintéticas y restauración del valor al terminar. |
| F12 | Unidad 6 · `restore_test.ps1` | La restauración descarta dueños y permisos. | Aceptado | Ya figura como mejora en el informe de la Unidad 6 (`pg_dumpall --globals-only`). |
| F13 | TP7 · `fn_resetear_password.sql` | `gen_salt('bf')` usa el costo por defecto, bajo. | Aceptado | Correcto por lectura del código; mejora registrada. |
| F14 | TP7 · `fn_autenticar.sql` | Diferencia de tiempo entre mail existente e inexistente. | Aceptado | Riesgo bajo y difícil de medir con costo bajo; mejora registrada. |
| F15 | TP4 · `consulta_competencia.sql` | Usa `now()`: el resultado depende del día de ejecución. | Aceptado | Problema de reproducibilidad; TP6 ya usa una fecha fija. |
| F16 | TP3 · `seed_masivo.sql` | Carga masiva sin control de base ni `ON_ERROR_STOP`. | Aceptado | Correcto; los scripts posteriores (TP6, TP7) ya incorporan ese control. |
| F17 | TP3 · `seed_masivo.sql` y TP2 | Cantidades y stock se generan sin relación entre sí. | Aceptado | Riesgo latente: solo afecta si se instalan los triggers de TP2, que hoy no están en ninguna base. |
| F18 | TP3 · `verificacion_carga.sql` | El rango esperado en un comentario no coincide con la carga real. | Aceptado | Comentario desactualizado; el valor verificado sí es correcto. |
| F19 | TP3 · `indices_propuestos.sql` | Crea los 4 índices aunque 3 se revirtieron. | Aceptado | Registro histórico; si se ejecutara tal cual, chocaría con TP5. |
| F20 | TP3 · `optimizacion_propuesta_2.sql` | La Propuesta 2 no se mide combinada con la 1, como dice el comentario. | Aceptado | El comentario no coincide con el script. |
| F21 | TP5 · `medir_q2_rondas.sql` | No se puede repetir con el índice ya aplicado. | Aceptado | Script de medición ya ejecutado y archivado. |
| F22 | TP5 · `medir_q4_rondas.sql` | `DROP/CREATE INDEX` con `COMMIT` sin control de base. | Aceptado | Correcto; el propio archivo advierte el estado del índice. |
| F23 | TP3 y TP5 · consultas | `BETWEEN` con `timestamptz` excluye el último día después de las 00:00. | Aceptado | Buena práctica; con los datos de la carga no cambia el resultado. |
| F24 | TP7 · `usuario_anon_cobertura.sql` | `LOCK TABLE` sin `NOWAIT` ni `lock_timeout`. | Aceptado | Riesgo bajo en un laboratorio de un solo usuario. |

## Desarrollo de tres hallazgos

### F05 — Un pedido ENTREGADO se puede borrar (TP2) · Aceptado

**Qué dijo la IA.** El trigger de TP2 que protege los pedidos en estado final
solo actúa en `UPDATE`, y la clave foránea `pedido → detalle_pedido` es
`ON DELETE CASCADE`. Un `DELETE` borra el pedido y su detalle, contra la regla
de preservar la historia de ventas.

**Cómo se comprobó.** En la copia `foodstore_tp8_feria`, dentro de
`BEGIN … ROLLBACK`: se instalaron los triggers de TP2 y se verificó que
existían (2 en `pedido`). Un `UPDATE` del pedido 1 (ENTREGADO) a CANCELADO fue
rechazado por el trigger. El `DELETE` del mismo pedido respondió `DELETE 1`, y
su detalle pasó de 2 filas a 0. Después del `ROLLBACK` quedaron 5 pedidos y
0 triggers. La prueba se repitió en `foodstore_copia_trabajo`, la base donde
TP2 instaló los triggers: hoy no los tiene, y el `DELETE` también pasa.

**Decisión.** Aceptado. TP2 está calificado y no se modifica. Mejora
registrada: un trigger `BEFORE DELETE` que rechace los pedidos en estado final,
y `ON DELETE RESTRICT` en la clave foránea.

### F07 — Un error al recargar vacía la instantánea de la tablet (Unidad 8) · Corregido

**Qué dijo la IA.** En `recargar_snapshot.sql`, si el `INSERT` en
`snapshot_servidor` falla, `sqlite3` sigue de largo y el `COMMIT` confirma el
`DELETE` previo. La tablet queda sin instantánea, y el semáforo rechazaría todo
como "Producto inexistente".

**Cómo se comprobó.** En una base SQLite de prueba, fuera del repositorio, se
cargó la instantánea inicial (3 productos) y se recargó con un CSV que repetía
el producto 1. Antes de corregir: error `UNIQUE constraint failed` y
`snapshot_servidor` con **0** filas.

**Corrección.** Se agregó `.bail on` al inicio del script y `.bail off` al
final. Ante un error, `sqlite3` se detiene antes del `COMMIT` y la transacción
se descarta. Después de corregir, con el mismo CSV: el mismo error, pero
`snapshot_servidor` conserva sus **3** filas. Prueba de regresión: los casos C2
a C6 dan los mismos resultados que antes. El `.bail off` final evita que el
error intencional de C6 corte la ejecución de `casos_2c.sql`.

### F09 — Un producto que desaparece del servidor (Unidad 8) · Descartado

**Qué dijo la IA.** El upsert de `recargar_snapshot.sql` solo actualiza los
productos presentes en el CSV. Si un producto desaparece del servidor, quedaría
en la tablet como disponible.

**Cómo se comprobó.** En `foodstore_tp8_feria`, con la Coca 1.5L dada de baja:
hay 3 productos y la vista `v_snapshot_movil` exporta 3 filas (1 dada de baja).
La vista no filtra por `activo`, así que la baja lógica viaja a la tablet como
`disponible = 0`. El intento de borrar físicamente la Coca falló por la clave
foránea `fk_detalle_pedido_producto` (`ON DELETE RESTRICT`). No hay productos
sin ventas (0 filas).

**Decisión.** Descartado. En este diseño un producto no desaparece del CSV: se
da de baja lógicamente y sigue viajando. **Límite:** solo podría pasar con un
producto nuevo, sin ventas, borrado físicamente en vez de darse de baja. Hoy no
existe ninguno.