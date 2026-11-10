# Migración de pedidos — ejecución manual documentada

Las atribuciones de ejecución a Amanda y Mateo y las referencias a sus máquinas corresponden a lo informado por los integrantes; Git y los JSON no demuestran por sí solos autoría ni máquina de ejecución. No deben presentarse como una única ejecución; ambos aportes se integran en la entrega grupal.

Las consultas y la comparación de las consignas 4–5 fueron aportadas, con ejecución informada por Mateo. Su captura MongoDB no mostraba completas c) ni d); la reejecución de Amanda del 2026-11-01, con los mismos scripts, completa esa evidencia con resultados coincidentes. Los resultados de Mateo se conservan.

Aplicar [AGENTS.md](../../AGENTS.md). Amanda informó la ejecución manual de su
migración en Compass el 2026-10-28; el asistente inspeccionó sus capturas y
documentó el resultado, sin nuevas conexiones ni ejecuciones. La fuente oficial
de la migración es la extracción de Amanda. El repositorio también conserva, como
anexo, la prueba local independiente de Mateo del 2026-10-29, con su propia
extracción y evidencias, documentada en
[comparacion_resultados.md](../docs/comparacion_resultados.md). No deben presentarse como una única ejecución; ambos aportes se integran en la entrega grupal. Estas instrucciones no autorizan repetir ninguna carga.

## Incidencia de Buffer y resultado registrado

En el modo `validar` de Compass, Amanda informó `ReferenceError: Buffer is not defined`, en fase `validacion_local`. Fue necesario importar explícitamente el módulo dentro del `try`, junto a los demás `require`:

```javascript
const { Buffer } = require("buffer");
```

Se conservaron la comprobación UTF-8, el SHA-256 y los demás controles. Este ajuste ya está en el script; no se modificó en esta etapa documental. La ejecución informada se realizó en Compass; la alternativa externa se mantiene como referencia para otros entornos.

Las capturas de [inserción](../evidencias/migracion_insercion.png) y [verificación](../evidencias/migracion_verificacion_amanda.png), inspeccionadas el 2026-10-28, muestran inserción confirmada de IDs `Long` 1–5 en `foodstore_unidad7.pedidos` y verificación satisfactoria de cinco pedidos, siete líneas, tipos BSON correctos y correspondencia completa con el lote fuente. No acreditan versiones ni la configuración efectiva de `retryWrites`. No volver a usar el modo `insertar` para repetir una verificación: el script se detendrá si esos IDs ya existen; para una comprobación posterior autorizada corresponde el modo de lectura `verificar`.

## Fuente oficial de la migración

La fuente oficial de la consigna 2, acordada por el equipo como única
exportación, es `extraccion_20261028_170446.json`, utilizada en la ejecución de
Amanda. Se validó el archivo original sin modificarlo:

- Fuente: [extraccion_20261028_170446.json](../evidencias/extraccion_20261028_170446.json).
- SHA-256: `3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`.
- JSON UTF-8 válido, sin claves duplicadas ni caracteres de reemplazo.
- Contexto declarado: `foodstore_dev.public`, `repeatable read`, `solo_lectura: on`; servidor PostgreSQL 17.11 según el archivo, no mediante una nueva conexión.
- Todos los controles generales verdaderos, incluido `extraer`; cinco pedidos (IDs 1–5) y siete líneas. Controles detallados satisfactorios y sin submilisegundos.
- Fórmulas comprobadas localmente con aritmética decimal exacta; sin observaciones ni nombres/contactos personales del cliente.

El script actual está configurado con esta fuente y su hash, en `FUENTE` y `SHA`.
Una revisión intermedia del historial los había cambiado para usar
`extraccion_20261029_102959.json`, la extracción de la prueba local de Mateo;
el hash configurado entonces correspondía a su copia local con finales CRLF y no
coincidía con la copia versionada, por lo que el script fallaba en un clon
nuevo. Esa configuración se revirtió a la fuente oficial. El script compartido lee `extraccion` del
archivo configurado y no usa las referencias esperadas como datos de carga.
Comprueba el SHA-256 antes de convertir, valida el lote completo y exige IDs
Long, cantidades Int32, importes Decimal128 desde texto y fechas Date sin
pérdida. Una extracción nueva exige revisión y actualización explícita de la
referencia y hash.

