# TP8 | Mantenimiento, respaldo y recuperación

UTN FRM · Base de Datos II · FoodStore
Alumna: Pagano Amanda · Comisión 4 · Profesor: Neira Sergio
Fecha de los ensayos: 24/10/2026 (UTC-03:00)

## Objetivo y entorno

Evaluar la recuperación de FoodStore en un laboratorio Windows con PostgreSQL 17.11. Se ensayaron dos bases:

- `foodstore_dev`: el esquema original del TP1, como adaptación local de la base `foodstore` de la consigna.
- `foodstore_tp3_carga`: la base con carga masiva utilizada desde el TP3 en optimización, reportes e índices (TP3 a TP5). Por su volumen es la más representativa de un uso real, y permite ver cómo crece el tiempo de recuperación.

El destino descartable fue `foodstore_restore_test`. Las bases originales no se modificaron.

## Procedimiento y validaciones

Se generaron respaldos en formato custom con `pg_dump -Fc`. Para restaurar, se creó el destino desde `template0` y se ejecutó `pg_restore --exit-on-error --no-owner --no-privileges`. Cada origen se ensayó por separado, uno después del otro. Autoricé por separado cada borrado de `foodstore_restore_test`.

Antes del respaldo y después de la restauración se registraron estos conteos exactos:

| Tabla | Dev antes | Dev restaurado | Carga antes | Carga restaurada |
|---|---:|---:|---:|---:|
| categoria | 2 | 2 | 2 | 2 |
| cliente | 3 | 3 | 20.003 | 20.003 |
| producto | 3 | 3 | 50.003 | 50.003 |
| pedido | 5 | 5 | 200.005 | 200.005 |
| detalle_pedido | 7 | 7 | 499.571 | 499.571 |

Los nueve indicadores de integridad dieron cero en ambos ensayos. Esos indicadores son:
- precios no positivos;
- stock negativo;
- cantidades no positivas;
- subtotales incorrectos;
- cuatro tipos de referencias huérfanas.

Las restauraciones conservaron también 6 tablas, 5 vistas y 57 restricciones. La validación compara conteos e indicadores, no fila por fila. La restauración no incluye roles ni permisos.

## Objetivos y resultados

Respaldos utilizados:
- **Dev:** iniciado a las 00:32:38,094, con 46.877 bytes.
- **Carga:** 7.321.779 bytes, con marca registrada a las 00:32:43,629, justo antes de iniciar el respaldo. Es el mismo respaldo que se reutilizó en la repetición.

| Indicador | Meta (SPEC 23/10) | Dev | Carga (repetición) |
|---|---|---:|---:|
| RTO observado | ≤ 15 minutos | 2,9817064 s | 8,1943358 s |
| Antigüedad del respaldo al iniciar (aproximación al RPO) | RPO ≤ 24 horas | 0,7817533 s | aprox. 272,6074609 s |

El RTO se mide desde inmediatamente antes de crear el destino hasta que terminan las validaciones.

La antigüedad del respaldo indica qué tan fresco era, pero no mide datos perdidos: las bases originales no recibieron escrituras durante el ensayo. El RPO de diseño lo fija la frecuencia diaria del respaldo, es decir, hasta 24 horas.

En carga, la antigüedad es mayor porque la restauración se repitió con el mismo respaldo. Como el inicio exacto de ese respaldo no quedó registrado, se usó la marca tomada justo antes.

Las metas se fijaron el 23/10, antes de los ensayos, y los valores observados quedan dentro de ellas. Es una medición única en un laboratorio local, sin programación periódica instalada.

## Mantenimiento justificado

El diagnóstico registró cero consultas ajenas activas y cero deadlocks acumulados en ese momento. Autovacuum y autoanalyze ya habían actuado sobre las tablas grandes. En cambio, `categoria`, `usuario` y `mv_resumen_ventas_categoria_mes`, por su tamaño reducido, no tenían estadísticas en la copia restaurada. Por eso se aplicó `ANALYZE` solo a esas tres relaciones y solo en el destino:
- conservaron 2, 3 y 26 filas;
- sus columnas con estadísticas pasaron de 0 a 5, 9 y 6.

