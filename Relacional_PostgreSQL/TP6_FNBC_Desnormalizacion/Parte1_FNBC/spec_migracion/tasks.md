# Tareas de implementación — Migración FNBC y reversión

## Preparación

- [x] Respaldar foodstore_copia_trabajo antes de ejecutar (protocolo de seguridad) (R1, R4)
- [x] Verificar conexión exclusiva a `foodstore_copia_trabajo` con `\set ON_ERROR_STOP on` y apertura de transacción `BEGIN` (R1, R4)
- [x] Validar en catálogo la existencia de `public.usuario` con columna `id` identity `BIGINT` y ausencia de conflictos de nombres para los objetos a crear (R1)
- [x] Aplicar bloqueo concurrente `LOCK TABLE public.usuario IN SHARE ROW EXCLUSIVE MODE NOWAIT` y verificar usuarios de prueba 801 y 802 (R1)

## Ida

- [x] Crear tablas maestras mínimas `public.lote` y `public.deposito` (R1)
- [x] Insertar registros maestros de prueba en `lote`, `deposito` y usuarios de prueba 801 y 802 en `usuario` (R1)
- [x] Crear relación original `public.control_lote_almacen` con clave primaria y sus tres claves foráneas (R1, R3)
- [x] Cargar instancia de prueba original de 3 tuplas en `control_lote_almacen` (R3)
- [x] Validar dependencia funcional C → D sobre `control_lote_almacen` antes de la descomposición (R2)
- [x] Crear tablas descompuestas `public.responsable_deposito` y `public.control_lote` con sus respectivas PK y FK (R3)
- [x] Migrar tuplas mediante `INSERT ... SELECT DISTINCT` desde la relación original hacia ambas tablas descompuestas (R3)
- [x] Crear vista de reconstrucción `public.v_control_lote_almacen` mediante `JOIN` por `responsable_control_id` (R3)
- [x] Registrar foto de referencia en tabla temporal `ref_control_lote_almacen` (R3, R5)
- [x] Ejecutar comprobación de equivalencia de ida mediante `EXCEPT` bidireccional y comparación de conteos (R3)
- [x] Ejecutar corte formal de la migración retirando `public.v_control_lote_almacen` y `public.control_lote_almacen` (R5)
- [x] Verificar en catálogo con `to_regclass` que `control_lote_almacen` haya sido retirada (R5)

## Vuelta

- [x] Validar cumplimiento de la dependencia funcional LD → C sobre los datos nuevos antes de revertir (R2, R6)
- [x] Recrear `public.control_lote_almacen` aplicando exactamente el DDL original (mismas columnas, PK y 3 FK) (R6)
- [x] Repoblar `control_lote_almacen` mediante `INSERT ... SELECT` a partir del `JOIN` entre `control_lote` y `responsable_deposito` (R6)
- [x] Ejecutar comprobación de equivalencia de reversión comparando `ref_control_lote_almacen` contra `control_lote_almacen` (`EXCEPT` y conteos) (R6)
- [x] Retirar estructura nueva eliminando `public.control_lote` y luego `public.responsable_deposito` en orden estricto de FK (R6)
- [x] Verificar con `to_regclass` que no queden tablas descompuestas ni vistas en el catálogo (R6)
- [x] Consultar el contenido final y conteo de filas de `control_lote_almacen` para verificar su total restitución (R6)

## Evidencia

- [x] Ejecutar el ensayo y guardar la salida en `evidencias/evidencia_reversion_AAAAMMDD_HHMMSS.txt` (R7)
- [x] Verificar en el log que el ensayo finalice con `ROLLBACK` sin dejar cambios persistidos (R4, R7)
- [x] Completar la decisión humana en la DUIA (R7)
