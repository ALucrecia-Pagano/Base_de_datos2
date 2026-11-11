# Spec — Migración FNBC de control_lote_almacen

Formato de spec en tres archivos (requisitos, diseño, tareas) al estilo Kiro. La cátedra autorizó usar cualquier herramienta de IA.

## Contexto

La relación `control_lote_almacen(lote_id, deposito_id, responsable_control_id)` presenta las dependencias funcionales del dominio LD → C y C → D, cumpliendo 3FN pero violando la Forma Normal de Boyce-Codd (FNBC) debido a que en C → D el determinante no es superclave.
Esta violación produce tres anomalías operativas documentadas: de inserción (imposibilidad de registrar la asignación de un responsable a un depósito sin asociarle de inmediato un lote), de borrado (al eliminar el último lote de un responsable se pierde su vinculación con el depósito) y de actualización (el traslado de un responsable exige modificar múltiples tuplas arriesgando inconsistencias).
Para subsanar estas anomalías se proyecta la descomposición en dos relaciones en FNBC: `responsable_deposito(responsable_control_id, deposito_id)` y `control_lote(lote_id, responsable_control_id)`.

## Requisitos

### R1 — Base protegida
**Historia:** Como responsable de la base, quiero restringir la ejecución exclusivamente a `foodstore_copia_trabajo` y abortar ante objetos preexistentes, para evitar sobrescribir esquemas o ejecutar accidentalmente en entornos no autorizados.

**Criterios de aceptación (EARS):**
- SI la base de datos conectada no es `foodstore_copia_trabajo`, ENTONCES el script DEBE abortar la ejecución inmediatamente con una excepción explícita.
- SI no existe la tabla `public.usuario` o su columna `id` no es de tipo `BIGINT GENERATED ALWAYS AS IDENTITY`, ENTONCES el script DEBE abortar la ejecución.
- SI existe en el esquema `public` cualquiera de los objetos a crear (`lote`, `deposito`, `control_lote_almacen`, `responsable_deposito`, `control_lote`, `v_control_lote_almacen`), ENTONCES el script DEBE abortar la ejecución sin modificar el catálogo.

### R2 — Validación previa
**Historia:** Como responsable de la base, quiero validar las dependencias funcionales antes de migrar y antes de revertir, para garantizar que los datos cumplan las premisas del modelo tanto en la ida como en la vuelta.

**Criterios de aceptación (EARS):**
- CUANDO se analice la relación original `control_lote_almacen`, SI algún `responsable_control_id` está asociado a más de un `deposito_id` (violación de C → D), ENTONCES el script DEBE abortar la migración con un mensaje de error descriptivo.
- CUANDO se inicie el proceso de reversión sobre las tablas descompuestas, SI algún par `(lote_id, deposito_id)` está asociado a más de un `responsable_control_id` tras el JOIN (violación de LD → C), ENTONCES el script DEBE abortar la reversión sin recrear la relación original.

### R3 — Migración sin pérdida
**Historia:** Como responsable de la base, quiero descomponer los datos mediante proyecciones con `SELECT DISTINCT` y verificar su reconstrucción por JOIN, para asegurar una descomposición sin pérdida de información.

**Criterios de aceptación (EARS):**
- CUANDO se pueblen `responsable_deposito` y `control_lote`, el script DEBE proyectar las tuplas mediante `SELECT DISTINCT` desde `control_lote_almacen`.
- CUANDO se verifique la equivalencia entre la foto original y la vista reconstruida `v_control_lote_almacen`, el script DEBE comprobar que la operación `EXCEPT` en ambos sentidos devuelva cero filas y que los conteos de filas coincidan exactamente.

### R4 — Transacción reversible
**Historia:** Como responsable de la base, quiero que todas las operaciones se ejecuten dentro de un bloque transaccional con control estricto de errores, para que cualquier fallo devuelva la base a su estado íntegro original.

**Criterios de aceptación (EARS):**
- CUANDO comience la ejecución, el script DEBE activar `\set ON_ERROR_STOP on` e iniciar una transacción explícita con `BEGIN`.
- SI ocurre cualquier error durante alguna de las etapas, ENTONCES el script DEBE detenerse inmediatamente y deshacer todos los cambios realizados.

### R5 — Retiro de la relación original
**Historia:** Como responsable de la base, quiero eliminar la relación original tras verificar la ida, para formalizar el corte de la migración y asegurar que las operaciones dependan de la nueva estructura descompuesta.

**Criterios de aceptación (EARS):**
- CUANDO se haya verificado satisfactoriamente la reconstrucción sin pérdida, el script DEBE eliminar `v_control_lote_almacen` y `control_lote_almacen`.
- CUANDO se elimine `control_lote_almacen`, el script DEBE comprobar mediante `to_regclass` que la tabla ya no exista en el catálogo y emitir una notificación de confirmación.

### R6 — Reversión
**Historia:** Como responsable de la base, quiero disponer de un procedimiento que reconstruya `control_lote_almacen` con su DDL original a partir de las tablas descompuestas, para permitir un retorno seguro al esquema previo si se requiere dar marcha atrás.

**Criterios de aceptación (EARS):**
- CUANDO se ejecute la reversión tras validar LD → C, el script DEBE recrear `control_lote_almacen` con su DDL exacto original (claves primaria y foráneas idénticas).
- CUANDO se pueble `control_lote_almacen` desde `control_lote` y `responsable_deposito` vía JOIN, el script DEBE verificar que el contenido coincida exactamente con la foto previa (diferencias vacías y mismos conteos).
- CUANDO se verifique la relación revertida, el script DEBE eliminar `control_lote` y `responsable_deposito`, comprobando con `to_regclass` su completa remoción del catálogo.

### R7 — Ensayo sin persistencia
**Historia:** Como responsable de la base, quiero validar el ciclo completo de migración, corte y reversión en un ensayo no persistente, para certificar el procedimiento sin alterar permanentemente los datos ni el esquema.

**Criterios de aceptación (EARS):**
- CUANDO finalicen todas las comprobaciones del ensayo, el script DEBE emitir `ROLLBACK` como última instrucción para descartar todos los cambios.
- CUANDO se ejecute el ensayo completo vía psql, el script DEBE permitir canalizar su salida textual a un archivo de evidencia `.txt`.

## Fuera de alcance

- No se implementa un trigger entre tablas para preservar la dependencia funcional LD → C ante futuras escrituras (limitación formal del informe de FNBC, sección 7).
- No se ejecuta sobre `foodstore_dev` ni sobre la base de carga masiva (`foodstore_tp3_carga`).
