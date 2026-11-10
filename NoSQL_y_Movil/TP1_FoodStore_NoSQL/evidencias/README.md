# Registro de evidencias

Las atribuciones de ejecución a Amanda y Mateo y las referencias a sus máquinas corresponden a lo informado por los integrantes; Git y los JSON no demuestran por sí solos autoría ni máquina de ejecución. No deben presentarse como una única ejecución; ambos aportes se integran en la entrega grupal.

Las consultas y la comparación de las consignas 4–5 fueron aportadas, con ejecución informada por Mateo. Su captura MongoDB no mostraba completas c) ni d); la reejecución de Amanda del 2026-11-01, con los mismos scripts, completa esa evidencia con resultados coincidentes. Los resultados de Mateo se conservan.

Aplicar las [reglas del proyecto](../../AGENTS.md). Esta carpeta conserva
evidencias de los trabajos de los integrantes, según lo informado por ellos.

## Amanda — extracción y migración del 2026-10-28 (fuente oficial)

- Extracción: `extraccion_20261028_170446.json`, fuente oficial de la migración
  y única exportación acordada por el equipo. SHA-256
  `3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`,
  configurado en `mongodb/migracion_pedidos.js`.
- Evidencias: [inserción](migracion_insercion.png),
  [verificación](migracion_verificacion_amanda.png) y
  [documento del pedido 1](pedido_1_documento.png).
- Responsable: Amanda.
- Registro: [resultado_migracion.md](../docs/resultado_migracion.md).
- El renombrado posterior de la captura de verificación no representa una nueva
  ejecución ni una segunda migración de Amanda.

## Mateo — anexo: prueba local independiente del 2026-10-29

- Extracción: `extraccion_20261029_102959.json`, conservada como anexo de su
  prueba local; no es fuente operativa del script. Su arreglo `extraccion` es
  idéntico al de la fuente oficial. El hash `0e17c782…` corresponde a su copia
  local con CRLF; la copia versionada (LF) da `cece1385…`. Detalle en
  [comparacion_resultados.md](../docs/comparacion_resultados.md).
- Evidencias: [MongoDB](consultas_mongodb_consignas_4_5.png),
  [PostgreSQL](consultas_postgresql_consignas_4_5.png) y
  [verificación de Mateo](migracion_verificacion_mateo_20261029.png).
- Responsable: Mateo.
- Registro: [comparacion_resultados.md](../docs/comparacion_resultados.md).
- Este trabajo no reemplaza ni modifica la migración documentada de Amanda.
- La captura MongoDB no muestra completas c) ni d); esas salidas se completan
  con la reejecución de Amanda del 2026-11-01.

## Amanda — reejecución de consultas 4–5 del 2026-11-01

- Consultas de solo lectura ejecutadas manualmente por Amanda en su computadora,
  con los scripts sin modificar: `psql -X -U postgres -d foodstore_dev -f
  TP1_FoodStore_NoSQL/postgresql/consultas_postgresql.sql` y
  `mongodb/consultas_mongodb.js` pegado completo en la shell de Compass sobre
  `foodstore_unidad7`.
- Evidencias: [PostgreSQL, b) y c)](consultas_postgresql_amanda.png);
  [MongoDB 1, base, conteo, script y parámetros](consultas_mongodb_amanda_1.png);
  [MongoDB 2, a), b) e inicio de c)](consultas_mongodb_amanda_2.png);
  [MongoDB 3, c) y d) completas](consultas_mongodb_amanda_3.png).
- Responsable: Amanda. Las capturas no acreditan versiones de MongoDB ni de Compass.
- Registro: [comparacion_resultados.md](../docs/comparacion_resultados.md).

Las dos extracciones y sus evidencias se conservan separadas aunque describan
el mismo subconjunto de pedidos; la oficial es la de Amanda. La revisión del asistente fue documental y
visual, sin ejecutar motores ni migraciones.

## Lucas — consulta a IA y contraste, consignas 6–7

- Capturas de la conversación con Gemini, aportadas por Lucas, en orden de lectura:
  - [gemini_lucas_1.jpeg](gemini_lucas_1.jpeg) y [gemini_lucas_2.jpeg](gemini_lucas_2.jpeg):
    pregunta enviada.
  - [gemini_lucas_3.jpeg](gemini_lucas_3.jpeg): secciones 1 (Almacenamiento) y 2
    (Consulta de un pedido completo) de la respuesta.
  - [gemini_lucas_4.jpeg](gemini_lucas_4.jpeg): sección 3 (Integridad y coherencia),
    con las dos afirmaciones contrastadas.
  - [gemini_lucas_5.jpeg](gemini_lucas_5.jpeg): afirmación sobre MongoDB y
    recomendación completa.
- Las capturas muestran el modelo «Gemini Flash-Lite» y no muestran la fecha del
  chat; la fecha 29/10/2026 es la informada por Lucas. No muestran correos ni
  datos personales.
- Salidas de laboratorio: [prueba_validacion_expr_salida.txt](prueba_validacion_expr_salida.txt)
  y [contraste_integridad_postgresql_salida.txt](contraste_integridad_postgresql_salida.txt).
- Responsable: Lucas.
- Registro: [contraste_ia.md](../docs/contraste_ia.md).

Para cada ejecución autorizada registrar:

- Fecha real, hora y zona horaria.
- Objetivo, consigna y responsable del registro.
- Motor, versión conocida, herramienta y destino (base, colección o tablas), sin secretos.
- Estado o subconjunto de datos relevante y parámetros usados.
- Comando o consulta exactos y referencia al archivo correspondiente.
- Resultado observado, cantidades e IDs pertinentes, errores y limitaciones.
- Nombre o enlace de la evidencia y pasos suficientes para reproducirla.

Distinguir propuesta, implementación, ejecución y verificación; identificar como tales los antecedentes aportados por el equipo. No inventar resultados, fechas ni versiones.

Conservar las evidencias originales sin alterarlas. Si contienen datos sensibles, mantenerlas fuera de lo publicable y producir una copia anonimizada identificada como tal. Revisar capturas, texto y JSON antes de publicarlos; no incluir contraseñas, cadenas de conexión con secretos, respaldos completos ni datos personales reales. La política de exclusión no oculta texto, JSON ni capturas por defecto.

Convención sugerida para futuras evidencias: `AAAA-MM-DD_consigna_descripcion.ext`, usando la fecha efectiva de captura. Una captura aislada debe acompañarse del contexto necesario.
