# TP8 | Mantenimiento, respaldo y recuperación

**UTN FRM · Base de Datos II · FoodStore**  
**Operador:** Mateo Liendo (`Mateo_Liendo`)  
**Base ensayada:** `foodstore_dev`  
**Fecha del ensayo:** 26/10/2026 (UTC-03:00)  
**Entorno:** Windows · PostgreSQL 17.10

## Objetivo y entorno

El objetivo fue evaluar el respaldo y la recuperación de la base normal
`foodstore_dev`, correspondiente al esquema original de FoodStore. Se generó
un respaldo, se restauró en una base de prueba y se ejecutaron un diagnóstico y
un mantenimiento controlado sobre esa copia.

La base de origen no fue modificada. El único destino de restauración fue
`foodstore_restore_test`. Los respaldos y sus registros se conservaron fuera
del repositorio, en:

```text
C:\Users\Mateows\TP8_Backups\Mateo_Liendo
```

## Procedimiento y validaciones

El respaldo se generó con `backup_foodstore.ps1` en formato custom mediante
`pg_dump -Fc`. El procedimiento obtuvo una línea base, verificó que el archivo
no estuviera vacío, comprobó su contenido con `pg_restore --list` y calculó su
huella SHA-256.

La restauración se realizó con `restore_test.ps1`, que creó
`foodstore_restore_test` desde `template0`, verificó la huella del respaldo,
ejecutó `pg_restore` y comparó la copia con la línea base.

Se validaron los conteos de cinco tablas y nueve indicadores de integridad.
Los indicadores controlaron valores negativos o no válidos y referencias
huérfanas. La validación no constituye una comparación exhaustiva fila por
fila ni recupera roles y permisos.

## Incidente de autenticación

El primer intento no generó un respaldo porque la autenticación local no
estaba configurada. La ejecución quedó registrada con estado `FAIL`, sin
archivo de respaldo ni huella SHA-256.

El problema se resolvió configurando localmente `pgpass.conf`, sin incluir la
contraseña en scripts, comandos, evidencias ni en este informe. Luego se
verificó la conexión con `foodstore_dev` y se repitió el respaldo
correctamente. El intento fallido se conserva separado como antecedente y no
se presenta como respaldo válido.

## Objetivos y resultados

Las metas de laboratorio fueron RPO de hasta 24 horas y RTO de hasta 15
minutos. La antigüedad del respaldo se utiliza como aproximación de frescura;
no mide por sí sola datos perdidos ni garantiza un RPO.

### Respaldo

El respaldo válido se generó en:

```text
C:\Users\Mateows\TP8_Backups\Mateo_Liendo\
foodstore_dev_20261026_174747_665_990189c9
```

| Indicador | Resultado |
|---|---:|
| Estado | `PASS` |
| Tamaño | 79.722 bytes |
| SHA-256 | `E9F4B863285740BBD328BE9D7D017EA6E18BF133949A6ED2148162532A263905` |
| Error | `null` |

El SHA-256 fue calculado nuevamente y coincidió con el registrado en
`metadata.json`. También se verificaron los logs de `pg_dump` y
`pg_restore --list`.

### Línea base y restauración

| Tabla | Antes | Restaurada |
|---|---:|---:|
| `categoria` | 2 | 2 |
| `cliente` | 3 | 3 |
| `producto` | 3 | 3 |
| `pedido` | 5 | 5 |
| `detalle_pedido` | 7 | 7 |

Los nueve indicadores de integridad dieron cero antes y después de la
restauración.

La restauración válida quedó registrada en:

```text
C:\Users\Mateows\TP8_Backups\Mateo_Liendo\restore_results\
restore_20261026_175102_843_9442e35e\result.json
```

| Indicador | Resultado | Meta |
|---|---:|---:|
| Estado | `PASS` | — |
| RTO observado | 1,6352297 s | ≤ 15 min |
| Antigüedad aproximada | 195,1630011 s | ≤ 24 h |
| Error | `null` | — |

El destino no existía antes de la restauración, por lo que no fue necesario
borrar ni reutilizar una base de prueba existente.

## Mantenimiento justificado

El diagnóstico se ejecutó sobre `foodstore_restore_test` y finalizó con
`ROLLBACK`. Registró PostgreSQL 17.10, cero deadlocks acumulados, cero tuplas
muertas en las relaciones informadas y autovacuum activo.

El mantenimiento se aplicó únicamente sobre la copia restaurada. Se ejecutó
`ANALYZE VERBOSE` sobre `categoria`, `usuario` y
`mv_resumen_ventas_categoria_mes`, que no tenían estadísticas de columnas
antes del mantenimiento.

| Relación | Estadísticas antes | Estadísticas después |
|---|---:|---:|
| `categoria` | 0 | 5 |
| `usuario` | 0 | 9 |
| `mv_resumen_ventas_categoria_mes` | 0 | 6 |

La validación informó:

```text
VALIDACION: conteos exactos preservados.
```

No se ejecutó `VACUUM FULL` ni se aplicó mantenimiento sobre `foodstore_dev`.

## Evidencias y control humano

Las evidencias externas del ensayo se conservaron en:

- respaldo y metadatos:
  `C:\Users\Mateows\TP8_Backups\Mateo_Liendo\foodstore_dev_20261026_174747_665_990189c9`;
- restauración:
  `C:\Users\Mateows\TP8_Backups\Mateo_Liendo\restore_results`;
- diagnóstico:
  `C:\Users\Mateows\TP8_Backups\Mateo_Liendo\health_check`;
- mantenimiento:
  `C:\Users\Mateows\TP8_Backups\Mateo_Liendo\maintenance`.

Cada operación sobre la base fue realizada manualmente por el operador,
siguiendo una autorización separada: respaldo, restauración, diagnóstico y
mantenimiento. La base original no recibió cambios.

Los archivos `.dump` permanecen fuera del repositorio porque contienen los
datos completos de la base y la tabla `usuario`, que incluye hashes de
contraseñas.

## Conclusión

El respaldo de `foodstore_dev`, realizado por Mateo Liendo, finalizó con
`PASS`, fue verificado mediante tamaño, hash y lectura de contenido, y pudo
restaurarse correctamente en `foodstore_restore_test`.

Los conteos coincidieron, los controles de integridad dieron cero y el
mantenimiento preservó los conteos. El RTO observado y la frescura aproximada
del respaldo quedaron dentro de las metas de laboratorio. El ensayo se realizó
en un entorno local y con una única ejecución, por lo que no demuestra por sí
solo el comportamiento de una política periódica en producción.
