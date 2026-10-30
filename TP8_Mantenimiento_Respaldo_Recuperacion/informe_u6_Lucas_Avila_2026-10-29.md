# TP8 | Mantenimiento, respaldo y recuperación

**UTN FRM · Base de Datos II · FoodStore**<br>
**Operador:** Lucas Avila · **Base ensayada:** `foodstore_dev` (equivale a `foodstore` de la consigna) · **Fecha:** 29/10/2026 (UTC-03:00) · **Entorno:** Windows · PostgreSQL 17.11

## Informe post-incidente

Simulacro: se supone perdido Food Store y se reconstruye el servicio en `foodstore_restore_test` con el último respaldo válido, sin modificar la base de origen.

| Dato | Valor |
|---|---|
| Respaldo utilizado | `foodstore_dev_20261029_210621_831_b06344f9.dump`, generado el 29/10/2026 a las 21:06 |
| Estado, tamaño y huella | `PASS` · 22.846 bytes · SHA-256 `7E84B858…E25580F8` (completo en el anexo) |
| Restauración y validación | de 21:26:27 a 21:26:28 |
| **RTO** | previsto ≤ 15 min · **observado 0,93 s** |
| **RPO** (antigüedad del respaldo) | previsto ≤ 24 h · **observado 1.205,9 s (≈ 20 min 6 s)** |

Las metas son las de laboratorio fijadas en la SPEC del grupo (respaldo diario). La antigüedad del respaldo es solo una aproximación al RPO: no mide datos realmente perdidos. El RTO corresponde a una base de 20 filas en las cinco tablas principales, en un equipo local; no puede extrapolarse a una base real.

## Validaciones

- **Conteos restaurados = línea base:** `categoria` 2, `cliente` 3, `producto` 3, `pedido` 5, `detalle_pedido` 7.
- **Nueve controles lógicos** (precios, stock, cantidades, subtotales y referencias huérfanas): 0 antes del respaldo y 0 después de restaurar.
- **Diagnóstico** (`health_check.sql`, 21:30, solo lectura): 0 tuplas muertas, 0 deadlocks, autovacuum activo y ninguna sesión activa ajena al chequeo.
- **Mantenimiento** (`maintenance.sql`, 21:32, solo sobre la copia): las 7 relaciones no tenían estadísticas del planificador (`last_analyze` vacío) y el autovacuum no iba a actuar, porque su umbral es de 50 filas modificadas más el 10 % de la tabla y estas tienen entre 2 y 7 filas. Se justificó un `ANALYZE` puntual: columnas con estadísticas de 0 a 5 en `categoria`, de 0 a 9 en `usuario` y de 0 a 6 en la vista materializada. Los conteos quedaron preservados. No se hizo `VACUUM` (0 tuplas muertas) ni `VACUUM FULL`.

## Problemas encontrados

1. **Autenticación.** La prueba con `-w` falló con `fe_sendauth: no password supplied` porque la línea de `pgpass.conf` tenía espacios al inicio. Se quitaron y la conexión funcionó. La contraseña no figura en scripts, comandos ni evidencias.
2. **Esquema incompleto.** `maintenance.sql` usa `public.usuario` y `public.mv_resumen_ventas_categoria_mes` (TP5), que mi `foodstore_dev` no tenía porque solo contenía el esquema del TP1. Se agregaron con `usuarios.sql`, `usuarios_datos.sql` y `vista_materializada.sql`, y se repitieron el respaldo y la restauración. Antes de repetir se eliminó `foodstore_restore_test` del primer ensayo, tras comprobar que no tenía conexiones y confirmando con `dropdb -i`. `foodstore_dev` nunca se borró ni se recreó. El primer ensayo (respaldo de las 20:55, RTO 0,84 s, antigüedad 238 s) se conserva como antecedente.

## Mejora propuesta

Ejecutar `ANALYZE` sobre **todas** las tablas al terminar de restaurar. El diagnóstico mostró las 7 relaciones sin estadísticas, pero `maintenance.sql` solo cubre `categoria`, `usuario` y la vista materializada: `cliente`, `pedido`, `producto` y `detalle_pedido` quedaron sin analizar. Incorporarlo al final de `restore_test.ps1` evitaría que una copia restaurada trabaje a ciegas. También conviene documentar que `foodstore_dev` requiere el esquema del TP1 más los objetos del TP5.

