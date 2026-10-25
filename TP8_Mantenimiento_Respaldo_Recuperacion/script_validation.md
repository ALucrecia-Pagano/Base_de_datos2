# Validación de scripts de entrega

## Estado actual de la revisión de cierre

El baseline del 24/10/2026 fue BLOQUEADO por la política de Windows PowerShell 5.1 antes de ejecutar la suite. No se cambió la política ni se usó Bypass. Por indicación posterior del usuario, los scripts y `pruebas/test_delivery.ps1` permanecen intactos; no hay RED/GREEN actual de las correcciones propuestas. Los resultados 12/12 y ejecuciones reales descriptos abajo son exclusivamente HISTÓRICOS. Las propuestas y el comando/error completo están en [la revisión de cierre](docs/cierre_revision_20261024.md).

El validador comprueba cinco conteos y nueve indicadores. El dump lleva fecha, hora e id en el nombre, y el diagnóstico termina con ROLLBACK. Siguen sin implementarse la imposición de ruta externa, el rechazo explícito de colisiones y el registro por etapa. Estos cambios todavía no se probaron con la suite ni contra PostgreSQL.

Fecha: 24/10/2026 (Argentina). Scripts nuevos, sin baseline previo. No se modificó el repositorio de Mateo ni las bases fuente.

## Antecedente histórico: TDD y controles aislados

RED ejecutado antes de implementar: fallo por ausencia de `backup_foodstore.ps1`. Luego se implementaron los tres scripts; el ensayo completo detectó un error de conversión de fechas de `ConvertFrom-Json` en PowerShell 7.6; se corrigió usando conversión explícita a DateTimeOffset.

GREEN: 12 controles de comportamiento aprobados en PowerShell 7.6.5 y Windows PowerShell 5.1. La copia entregable de pruebas también pasó 12/12. Ejecutar: `& .\pruebas\test_delivery.ps1`. Usa herramientas simuladas en una carpeta temporal, sin conexiones a PostgreSQL.

| Comportamiento | Casos ejecutados |
|---|---|
| Respaldo | Ambas fuentes admitidas; fuente prohibida rechazada; pg_dump exit 7 provoca fallo; éxito requiere dump no vacío y SHA256 |
| Seguridad destino | Destino existente impide createdb y pg_restore; destino ausente permite flujo aislado; ninguna llamada dropdb |
| Restauración | pg_restore exit 9 rechazado; éxito con métricas coincidentes |
| Validación | Conteo diferente rechazado; filas inválidas rechazadas; métricas correctas aceptadas; orden JSON diferente aceptado; hash alterado rechazado antes de restaurar |
| Evidencia | Cinco fallos de recuperación persisten result.json; éxito registra RTO y proxy RPO |

| Tarea | Prueba | Capa | Safety Net | RED | GREEN | Triangulación | Refactor |
|---|---|---|---|---|---|---|---|
| Respaldo y restauración segura | pruebas/test_delivery.ps1 | Integración aislada de scripts | Nuevos; no aplicable | Script ausente | 12/12 en ambos shells | Éxito, fallos nativos, destino existente y métricas divergentes | Logs separados; pruebas verdes |

## Antecedente histórico: prueba real adicional de los scripts de entrega

El primer intento dentro del entorno restringido falló por bloqueo TCP local (10013); quedó manifest FAIL. Se repitió con permiso de acceso local y ambos respaldos nuevos terminaron PASS, con pg_restore --list y hash verificados:

- foodstore_dev: 46.877 bytes; conteos categoria=2, cliente=3, producto=3, pedido=5, detalle_pedido=7.
- foodstore_tp3_carga: 7.321.779 bytes; conteos categoria=2, cliente=20.003, producto=50.003, pedido=200.005, detalle_pedido=499.571.
- En ambas fuentes: cero filas inválidas según los cuatro controles de estos scripts (precios y stock >=0; cantidad >0; NULL rechazado).
- Guardia real de restore: detectó foodstore_restore_test existente y abortó antes de createdb/pg_restore. Resultado FAIL esperado, sin RTO porque no se inició recuperación.

Evidencias adicionales del paquete: `evidencias/validacion_scripts_nuevos/` (líneas base, metadatos, catálogos y guardia de destino). Los originales completos se conservan en `work/validacion_real_scripts/`; intento restringido: `work/validacion_scripts_intento_sandbox/`. Se excluyeron dumps nuevos del paquete para evitar duplicar los respaldos previos.

La restauración completa con estos scripts nuevos fue comprobada mediante herramientas simuladas. Los ensayos reales anteriores (2,98 s y 8,19 s) pertenecen al procedimiento previo y están documentados por separado: no deben atribuirse a esta versión.

## Uso y límites

Se requieren herramientas PostgreSQL 17 y autenticación ya configurada por el usuario; los scripts usan -w (no solicitan contraseña), no guardan credenciales ni cambian configuración. No contienen borrado de bases. Destino fijo foodstore_restore_test; si existe, se conserva y el script aborta. Una falla posterior a createdb conserva el destino para diagnóstico.

`pg_common.ps1` debe permanecer junto a los dos scripts. OutputDirectory puede cambiarse; si se mueve el dump, usar -DumpPath junto a MetadataPath. La comparación de cinco tablas y nueve indicadores verifica esos controles, no equivalencia total de todos los objetos. Baseline y pg_dump se toman en instantes distintos: ejecutar sin escrituras concurrentes si se desea comparar los conteos exactamente. RTO va desde antes de createdb hasta terminar validaciones; RPO es únicamente antigüedad del inicio del respaldo al inicio de recuperación.

El registro histórico declara que Windows PowerShell 5.1 requirió ExecutionPolicy Bypass solo para aquel proceso de pruebas. Se conserva como antecedente, no como instrucción de reproducción: en esta revisión está prohibido y no se utilizó. Los resultados históricos no resuelven el bloqueo actual.


Integración con entrega en repositorio: el destino por defecto de respaldos se cambió mecánicamente a la carpeta TP8_Backups del perfil del usuario (en este equipo C:/Users/hp/TP8_Backups), fuera del repositorio. Cada ejecución crea un subdirectorio único: no sobrescribe foodstore_origen.dump ni otros archivos previos. OutputDirectory permite otra ubicación externa. Antes y después del ajuste: 12/12 controles aislados aprobados en PowerShell7.6.5 y Windows PowerShell5.1. No se ejecutaron nuevas conexiones PostgreSQL ni se escribió en la carpeta externa durante esta comprobación; las pruebas usan OutputDirectory temporal explícito. La expresión predeterminada es un ajuste mecánico de ruta, sin prueba de integración real en el perfil del usuario.