## Modos y precauciones concretas

- `validar` (predeterminado): lectura local del JSON, comprobación del hash y conversión BSON; no consulta ni escribe MongoDB.
- `insertar`: comprueba la base activa y todos los IDs del lote antes de escribir. Si cualquiera existe, se detiene sin insertar. Si no existe la colección, la primera inserción puede crearla implícitamente. Nunca borra, actualiza, reemplaza, hace upsert ni recrea destinos.
- `verificar`: solo lee el destino y compara con el lote; no inserta. Puede usarse para inspeccionar una carga parcial después de un error, pero no la recupera.

Configurar la conexión revisada con `retryWrites=false` antes de insertar: además de no tener bucles de reintento, se deben desactivar los reintentos automáticos del cliente. El script no cambia la conexión ni registra su URI o credenciales. Evitar escritores concurrentes durante el laboratorio. La comprobación previa de IDs no elimina una carrera con otro escritor.

`insertMany` con `ordered: true` **no es una transacción del lote**. Ante un error pueden haberse insertado documentos anteriores. El script informa fase, fecha, código y mensaje, y termina sin reintentar, borrar ni completar automáticamente. Conservar la salida de la shell como evidencia nueva, sin sobrescribir el JSON original; revisar los IDs que realmente quedaron antes de decidir cualquier recuperación. Un error de verificación posterior también puede ocurrir después de una inserción confirmada.

## Rutas actuales y trazabilidad

`FOODSTORE_RAIZ` sigue siendo la raíz del repositorio, sin agregar
`TP1_FoodStore_NoSQL`. La configuración actual de `FUENTE` apunta a
`TP1_FoodStore_NoSQL/evidencias/extraccion_20261028_170446.json` y su `SHA` es
`3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243`, el de la
fuente oficial, protegida con `-text` en [.gitattributes](../../../.gitattributes).
`extraccion_20261029_102959.json` se conserva solo como anexo de la prueba
local independiente de Mateo; no es fuente operativa del script. Las rutas
visibles en las capturas corresponden a sus respectivas ejecuciones y no se
modificaron.

## Ejecución manual desde la shell de Compass

Cuando el script esté revisado y la ejecución autorizada:

1. Confirmar en Compass la conexión MongoDB prevista, su versión y `retryWrites=false` (agregar `?retryWrites=false` a una URI sin opciones, o `&retryWrites=false` si ya tiene opciones; no publicar la URI con secretos). Abrir la shell integrada `>_`.
2. Definir la raíz absoluta del repositorio, usando `/` en Windows. Cada integrante debe sustituir `C:/RUTA/AL/REPO` por la ruta absoluta real de su repositorio, tanto aquí como en el ejemplo de `load()`:

   ```javascript
   globalThis.FOODSTORE_RAIZ = "C:/RUTA/AL/REPO";
   globalThis.FOODSTORE_MODO = "validar";
   ```

3. Copiar **el contenido completo** de [migracion_pedidos.js](migracion_pedidos.js) desde el editor y pegarlo como un solo bloque en la shell. El modo predeterminado solo valida el archivo. Esta vía evita asumir que `load()` esté disponible en la versión integrada de Compass. El script necesita acceso local mediante `require("fs")`, `require("path")`, `require("crypto")` y la importación explícita de `Buffer` desde `require("buffer")`.
4. Si otra shell restringe esos módulos o el acceso a archivos, detenerse: usar la alternativa externa descrita abajo, sin transcribir los documentos ni quitar el control de hash. La ejecución de Amanda en Compass está documentada; según lo informado por Amanda, usó MongoDB Server 9.0.4 y Compass 1.53.2 con mongosh integrado 2.9.2. La compatibilidad de otros entornos no se infiere de las capturas.
5. Si la validación local es satisfactoria, seleccionar explícitamente el destino y activar una sola inserción:

   ```javascript
   use foodstore_unidad7
   globalThis.FOODSTORE_MODO = "insertar";
   ```

   Pegar otra vez el script completo. Repite la validación local, comprueba IDs, inserta ordenadamente y verifica. El modo se restablece a `validar` al empezar para no reutilizar accidentalmente una orden de inserción.

