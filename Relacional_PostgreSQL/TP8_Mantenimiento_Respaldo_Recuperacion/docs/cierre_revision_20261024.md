# Revisión de cierre TP8 - 24/10/2026

## Alcance y estado

Se contrastó la auditoría con los archivos actuales, AGENTS, protocolo y consigna PDF. Al bloquearse el baseline, el usuario indicó conservar el comportamiento de los scripts. Se actualizaron el informe y documentación; las propuestas siguientes NO están aplicadas ni verificadas mediante ejecución. No se consultó un informe de Mateo: se utilizó la estructura indicada por el usuario y únicamente datos de este TP8.

No se ejecutaron SQL, conexiones PostgreSQL, respaldos, restauraciones o mantenimiento reales. No se cambiaron políticas, permisos ni configuración; no se hicieron operaciones de escritura de git. Scripts, pruebas, consigna, todos los archivos de `evidencias/` y las dos SPEC históricas se conservan intactos.

## Estado de las pruebas

| Tipo | Estado y alcance |
|---|---|
| Baseline actual | BLOQUEADO antes de iniciar `pruebas/test_delivery.ps1`, en Windows PowerShell 5.1. Ninguna prueba aprobada actual. |
| RED/GREEN de correcciones | PENDIENTE. Código y suite sin cambios. |
| 12/12 en PowerShell 7.6.5 y 5.1 | Resultado HISTÓRICO declarado; no repetido en este cierre. |
| Restauraciones reales históricas | JSON coincidentes y tiempos conservados; no atribuirlas a scripts finales. |
| Validación real posterior | Metadatos PASS de dos respaldos y FAIL esperado de guardia de destino existente. No demuestra restauración completa del script final. |
| Controles estáticos actuales | Sintaxis y coherencia documental, sin equivalencia con pruebas de comportamiento o SQL en vivo. |

Comando exacto intentado desde `C:\Users\hp\Practicos`:

```powershell
& .\TP8_Mantenimiento_Respaldo_Recuperacion\pruebas\test_delivery.ps1
```

Error completo devuelto por la herramienta (línea 2 del bloque envolvente, no del test):

```text
& : No se puede cargar el archivo
C:\Users\hp\Practicos\TP8_Mantenimiento_Respaldo_Recuperacion\pruebas\test_delivery.ps1 porque la ejecución de scripts
está deshabilitada en este sistema. Para obtener más información, consulta el tema about_Execution_Policies en
https:/go.microsoft.com/fwlink/?LinkID=135170.
En línea: 2 Carácter: 384
+ ... cy -List; & .\TP8_Mantenimiento_Respaldo_Recuperacion\pruebas\test_de ...
+                 ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : SecurityError: (:) [], PSSecurityException
    + FullyQualifiedErrorId : UnauthorizedAccess
```

`Get-ExecutionPolicy -List` informó Undefined en MachinePolicy, UserPolicy, Process, CurrentUser y LocalMachine. Undefined no significa que los scripts estén permitidos. No se usaron Bypass, Unblock-File, ejecución del test como texto ni cambios de política. No se encontraron `pwsh` ni Docker disponibles; `wsl --list --quiet` informó que WSL no está instalado. No se instaló ningún shell. Una opción permitida es ejecutar la copia revisada en un equipo del grupo que ya permita scripts bajo su configuración habitual; esa ejecución no está acreditada aquí. No se encontró una alternativa local ya disponible que permita repetir la suite sin eludir la restricción.

## Propuestas de código NO aplicadas

### Validador alineado con la SPEC

`pg_common.ps1` contiene cuatro indicadores. Agregar al JSON `invalid` las siguientes cinco expresiones, y exigir presencia y valor cero en `Assert-Valid`:

```sql
'detalle_subtotal_incorrecto', (
  SELECT count(*) FROM public.detalle_pedido dp
  WHERE dp.subtotal IS DISTINCT FROM (dp.cantidad * dp.precio_unitario)
),
'producto_categoria_huerfana', (
  SELECT count(*) FROM public.producto p
  WHERE NOT EXISTS (SELECT 1 FROM public.categoria c WHERE c.id = p.id_categoria)
),
'pedido_cliente_huerfano', (
  SELECT count(*) FROM public.pedido p
  WHERE NOT EXISTS (SELECT 1 FROM public.cliente c WHERE c.id = p.id_cliente)
),
'detalle_pedido_huerfano', (
  SELECT count(*) FROM public.detalle_pedido dp
  WHERE NOT EXISTS (SELECT 1 FROM public.pedido p WHERE p.id = dp.id_pedido)
),
'detalle_producto_huerfano', (
  SELECT count(*) FROM public.detalle_pedido dp
  WHERE NOT EXISTS (SELECT 1 FROM public.producto p WHERE p.id = dp.id_producto)
)
```

