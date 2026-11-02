# FoodStore — Unidad 7: NoSQL

Las atribuciones de ejecución a Amanda y Mateo y las referencias a sus máquinas corresponden a lo informado por los integrantes; Git y los JSON no demuestran por sí solos autoría ni máquina de ejecución. No deben presentarse como una única ejecución; ambos aportes se integran en la entrega grupal.

Las consultas y la comparación de las consignas 4–5 fueron aportadas, con ejecución informada por Mateo. Su captura MongoDB no mostraba completas c) ni d); la reejecución de Amanda del 2026-11-01, con los mismos scripts, completa esa evidencia con resultados coincidentes. Los resultados de Mateo se conservan.

Trabajo práctico de Bases de Datos II sobre modelado documental,
migración de un subconjunto de FoodStore a MongoDB y comparación
de consultas con PostgreSQL.

## Datos académicos

- Institución: Universidad Tecnológica Nacional — Facultad Regional Mendoza.
- Carrera: Tecnicatura Universitaria en Programación.
- Materia: Bases de Datos II.
- Comisión: 4.
- Profesor: Neira Sergio.

## Integrantes

- Liendo Mateo.
- Ávila Lucas.
- Pagano Amanda.

## Continuidad del proyecto

Este trabajo continúa el proyecto FoodStore desarrollado en los
trabajos prácticos anteriores de la materia.

Repositorio relacional:
https://github.com/ALucrecia-Pagano/Base_de_datos2

Repositorio de esta unidad:
https://github.com/ALucrecia-Pagano/Bases-de-datos-II-NoSQL

Se utiliza PostgreSQL como origen y MongoDB para representar un
subconjunto de pedidos mediante documentos.

## Objetivo y alcance

- Modelar una colección de pedidos con datos del cliente y líneas embebidas.
- Migrar al menos cinco pedidos conservando los identificadores de origen,
  fechas, estados, cantidades y precios históricos.
- Ejecutar consultas en MongoDB.
- Comparar consultas equivalentes en PostgreSQL y MongoDB.
- Contrastar dos afirmaciones de una herramienta de IA.
- Fundamentar la elección tecnológica.

No se requiere migrar toda la base de datos.

## Distribución del trabajo

| Integrante | Responsabilidad | Consignas |
|---|---|---|
| Amanda Pagano | Modelo documental, migración y reglas de integridad. | 1, 2 y 3 |
| Mateo Liendo | Consultas en ambos motores y comparación de resultados. | 4 y 5 |
| Lucas Ávila | Consulta a IA, contraste de afirmaciones y borrador de conclusión. | 6 y 7 |

La conclusión y la entrega final serán revisadas por el equipo completo.

## Entorno comprobado de Amanda

- Windows 11.
- Cliente psql: PostgreSQL 17.11, utilizado desde Git Bash.
- MongoDB Server instalado y con el servicio en ejecución.
- MongoDB Compass conectado al servidor local.
- Comprobación de conexión: ping con resultado ok: 1.

El archivo de extracción registra PostgreSQL Server 17.11.
Versiones informadas por Amanda: MongoDB Server 9.0.4 y MongoDB Compass 1.53.2,
con mongosh integrado 2.9.2 (registro informado, sin captura de versiones).

## Datos de origen comprobados

Base PostgreSQL: foodstore_dev.

- Pedidos: 5.
- Líneas de detalle: 7.
- Estado de los cinco pedidos: ENTREGADO.

Los precios históricos se tomarán de detalle_pedido.precio_unitario,
no del precio de lista actual del producto.

## Criterios de trabajo

- PostgreSQL se utilizará como origen de lectura y comparación.
- No se modificarán los datos de origen para realizar la migración.
- Las escrituras del modelo documental se realizarán en MongoDB.
- No se publicarán contraseñas, respaldos completos ni datos personales reales.
- Las propuestas de IA se verificarán con documentación oficial
  o resultados de ejecución.
- Amanda realizó la preparación inicial mientras trabajaba sola y autorizó
  publicaciones directas en `main` durante esa etapa. Al incorporarse el equipo,
  el flujo previsto es trabajar en ramas y revisar mediante pull request antes
  de integrar a `main`. Ese antecedente no autoriza publicaciones directas para
  cualquier cambio documental futuro ni acredita protección de `main`.

## Entrega prevista

- Un PDF de hasta cinco páginas, sin contar el código adjunto.
- Archivo consultas_mongodb.js, o nombre equivalente.
- Archivo consultas_postgresql.sql, o nombre equivalente.

El PDF incluirá el modelo, evidencias, comparación de resultados,
contraste de afirmaciones de IA y conclusión de hasta 200 palabras.

## Estado del trabajo

