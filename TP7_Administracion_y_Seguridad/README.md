# TP7 — Administración y seguridad: guía de lectura

La matriz orienta la lectura de la [consigna](Trabajo%20Practico%20Unidad%205.pdf).
La documentación de referencia actual describe el trabajo y sus límites; las evidencias
registran ejecuciones fechadas, principalmente del 2026-10-15 (el ensayo adicional de D es del 2026-10-17). Estos archivos no
constituyen una verificación actual de PostgreSQL ni autorizan nuevas ejecuciones.

| Punto | Qué pide | Entregable | Evidencia o validación documentada |
|---|---|---|---|
| A.1 | Especificar roles con Kiro | [Requisitos](docs/kiro_roles_spec/requirements.md) y [diseño](docs/kiro_roles_spec/design.md) | RF-01–RF-07 y decisiones del diseño |
| A.2 | Implementar roles y privilegios | [roles.sql](sql/roles.sql) | [Aplicación y validación del 15/10](docs/evidencias/aplicacion_correccion_seguridad_20261015_1121.md) |
| A.3 | Verificar permisos efectivos | [Verificación de permisos](docs/kiro_roles_spec/verificacion_permisos.md) | [Roles verificados el 15/10](docs/evidencias/roles_vigentes_20261015.md) |
| A.4 | Revisar críticamente permisos amplios | [Bitácora consolidada](../BITACORA.md) | Propuestas solicitadas y rechazadas de A.4 |
| B.1 | Configurar auditoría | [Informe B](docs/informe_auditoria.md) | Parámetros y elección de `log_statement=all` |
| B.2 | Registrar operaciones y conexión fallida | [Secuencia B](sql/auditoria_test.sql) | [Log de prueba, copia legible](docs/log_auditoria_prueba.utf8.txt) |
| B.3 | Analizar información y límites del log | [Informe B](docs/informe_auditoria.md) | Análisis del fragmento registrado |
| B.4 | Evaluar sensibilidad y acceso | [Informe B](docs/informe_auditoria.md) | Exposición de parámetros y ACL documentadas |
| C.1 | Ejecutar la secuencia del simulacro | [Guion C](sql/simulacro_incidente.sql) | [Ejecución del 15/10](docs/evidencias/ejecucion_20261015_0215.md) |
| C.2 | Comprobar rechazo del escalamiento | [Informe C](docs/informe_incidente.md) | Manejador 42501 y marcas concordantes del guion |
| C.3 | Anonimizar el log | [Log anonimizado original](docs/log_simulacro_anonimizado.txt) | [Copia legible](docs/log_simulacro_anonimizado.utf8.txt) y [revisión de representación](docs/revision_documental_20261015.md) |
| C.4 | Reconstruir el incidente con OpenCode | [Respuesta íntegra](docs/respuesta_ia_incidente.md) | [Prompt propio recuperado](docs/registro_prompts_opencode_codex_20261015.md#p19473); límites de procedencia en el informe C |
| C.5 | Contrastar críticamente la reconstrucción | [Informe C](docs/informe_incidente.md) | Aciertos, afirmaciones insuficientemente respaldadas y límites |
| C.6 | Decidir medidas mediante revisión humana | [Informe C](docs/informe_incidente.md) | Decisión humana y distinción entre laboratorio y escenario real |
| D.1 | Transformar datos para el ensayo | [usuario_anon.sql](sql/usuario_anon.sql) y [usuario_anon_cobertura.sql](sql/usuario_anon_cobertura.sql) | [Informe D](docs/verificacion_equivalencia.md): transformación y límites de seudonimización |
| D.2 | Formular consultas equivalentes | [usuario_anon.sql](sql/usuario_anon.sql) y [usuario_anon_cobertura.sql](sql/usuario_anon_cobertura.sql) | Agregaciones por rol y mes de alta, con igual población |
| D.3 | Comparar resultados | [Informe D](docs/verificacion_equivalencia.md) §4 y §6 | [Salida del 15/10](docs/evidencias/salida_psql_usuario_anon_20261015_091628.txt) (2 usuarios) y [ensayo adicional del 17/10](docs/evidencias/usuario_anon_cobertura_20261017_233704.md) (8 usuarios, 3 roles, 4 meses en total (3 aportados por los fixtures), 2 eliminados): `EXCEPT ALL` bidireccional |
| D.4 | Identificar datos que no deben enviarse a IA | [Informe D](docs/verificacion_equivalencia.md) | Criterios para datos de usuario y cliente |
| E.1 | Consolidar interacciones en tres columnas | [Bitácora raíz](../BITACORA.md) | Prompts, respuestas y validación humana; [fuentes literales propias](docs/registro_prompts_opencode_codex_20261015.md) |
| E.2 | Documentar un error significativo y su corrección | [Bitácora raíz](../BITACORA.md) | Error `FULL JOIN` y corrección a `LEFT JOIN` |
| E.3 | Conservar el avance en Git | [Bitácora raíz](../BITACORA.md) | Historial por etapas y commits identificados; D/E comparten commit |

La muestra original de D (dos usuarios, dos roles y un mes de alta, sin eliminados) se
complementa con un ensayo adicional de cobertura: ocho usuarios, tres roles, cuatro meses en total (tres aportados por los fixtures)
y dos eliminados contados dentro de su grupo. Diseño en el [plan de ampliación](docs/plan_ampliacion_d.md).

La [bitácora de trabajo](BITACORA.md), el [plan de preparación](docs/plan_preparacion_local.md),
la [ejecución local](docs/ejecucion_local.md) y el [procedimiento C](docs/procedimiento_simulacro.md)
se conservan como antecedentes de sus respectivas etapas. Sus pendientes históricos
se interpretan junto con los informes y evidencias posteriores, sin reescribirlos.
Las reglas de autorización permanecen en el [protocolo](../protocolo_seguridad.md).