## Uso de IA y control humano

Usé Claude (Anthropic) como guía paso a paso: explicó cada comando antes de ejecutarlo, leyó los scripts y SQL del repositorio y me ayudó a interpretar las salidas. No tuvo acceso a mi PostgreSQL ni a mi contraseña. Los scripts de respaldo, restauración y mantenimiento son los del grupo (generados con asistencia de IA, según la SPEC) y no los modifiqué. Cada comando lo escribí y ejecuté yo, y revisé cada resultado antes de continuar. Verificaciones propias: 14 de 14 pruebas simuladas, comparación de conteos y de los nueve controles contra la línea base, y confirmación del nombre del destino antes de cada borrado.

**Conclusión.** El respaldo de `foodstore_dev` se restauró en `foodstore_restore_test` con conteos idénticos, controles en cero y tiempos muy por debajo de las metas. Fue una única ejecución en un entorno local, por lo que no demuestra por sí sola el comportamiento de una política periódica.

<div class="pagebreak"></div>

## Anexo: evidencias

**Cronología (29/10/2026)**

| Hora | Hecho |
|---|---|
| antes de los ensayos | `test_delivery.ps1`: `PASS 14 checks` |
| 20:55 | Respaldo de ensayo con esquema TP1: 17.864 bytes, `PASS` |
| 20:59 | Restauración de ensayo: RTO 0,84 s, antigüedad 238,4 s, `PASS` |
| entre 21:00 y 21:05 | Se agregan a `foodstore_dev` los objetos del TP5 |
| 21:06 | **Respaldo oficial:** 22.846 bytes, `PASS` |
| antes de 21:26 | Se elimina `foodstore_restore_test` del ensayo (0 conexiones, confirmación `dropdb -i`) |
| 21:26 | **Restauración oficial:** RTO 0,93 s, antigüedad 1.205,9 s, `PASS` |
| 21:30 | `health_check.sql` sobre la copia restaurada |
| 21:32 | `maintenance.sql` sobre la copia restaurada: conteos preservados |

**Huellas SHA-256**

- Oficial: `7E84B8589D810CB4E14630C5A3E906C5C4DC9E5D5220F7B58AE12598E25580F8`
- Ensayo: `8D0DDB34438D0281F94D4F036C66689E3695E55327FD25D0317C60081CDC847F`

**Nueve controles lógicos (todos en 0):** `producto_precio_negativo`, `producto_stock_negativo`, `detalle_cantidad_no_positiva`, `detalle_precio_negativo`, `detalle_subtotal_incorrecto`, `producto_categoria_huerfana`, `pedido_cliente_huerfano`, `detalle_pedido_huerfano`, `detalle_producto_huerfano`.

**Ubicación de las evidencias** (fuera del repositorio, en `C:\Users\Lucas\TP8_Backups\Lucas_Avila\`):

- respaldo oficial: `foodstore_dev_20261029_210621_831_b06344f9\` (`.dump`, `metadata.json`, `baseline.json`, `logs\`);
- restauración oficial: `restore_results\restore_20261029_212627_703_13530475\result.json`;
- diagnóstico: `health_check_restore_test.log`; mantenimiento: `maintenance.log`;
- ensayo previo: `foodstore_dev_20261029_205518_679_5d3dbade\` y `restore_results\restore_20261029_205917_029_b24d3d43\`.

**Comandos ejecutados** (desde la carpeta del repositorio, con `-NoProfile -ExecutionPolicy RemoteSigned` solo para cada ejecución):
`test_delivery.ps1` · `backup_foodstore.ps1 -SourceDatabase foodstore_dev -OutputDirectory …\Lucas_Avila` · `restore_test.ps1 -MetadataPath …\metadata.json -OutputDirectory …\restore_results` · `psql -X -w … -d foodstore_restore_test -f health_check.sql` · `psql -X -w … -d foodstore_restore_test -f maintenance.sql`.

Los `.dump` no se entregan: contienen todos los datos de la base y la tabla `usuario`, que guarda hashes de contraseñas (en esta base, valores de ejemplo). Su creación, tamaño, huella y restauración exitosa constan en este anexo.
