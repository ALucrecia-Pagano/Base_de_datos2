# Diseño técnico — Migración FNBC y reversión

## Esquema antes y después

| Objeto | Tipo | Columnas | Clave primaria (PK) | Claves foráneas (FK) |
|---|---|---|---|---|
| `public.control_lote_almacen` | Tabla (original) | `lote_id BIGINT`<br>`deposito_id BIGINT`<br>`responsable_control_id BIGINT` | `pk_control_lote_almacen` (`lote_id`, `deposito_id`) | • `fk_cla_lote` (`lote_id`) → `public.lote(id)` ON DELETE RESTRICT<br>• `fk_cla_deposito` (`deposito_id`) → `public.deposito(id)` ON DELETE RESTRICT<br>• `fk_cla_responsable` (`responsable_control_id`) → `public.usuario(id)` ON DELETE RESTRICT |
| `public.responsable_deposito` | Tabla (descompuesta) | `responsable_control_id BIGINT`<br>`deposito_id BIGINT` | `pk_responsable_deposito` (`responsable_control_id`) | • `fk_rd_responsable` (`responsable_control_id`) → `public.usuario(id)` ON DELETE RESTRICT<br>• `fk_rd_deposito` (`deposito_id`) → `public.deposito(id)` ON DELETE RESTRICT |
| `public.control_lote` | Tabla (descompuesta) | `lote_id BIGINT`<br>`responsable_control_id BIGINT` | `pk_control_lote` (`lote_id`, `responsable_control_id`) | • `fk_cl_lote` (`lote_id`) → `public.lote(id)` ON DELETE RESTRICT<br>• `fk_cl_responsable_deposito` (`responsable_control_id`) → `public.responsable_deposito(responsable_control_id)` ON DELETE RESTRICT |
| `public.v_control_lote_almacen` | Vista (reconstrucción) | `lote_id BIGINT`<br>`deposito_id BIGINT`<br>`responsable_control_id BIGINT` | *(No aplica — vista por JOIN)* | *(No aplica — vista por JOIN)* |

## Secuencia de la migración (ida)

1. **Comprobaciones previas:** Validar conexión a `foodstore_copia_trabajo`, verificar que `public.usuario` exista con columna `id` identity `BIGINT`, comprobar ausencia de colisiones de nombres para los objetos a crear en `public`, y bloquear concurrentemente `public.usuario` con `LOCK TABLE public.usuario IN SHARE ROW EXCLUSIVE MODE NOWAIT`.
2. **Validación de C → D:** Comprobar sobre `public.control_lote_almacen` que ningún responsable esté asociado a más de un depósito (`COUNT(DISTINCT deposito_id) = 1` por responsable).
3. **Creación de tablas nuevas:** Ejecutar el DDL de `public.responsable_deposito` y `public.control_lote` con sus respectivas restricciones de clave primaria y claves foráneas.
4. **Poblado de datos (INSERT … SELECT DISTINCT):** Proyectar las tuplas distintas de la relación original hacia `public.responsable_deposito` y hacia `public.control_lote`.
5. **Creación de vista de reconstrucción:** Crear `public.v_control_lote_almacen` mediante `JOIN ... ON` explícito por el atributo común `responsable_control_id`.
6. **Verificación de equivalencia:** Guardar foto en la tabla temporal `ref_control_lote_almacen` y comparar contra `v_control_lote_almacen` mediante doble `EXCEPT` y comparación de `COUNT(*)`.
7. **Retiro de control_lote_almacen (corte):** Eliminar la vista intermedia `DROP VIEW public.v_control_lote_almacen` y la tabla original `DROP TABLE public.control_lote_almacen`, verificando con `to_regclass` su efectiva desaparición del catálogo.

## Secuencia de la reversión (vuelta)

1. **Validación de LD → C en los datos nuevos:** Evaluar la consulta de agrupación sobre el `JOIN` de `control_lote` y `responsable_deposito` para asegurar que ningún par `(lote_id, deposito_id)` tenga más de un `responsable_control_id` asociado.
2. **Recrear control_lote_almacen con el DDL original:** Ejecutar el `CREATE TABLE public.control_lote_almacen` con su clave primaria (`pk_control_lote_almacen`) y sus tres claves foráneas (`fk_cla_lote`, `fk_cla_deposito`, `fk_cla_responsable`).
3. **Poblado por JOIN (INSERT … SELECT):** Insertar en `public.control_lote_almacen` las tuplas resultantes del `JOIN` entre `control_lote` y `responsable_deposito`.
4. **Verificación de equivalencia contra la foto previa:** Comprobar que no existan discrepancias entre `ref_control_lote_almacen` y `public.control_lote_almacen` mediante consulta con `UNION ALL` de diferencias `EXCEPT` y aserción de `COUNT(*)`.
5. **Retiro de vista de reconstrucción:** Si existiera en el entorno, eliminar `DROP VIEW public.v_control_lote_almacen` (en este flujo fue retirada durante el corte).
6. **Retiro de tablas descompuestas en orden estricto de FK:** Ejecutar primero `DROP TABLE public.control_lote` y posteriormente `DROP TABLE public.responsable_deposito` para no violar la restricción `fk_cl_responsable_deposito`.
7. **Comprobación de catálogo:** Verificar mediante `to_regclass` que `control_lote`, `responsable_deposito` y `v_control_lote_almacen` devuelvan `NULL`.

## Cómo se verifica que no hay pérdida

Por definición del álgebra relacional y del estándar SQL, el operador `EXCEPT` elimina duplicados antes de emitir su resultado, por lo que dos relaciones con multiplicidades distintas de una misma fila darían una diferencia vacía.
Por esta razón, la verificación de equivalencia combina el análisis de `EXCEPT` en ambos sentidos con la comparación estricta de `COUNT(*)` entre ambas relaciones, garantizando que el conjunto y la cardinalidad sean exactamente iguales.

## Por qué la reversión valida LD → C

Tal como se documentó en la sección 7 del informe de FNBC, la descomposición preserva localmente C → D pero no preserva LD → C; por ello, las tablas descompuestas permiten almacenar asignaciones donde dos responsables de un mismo depósito controlen el mismo lote.
Ese estado no es admisible en la relación original porque su clave primaria es `(lote_id, deposito_id)`, lo que provocaría un fallo de unicidad al ejecutar el `INSERT`.
Por este motivo, la reversión valida preventivamente que no existan violaciones a LD → C en los datos nuevos antes de intentar recrear y poblar la tabla original, abortando la operación con un mensaje explicativo.