Se contrastaron nombres de FK con el esquema documentado; no se comprobó una instalación actual. El esquema documentado exige FK no nulas: estas consultas rechazan también referencias NULL. Mantener los controles actuales de no negativos y NULL. Los metadatos antiguos que solo tienen cuatro indicadores deberán rechazarse por cobertura insuficiente, sin alterarlos ni inventar métricas. El SQL propuesto no fue ejecutado.

### Respaldo fechado, externo y sin sobrescritura

- Usar una sola marca para directorio y dump: `<base>_<yyyyMMdd_HHmmss_fff>_<id>.dump`.
- Antes de crear archivos o invocar herramientas, determinar raíz del repositorio recorriendo ancestros hasta `.git`; fallar si no se identifica. Normalizar `OutputDirectory`, comparar sin distinguir mayúsculas en Windows y con límites de directorio, rechazando la raíz y descendientes, incluidos `..`. Admitir hermanos externos cuyo nombre solo comparta prefijo.
- Rechazar puntos de reanálisis en ancestros existentes para impedir que una ruta aparente externa dirija al repositorio. No cambiar ACL.
- En ambos scripts, crear el directorio de ejecución sin `-Force` y detenerse ante colisión. Nunca reutilizarlo ni sobrescribir archivos como recuperación de un fallo.

### Registro explícito y objetivos separados

Registrar cada etapa conocida (`baseline`, `pg_dump`, `archive_list`, `destination_check`, `createdb`, `restore`, `validation`) con herramienta, inicio, fin, código de salida y resultado. Persistir fallos desde `finally`. Si no arranca, guardar código nulo y estado diferenciado; no inventar un código nativo. Registrar la etapa, no la línea de comandos completa, para evitar copiar SQL o credenciales; no registrar variables de autenticación. Conservar logs existentes y no rellenar retrospectivamente los vacíos.

Separar `status` operativo de `rto_goal_met` (cronómetro <=900 s) y `freshness_proxy_within_24h` (antigüedad <=86400 s). El segundo campo no acredita RPO real. Usar nulo si falta medición. No agregar programación, alertas, retención automática ni un sistema de permisos.

### Cierre del diagnóstico

Propuesta pendiente: cambiar el cierre futuro de `health_check.sql` de `COMMIT;` a `ROLLBACK;`. El archivo actual conserva COMMIT, al igual que los logs históricos. La transacción histórica era READ ONLY; no afirmar que ese COMMIT modificó filas. La guía ya no lo presenta como si esta corrección estuviera aplicada.

## Plan TDD pendiente

Interfaces: scripts de respaldo/restauración con herramientas falsas en una carpeta temporal nueva. Primero obtener baseline; luego una prueba fallida por requisito, implementación mínima y verde, seguida del caso límite. Un bloqueo o un fallo preexistente no es RED del requisito. No instalar herramientas ni cambiar políticas para lograrlo.

| Comportamiento | Casos propuestos, NO ejecutados |
|---|---|
| Indicadores | Métricas completas cero; cada indicador nuevo con 1; indicador ausente. Verificar que la consulta enviada al simulador los solicite. El JSON falso no valida la semántica SQL real. |
| Nombre | Ambas fuentes: fecha/hora en el archivo y coincidencia con metadata. |
| Ruta | Interna y `..` rechazadas antes de herramientas; externa y hermano de prefijo similar aceptados; enlace al repositorio en fixture solo si se permite sin cambiar permisos. |
| Colisión | Directorio previo con centinela intacto y rechazo antes de herramientas; directorio nuevo aceptado. Controlar fecha/ID únicamente en fixture temporal. |
| Etapas | Éxito, salidas 7/9 y fallo al iniciar; fechas/códigos persistidos; contraseña centinela ausente del registro estructurado. |
| Objetivos | PASS operativo con proxy antiguo no cumple frescura; reciente sí; umbral de 900 s probado con mediciones controladas, sin esperar 15 minutos. |
| Diagnóstico | Comprobar cierre ROLLBACK estáticamente; no presentarlo como ejecución SQL. |