6. Para repetir únicamente la verificación, establecer `globalThis.FOODSTORE_MODO = "verificar"` y volver a pegar el script completo, manteniendo seleccionada `foodstore_unidad7`.

## Alternativa: mongosh externo, solo si es necesario

No se supone que esté instalado. Si Compass no permite leer archivos o usar módulos locales, se necesita mongosh externo para conservar la lectura reproducible y el SHA-256 de la fuente. No se instala ni ejecuta aquí.

Abrir manualmente mongosh con la conexión local correcta y reintentos desactivados. Ejemplo sin autenticación, **solo si corresponde al entorno real**:

```bash
mongosh "mongodb://localhost:27017/foodstore_unidad7?retryWrites=false"
```

Si el entorno requiere autenticación, usar la conexión y mecanismo del equipo; no incluir contraseñas en archivos o comandos publicables. En la shell externa definir `FOODSTORE_RAIZ` y el modo como arriba. Ejecutar el archivo mediante una ruta absoluta:

```javascript
load("C:/RUTA/AL/REPO/TP1_FoodStore_NoSQL/mongodb/migracion_pedidos.js")
```

Primero `validar`; después, solo con autorización, seleccionar el destino y establecer `insertar` antes de otro `load()`. `verificar` permite una ejecución posterior de solo lectura.

## Verificaciones posteriores y alcance

La agregación selecciona únicamente los IDs del lote y exige cinco documentos y siete líneas. `$type` se evalúa en el servidor para confirmar `long` en IDs, `int` en cantidades, `date` en fechas y `decimal` en importes; así no se confía en conversiones de presentación de la shell. Compara después todos los campos, valores y arreglos con el lote generado de la fuente mediante Extended JSON canónico, conservando información BSON. Se ignora solo el orden de las claves de los objetos; el orden de las líneas debe coincidir.

Estas comprobaciones cubren los cinco pedidos migrados, no exigen que la colección carezca de otros pedidos. Las reglas aritméticas se verifican antes de insertar con centavos exactos y, después, por igualdad completa con el lote validado. No se instala un validador permanente; futuras escrituras ajenas al procedimiento podrían romper las reglas.

## Fuentes y alcance de la revisión

Documentación oficial consultada el 2026-10-28:

- [Compass: shell integrada](https://www.mongodb.com/docs/compass/embedded-shell/).
- [mongosh: scripts](https://www.mongodb.com/docs/mongodb-shell/write-scripts/) y [módulos externos](https://www.mongodb.com/docs/mongodb-shell/write-scripts/require-external-modules/).
- [Tipos BSON y constructores en mongosh](https://www.mongodb.com/docs/mongodb-shell/reference/data-types/).
- [insertMany y comportamiento ordenado](https://www.mongodb.com/docs/manual/reference/method/db.collection.insertMany/).
- [Reintentos de escritura](https://www.mongodb.com/docs/manual/core/retryable-writes/).
- [Agregación $type](https://www.mongodb.com/docs/manual/reference/operator/aggregation/type/) y [EJSON.serialize](https://www.mongodb.com/docs/mongodb-shell/reference/ejson/serialize/).

En la preparación inicial se comprobaron la evidencia y la sintaxis local del JavaScript, y se contrastaron las APIs con documentación. Posteriormente Amanda ejecutó manualmente la migración en Compass y aportó las capturas inspeccionadas. **El asistente no ejecutó la migración ni repitió las verificaciones en un motor; su revisión fue documental y visual.** La salida satisfactoria del script no acredita consultas de consignas 4–5, análisis de consignas 6–7 ni aprobación grupal del diseño.
