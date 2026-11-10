# Ensayos de respaldo y restauración TP8

Fecha: 24 de octubre de 2026, zona America/Buenos_Aires.

Se respaldaron ambas bases PostgreSQL 17 mediante pg_dump en formato custom (-Fc), y se restauraron sucesivamente en foodstore_restore_test, creada desde template0. Se utilizó pg_restore --exit-on-error --no-owner --no-privileges. Los códigos de salida fueron comprobados. Las bases originales se consultaron en modo de lectura y no recibieron cambios. No se modificaron fuentes ni el ZIP de Mateo. El mantenimiento se ejecutó después del ensayo; sus registros están en `salud_mantenimiento/`.

| Ensayo | Respaldo (bytes) | RTO observado | Antigüedad del respaldo al iniciar (proxy RPO) | Validación |
|---|---:|---:|---:|---|
| foodstore_dev, principal | 46.877 | 2,982 s | 0,782 s | Correcta |
| foodstore_tp3_carga, adicional, repetición autorizada | 7.321.779 | 8,194 s | Aproximadamente 272,607 s (4 min 32,607 s) | Correcta |

El RTO del primer ensayo incluye creación de destino, restauración y validaciones. La antigüedad se mide conservadoramente desde el inicio del respaldo hasta el inicio del simulacro: es una aproximación a su frescura, no una medición de pérdida real ni una garantía de RPO. La SPEC inicial del 23/10, anterior a los ensayos, fijaba RPO ≤24 h y RTO ≤15 min (copia en `historial/spec_inicial_20261023.md`). Las observaciones quedan dentro de esas metas locales; no demuestran cumplimiento periódico ni garantizan producción.

En el segundo ensayo el comparador inicial trató como diferentes dos resultados JSON con distinto orden de claves. Sus valores eran iguales. Se corrigió el comparador y se verificaron nuevamente, en vivo, la base fuente y la restaurada. El primer intento no persistió el cronómetro. `ERROR.txt`, conservado solo en la carpeta externa de ensayos originales y no incluido en esta selección, documenta el incidente resuelto del comparador; no indica corrupción o fallo del respaldo.

Tras autorización explícita del usuario para eliminar exclusivamente el destino creado por este procedimiento, se repitió la restauración de carga utilizando el respaldo original válido. Se comprobó primero que el destino coincidía con las métricas de nuestra restauración previa y con la fuente. El nuevo RTO medido fue 8,1943358 segundos, desde inmediatamente antes de crear el destino hasta terminar validaciones correctas; excluye el diagnóstico del intento anterior. La validación concluyó a las 00:37:24,493 UTC-03:00. El archivo timing.json de repeticion_20261024_003713 conserva los tiempos.

Para la repetición, la antigüedad aproximada del respaldo se calculó desde la marca del archivo source_before.json original (00:32:43,629), escrito inmediatamente antes de invocar pg_dump, hasta el inicio del simulacro (00:37:16,236). Son 272,6074609 segundos; el inicio exacto del respaldo original no había quedado guardado, por lo que este proxy conservador es aproximado. No representa pérdida de datos medida. Las evidencias iniciales y `result_initial_attempt.json` permanecen fuera del paquete, en la carpeta externa de ensayos originales. `results.json` y `summary.csv` incluidos reflejan la repetición final.

| Tabla | foodstore_dev: antes = restaurado | foodstore_tp3_carga: antes = restaurado |
|---|---:|---:|
| categoria | 2 | 2 |
| cliente | 3 | 20.003 |
| producto | 3 | 50.003 |
| pedido | 5 | 200.005 |
| detalle_pedido | 7 | 499.571 |
| usuario, verificación adicional | 2 | 3 |

Ambas restauraciones conservaron 6 tablas, 5 vistas y 57 restricciones. Dev contiene 13 índices y carga 16; cada restauración coincide con su origen. La columna real es producto.precio_lista; no producto.precio. Se comprobaron cero precios no positivos, cantidades no positivas, stocks negativos, subtotales inconsistentes y referencias huérfanas, según los indicadores guardados en JSON.

Las validaciones comprueban conteos, objetos e indicadores de integridad; no constituyen una comparación exhaustiva fila a fila ni una prueba de recuperación a un instante con WAL. No se simuló una avería ni se alteraron datos de las fuentes.

La primera base de ensayo, creada y validada durante este procedimiento, fue eliminada para reutilizar el nombre. El sistema de revisión automática rechazó inicialmente eliminar el segundo destino porque la autorización de borrado se limitaba al primer ensayo. Esa eliminación no se ejecutó entonces. El usuario posteriormente autorizó específicamente borrar este segundo destino y repetir el ensayo de carga; la repetición se completó correctamente. foodstore_restore_test conserva ahora esa última restauración de foodstore_tp3_carga.

Los archivos .dump son respaldos completos y pueden contener datos personales y credenciales almacenadas en las tablas. Permanecen fuera de este paquete, en los ensayos originales; conservarlos en un lugar de acceso restringido.

Evidencias: results.json y summary.csv resumen ambos ensayos. Este paquete contiene una selección de métricas, registros y validaciones de origen/restauración; no incluye dumps ni todos los archivos de los ensayos originales. Las rutas externas históricas son referencias de procedencia, no dependencias portables. Un registro vacío significa que la herramienta terminó correctamente sin mensajes; los códigos de salida se verificaron durante la ejecución.