| Tarea | Prueba | Capa | Safety Net | RED | GREEN | Triangulación | Refactor |
|---|---|---|---|---|---|---|---|
| Correcciones propuestas | `pruebas/test_delivery.ps1`, intacto | Integración simulada | BLOQUEADO | PENDIENTE | PENDIENTE | Casos propuestos | No realizado |

## Aclaraciones externas a evidencias intactas

- Los `backup.log` vacíos no prueban por sí solos código cero. Los JSON permiten contrastar métricas, pero faltan en el paquete algunos comandos, consultas y códigos nativos originales. No se reconstruyeron registros.
- El manifiesto protege integridad del paquete, no autenticidad ni restaurabilidad. No hay hashes de dumps históricos en esta selección; no se inspeccionaron respaldos externos.
- Los nueve indicadores históricos no equivalen al validador actual: el histórico informa precios no positivos; el código actual admite cero y rechaza negativos/NULL, coherente con la consigna. No renombrar claves históricas para ocultar la diferencia.
- Las marcas dan 2,9865544 s y 8,2566120 s; los cronómetros, 2,9817064 s y 8,1943358 s. No hay causa exacta acreditada. El proxy de carga usa una referencia previa al dump. No se demuestra pérdida efectiva ni cumplimiento periódico.
- Las SPEC iniciales idénticas, los resúmenes duplicados y las métricas iguales conservan sus funciones históricas. No se borran.
- Los enlaces relativos de las copias iniciales perdieron contexto al copiarlas. Sin alterarlas, sus destinos vigentes son el [protocolo](../../protocolo_seguridad.md) y la [consigna](<../TPUnidad_6_Mantenimiento_FoodStore (1).pdf>). Copias: [historial](../evidencias/historial/spec_inicial_20261023.md) y [antecedente](antecedentes/SPEC_U6_previo_20261023.md).
- Explicar la adaptación `foodstore_dev` frente a `foodstore`. La aceptación docente de Codex proviene del usuario, sin comprobante en el paquete. Confirmar si la cátedra acepta omitir dumps: la consigna menciona limitación de tamaño del aula. No adjuntar automáticamente respaldos con datos.

## Antes de entregar

### Verificaciones de este cierre

El PDF se regeneró desde el contenido Markdown con tipografías PDF estándar, sin instalar dependencias. Windows.Data.Pdf reconoció una página y produjo la previsualización PNG temporal, revisada visualmente: tablas completas, márgenes y pie separados, sin texto cortado ni superpuesto. Cuerpo de 10 puntos; tablas de 9,5 puntos y encabezados de 9,2; referencias de 8,4. Se mantuvo un solo PDF final y un solo Markdown editable. Los temporales de generación y previsualización están fuera del paquete.

Limitación de la herramienta de revisión: el proceso auxiliar de renderizado terminó con código -1073741819 después de escribir el PNG, en dos intentos. La causa no fue determinada. La lectura de una página y el raster obtenido sí se observaron, pero no se informa salida cero del auxiliar. Revisar también el PDF en el visor habitual antes de entregarlo.

Se verificó sintaxis de los cuatro PS1 con el parser de Windows PowerShell 5.1: cero errores; no se ejecutaron esos scripts. Se contrastaron conteos y tiempos con los JSON; los intervalos exactos se recalcularon con DateTimeOffset (precisión de 100 ns). Los 51 archivos protegidos del inventario inicial (evidencias, copias históricas, scripts, pruebas y consigna) conservaron sus hashes. Solo quedaron cuatro enlaces rotos dentro de las dos copias históricas, intencionalmente intactas y con destinos vigentes aclarados arriba. El manifiesto se actualiza después de la documentación para cubrir todos los archivos finales excepto a sí mismo.

Abrir [README_TP8.md](../README_TP8.md), luego el [informe PDF](../informe_u6.pdf). Revisar legibilidad, conteos y metas; consultar [script_validation.md](../script_validation.md) para distinguir pruebas históricas, bloqueadas y pendientes. La revisión humana final sigue pendiente. No hace falta ejecutar scripts para leer la entrega.