- [x] Instalación y conexión local de MongoDB comprobadas.
- [x] Cantidad de pedidos y detalles de origen verificada.
- [x] Estructura de las tablas de origen revisada.
- [x] Modelo documental redactado y aprobado por el equipo con el informe final.
- [x] Migración ejecutada manualmente por Amanda y verificada según capturas.
- [x] Consultas y comparación aportadas, con ejecución informada por Mateo.
- [x] Consultas ejecutadas y comparadas en ambos motores, con evidencias completas
  de a)–d) por la reejecución de Amanda del 2026-11-01.
- [x] Contraste de afirmaciones de IA aportado por Lucas.
- [x] Versiones de MongoDB Server (9.0.4) y Compass (1.53.2, mongosh integrado 2.9.2)
  de Amanda registradas, según lo informado.
- [x] Informe final integrado en [informe/](informe/README.md), aprobado por el equipo
  (OK de Mateo y Lucas del 2026-11-01) y listo para entregar.
- [ ] Confirmación docente del cliente con ID más alias.
- [ ] Corrección de la cátedra.

La conversación con Gemini de la consigna 6 está respaldada por cinco capturas
aportadas por Lucas (`evidencias/gemini_lucas_1.jpeg` a `gemini_lucas_5.jpeg`),
enlazadas desde [contraste_ia.md](docs/contraste_ia.md).

El [modelo documental](docs/modelo_documental.md) está redactado y fue aprobado
por el equipo con el informe final. La migración documentada corresponde a cinco pedidos
y siete líneas en `foodstore_unidad7.pedidos`, con IDs `Long` 1–5, tipos BSON
correctos y correspondencia con todos los campos del lote fuente, según las
salidas de Compass inspeccionadas durante la revisión documental del asistente.
Esta revisión no incluyó nuevas conexiones ni ejecuciones en los motores.

El [resultado de la migración](docs/resultado_migracion.md) describe el
procedimiento, las evidencias y los límites de la verificación. Capturas:
[inserción](evidencias/migracion_insercion.png) y
[verificación](evidencias/migracion_verificacion_amanda.png).
El [resultado de las consultas y comparación](docs/comparacion_resultados.md)
documenta la ejecución de las consignas 4 y 5 informada por Mateo y la
reejecución de Amanda del 2026-11-01, que completa las evidencias de MongoDB.
El [contraste de IA](docs/contraste_ia.md) de las consignas 6 y 7 fue aportado
por Lucas. El informe final fue aprobado por el equipo el 2026-11-01 y está listo
para entregar.

### Trazabilidad de ejecuciones independientes

Según lo informado por los integrantes, Amanda realizó su extracción y migración el 2026-10-28 con
`extraccion_20261028_170446.json`, el hash histórico registrado para ese archivo
y sus propias evidencias; esa es la fuente oficial de la migración. Mateo
realizó una prueba local independiente el 2026-10-29 con
`extraccion_20261029_102959.json`, conservada como anexo junto con sus
evidencias de consultas y verificación. Aunque ambas extracciones contienen el mismo
subconjunto documentado, no deben presentarse como una única ejecución; ambos aportes
se integran en la entrega grupal. El renombrado de
`migracion_verificacion_amanda.png` no representa una nueva migración de Amanda.

El repositorio conserva un único archivo compartido
`mongodb/migracion_pedidos.js`. Su configuración actual de `FUENTE` y `SHA`
apunta a la fuente oficial `extraccion_20261028_170446.json`. Una revisión
intermedia del historial había apuntado a la extracción del anexo de Mateo con
el hash de su copia local CRLF, que no coincide con la copia versionada; esa
configuración se revirtió.

## Rutas de ejecución actuales

Los ejemplos parten de la raíz del repositorio y requieren autorización específica antes de conectar motores. No repetir la migración ya realizada. `FOODSTORE_RAIZ` conserva la raíz del repositorio, sin agregar la carpeta del TP. Consultar la [guía MongoDB](mongodb/README.md) para modos, destino y precauciones.

- En una sesión nueva de psql conectada al origen autorizado `foodstore_dev`, cargar la extracción completa con `\i TP1_FoodStore_NoSQL/postgresql/extraccion_pedidos.sql`.
- Los archivos de consultas cuya ejecución informó Mateo son `TP1_FoodStore_NoSQL/postgresql/consultas_postgresql.sql` y `TP1_FoodStore_NoSQL/mongodb/consultas_mongodb.js`; sus resultados se documentan en `TP1_FoodStore_NoSQL/docs/comparacion_resultados.md`.
- En una shell compatible, la ruta de carga del script es `load("C:/RUTA/AL/REPO/TP1_FoodStore_NoSQL/mongodb/migracion_pedidos.js")`, con raíz y modo definidos según la guía.

Las ejecuciones anteriores usaron la estructura previa al traslado. El JSON, las capturas y la consigna PDF se conservan sin cambios; las rutas que muestran son históricas.