No se aplicó VACUUM ni VACUUM FULL: las tablas grandes no tenían tuplas muertas y la consigna excluye VACUUM FULL como mantenimiento periódico. Tampoco se hizo mantenimiento sobre las bases originales.

## Incidente

En el primer intento con la base de carga se detectó una diferencia entre origen y restaurada. Los valores eran iguales: solo cambiaba el orden de las claves del JSON.

Se corrigió la comparación para que fuera por valor, y se verificaron nuevamente, en vivo, la fuente y la restaurada. Autoricé borrar solo ese destino y repetir la restauración. El RTO informado es el de la repetición.

`restore_test.ps1` ya incorpora las dos lecciones: compara tabla por tabla, así que no depende del orden de las claves, y guarda el resultado aunque falle.

## Uso de IA y control humano

**Controles propios previos a los ensayos.** Con `psql` desde PowerShell:
- ejecuté los `COUNT(*)` de las cinco tablas en ambas bases, y coinciden con las líneas base;
- inspeccioné la estructura de `producto` y `detalle_pedido` con `\d`, y así se identificó que la columna real es `precio_lista` y no `precio`;
- corrí las validaciones de precio, stock y cantidad, que dieron cero.

También generé un respaldo preparatorio de `foodstore_tp3_carga` con `pg_dump -Fc`: comprobé el código de salida 0 y lo verifiqué con `pg_restore --list`. Decidí que el respaldo se hiciera sobre la base original y no sobre una copia, por eso `foodstore_dev` es el origen principal.

**Asistencia de IA.** La SPEC inicial se redactó con asistencia de IA. Codex generó los scripts y ejecutó los ensayos finales. La cátedra admite el uso de agentes, y se utilizó Codex en lugar de OpenCode.

Cada operación sobre las bases requirió mi autorización: respaldos, borrado de cada destino, repetición y `ANALYZE`. Hay dos constancias en las evidencias:
- mi autorización textual ("si autorizo") en `repeticion/timing.json`;
- el caso del segundo borrado, registrado en `evidencias/LEEME.md`: cuando Codex intentó borrar el segundo destino apoyándose en la autorización del primero, el sistema de revisión de la herramienta lo bloqueó, y el borrado se hizo solo después de mi autorización específica.

**Pruebas de los scripts finales.**
- `backup_foodstore.ps1` se ejecutó con ambas bases y terminó en PASS.
- La guarda de `restore_test.ps1` abortó sin borrar el destino existente, tal como estaba diseñada.
- El RTO informado proviene del ensayo previo, no de ese script.

**Revisión posterior.** No leí en detalle los cuatro scripts antes de su ejecución. Los revisé después con Claude Code, que también usé para auditar este informe y la SPEC y para contrastar los números con las evidencias. Los cambios los decidí yo.

## Mejora y conclusión

Mejora para la próxima ejecución: respaldar también roles y permisos con `pg_dumpall --globals-only`, restaurarlos antes del dump y quitar `--no-owner --no-privileges` de la restauración. Hoy se recuperan los datos, pero no los dueños ni los permisos. Además, programar el respaldo diario con el Programador de tareas de Windows haría que el RPO de 24 horas no dependa de ejecutarlo a mano.

Conclusión: las dos bases se recuperaron con conteos idénticos e indicadores de integridad en cero, con tiempos muy por debajo de las metas, en un laboratorio local.

Evidencias:
- `evidencias/results.json`;
- `evidencias/LEEME.md`;
- `evidencias/foodstore_tp3_carga/repeticion/timing.json`;
- `evidencias/salud_mantenimiento/`.

Los respaldos `.dump` se conservan fuera del repositorio.