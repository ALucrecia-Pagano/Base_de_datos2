# Respaldo programado (objetivo 7 del TPI)

## Qué se programó
Se registró la tarea `FoodStore_Respaldo_Diario` en el Programador de tareas de Windows con ejecución diaria a las 23:00, que invoca `backup_foodstore.ps1` (Unidad 6) sobre la base `foodstore_dev`. Cada corrida deja en `%USERPROFILE%\TP8_Backups` el archivo `.dump`, su hash SHA-256 en `metadata.json` y los conteos de control en `baseline.json`. Esto cubre el RPO de diseño de 24 horas fijado en el informe de la Unidad 6.

## Cómo se registra y cómo se quita
Para registrar la tarea diaria:
`powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\Relacional_PostgreSQL\TP8_Mantenimiento_Respaldo_Recuperacion\programacion\registrar_respaldo_programado.ps1`

Para quitar la tarea programada:
`powershell.exe -NoProfile -ExecutionPolicy RemoteSigned -File .\Relacional_PostgreSQL\TP8_Mantenimiento_Respaldo_Recuperacion\programacion\quitar_respaldo_programado.ps1`

## Prueba realizada
| Campo | Valor registrado |
| --- | --- |
| Fecha y hora previa (`$antes`) | `2026-11-10 23:17:44.838 -03:00` |
| Disparo | `Start-ScheduledTask -TaskName 'FoodStore_Respaldo_Diario'` (corrida por el Programador, no a mano) |
| `LastRunTime` | `10/11/2026 23:17:47` |
| `LastTaskResult` | `0` |
| `status` | `PASS` |
| Inicio (`started_at`) | `2026-11-10T23:17:48.9253116-03:00` |
| Fin (`finished_at`) | `2026-11-10T23:17:50.8187032-03:00` |
| Duración (`finished_at - started_at`) | `1,893 s` |
| `dump_bytes` | `46877` |
| `dump_sha256` | `A5FEFDBA89565CBF60F5C9F14E1B527AC59C3D3681D56919C166D94F1C2B280B` |

Evidencias recolectadas de la corrida:
- [Información de ejecución de la tarea](./evidencias_20261110/tarea_info.txt)
- [Definición XML exportada del Programador](./evidencias_20261110/tarea_definicion.xml)
- [Metadata y hash del respaldo](./evidencias_20261110/metadata.json)
- [Conteos de línea base](./evidencias_20261110/baseline.json)

## Tareas de mantenimiento relacionadas
Las tareas complementarias del plan de mantenimiento siguen como se implementaron y probaron en la Unidad 6 sobre la base de prueba de restauración:
- Estadísticas y limpieza: [../maintenance.sql](../maintenance.sql)
- Verificación de integridad: [../health_check.sql](../health_check.sql)
- Restauración probada: [../restore_test.ps1](../restore_test.ps1)

## Limitaciones
- La tarea corre solo con la sesión de Windows iniciada (para no guardar contraseñas en el Programador de tareas).
- El servicio de PostgreSQL se inicia a mano en esta máquina y, si está detenido a esa hora, el respaldo falla y queda registrado como `FAIL` en `metadata.json`.
- No hay rotación automática, por lo que los respaldos viejos se borran a mano.
- La tarea guarda la ruta absoluta de `backup_foodstore.ps1`. Si el repositorio se mueve o se vuelve a clonar en otra carpeta, hay que quitar la tarea y registrarla de nuevo; si no, la tarea falla sin llegar a correr el script y sin dejar `metadata.json`. Una falla de ese tipo solo se ve en el `LastTaskResult` de `Get-ScheduledTaskInfo`, por eso el control diario revisa las dos cosas.

## DUIA
| Herramienta | Finalidad | Fecha |
| --- | --- | --- |
| Antigravity (Gemini) | Crear los scripts de registro y baja, ejecutar la prueba y recolectar la evidencia | 2026-11-10 |
| Claude (chat) | Armar el prompt y el contenido de los scripts de registro y baja | 2026-11-10 |

## Decisión humana
Elegí programar el mismo backup_foodstore.ps1 de la Unidad 6 en lugar de escribir uno nuevo, porque ya estaba probado y deja su metadata con el hash y los conteos de control. Lo dejé diario a las 23 porque coincide con el RPO de 24 horas que fijamos en el informe de esa unidad. La tarea corre solo con mi sesión iniciada para no guardar ninguna contraseña en el Programador de tareas; la conexión sale del pgpass.conf que ya usaba. Como en mi máquina el servicio de PostgreSQL arranca a mano, un día que esté apagado el respaldo va a fallar, pero queda registrado como FAIL y no pasa desapercibido. Esa es la principal limitación y la dejo anotada.
