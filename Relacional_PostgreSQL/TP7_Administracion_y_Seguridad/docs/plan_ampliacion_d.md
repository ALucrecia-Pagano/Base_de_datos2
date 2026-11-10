# TP7 Parte D — Plan de cobertura adicional

**Estado: ejecutado el 2026-10-17 en una única pasada con ROLLBACK.** Evidencia:
[usuario_anon_cobertura_20261017_233704.md](evidencias/usuario_anon_cobertura_20261017_233704.md).
La evidencia original del 15/10/2026 se conserva intacta.

## Fixtures propuestos

Todos usan nombre `LabD-Cobertura`, apellido `Fixture-N`, celular NULL y correo
`lab_d_cobertura_N@example.invalid`. La hora de alta es 12:00:00 con offset -03.

| N | ID explícito | Rol | Alta | Eliminado |
|---|---|---|---|---|
| 1 | -770701 | ADMIN | 2026-01-10 | false |
| 2 | -770702 | ADMIN | 2026-01-20 | true |
| 3 | -770703 | VENDEDOR | 2026-02-10 | false |
| 4 | -770704 | VENDEDOR | 2026-02-20 | false |
| 5 | -770705 | USUARIO | 2026-03-10 | false |
| 6 | -770706 | USUARIO | 2026-03-20 | true |

Resultados esperados **solo de fixtures**, definidos antes de ejecutar (los obtenidos
coinciden; ver la [evidencia](evidencias/usuario_anon_cobertura_20261017_233704.md)):

| Rol | Mes de alta | Cantidad, incluyendo eliminados |
|---|---|---|
| ADMIN | 2026-01-01 | 2 |
| VENDEDOR | 2026-02-01 | 2 |
| USUARIO | 2026-03-01 | 2 |

Son seis filas, tres roles, tres meses y dos eliminados. ADMIN/enero y
USUARIO/marzo mezclan activos y eliminados. La distribución se comprueba con
excepciones, no solo con mensajes. Al planificar, los totales generales no se
presuponían: incluirían los usuarios originales y estos seis. En la ejecución del
2026-10-17 resultaron 8 filas en 5 grupos (los 2 usuarios originales, de octubre,
más los 6 fixtures).

## Contraseña bloqueada y requisitos reales

El [esquema documentado](../../TP5_Indices_Vistas/Parte_B_Vistas/usuarios.sql)
exige `contrasena VARCHAR(255) NOT NULL` y `trim(contrasena) <> ''`, sin comprobar
formato bcrypt. Se propone el marcador literal `!TP7_D_COBERTURA_SIN_LOGIN!`:
no es contraseña ni hash, cumple las restricciones documentadas y no representa
una credencial utilizable por la [función de autenticación](../sql/fn_autenticar.sql),
que compara el resultado de `crypt` con el valor almacenado. Su longitud/formato
no es una salida de los algoritmos de `crypt` admitidos por pgcrypto. Una sal inválida
puede causar error; no se promete que autenticar estos fixtures devuelva NULL.
No se llamará a autenticación ni a reset de contraseña con ellos.

Es una excepción de laboratorio, transaccional, al convenio de almacenar hashes;
evita publicar hashes o generar claves conocidas. No cambia el esquema, no lee
credenciales existentes y la copia no contiene `contrasena`. La revisión previa
debe confirmar que ninguna aplicación usa comparación literal de contraseñas.
Si hay validadores o mecanismos diferentes, detenerse y revisar antes de ejecutar.

## Prerrequisitos, efectos y seguridad

Autorizar separadamente inventario, respaldo y ensayo conforme al
[protocolo](../../protocolo_seguridad.md#alcance-particular-del-tp7-administración-y-seguridad).
Exigir respaldo custom nuevo fechado fuera del repositorio, registrar origen,
formato, hash y salida de generación/listado; listado legible no prueba restaurabilidad.
**No se genera respaldo en esta etapa.**

Antes de autorizar ejecución, revisar el esquema instalado completo: nueve columnas,
tipos y orden, constraints y sus funciones dependientes, identity, defaults, triggers,
reglas, políticas, privilegios, funciones de autenticación y event triggers. El script
aborta ante tabla no ordinaria, RLS, herencia, reglas, triggers de usuario habilitados,
event triggers habilitados, nombres ocupados o conflictos de IDs/correos. Estas
guardas no sustituyen ese inventario: restricciones nuevas deben revisarse y no
deshabilitarse automáticamente. Requiere sesión administrativa autorizada con
SELECT/INSERT de usuario, CREATE de esquema/TEMP y capacidad de revocar ACL propias.

Usar ventana sin actividad concurrente y sesión nueva sin transacción previa,
sin echo SQL ni variables de credenciales en la salida. Hay una sola transacción
REPEATABLE READ, zona `America/Argentina/Buenos_Aires` y cierre ROLLBACK.
El bloqueo SHARE ROW EXCLUSIVE sobre usuario impide escrituras concurrentes hasta
el cierre y puede esperar o afectar disponibilidad: cancelar ante contención, no
desconectar sesiones ajenas. Las filas originales se conservan. Todos los campos
de fixtures se suministran explícitamente, con OVERRIDING SYSTEM VALUE para identity;
no se invocan nextval/setval ni se crea identity en la copia. La copia pública y
la tabla temporal pierden ACL heredadas hacia otros roles dentro de la transacción;
no se otorgan permisos. El propietario y superusuarios conservan acceso implícito.
Ante error, ON_ERROR_STOP puede impedir alcanzar el cierre: descartar la transacción
en esa sesión o cerrar la conexión; nunca confirmar ni limpiar objetos automáticamente.

## Comparación estática y comprobaciones futuras

El [nuevo script autónomo](../sql/usuario_anon_cobertura.sql) conserva del
[original](../sql/usuario_anon.sql): población completa sin filtros, incluidos
eliminados; sintéticos derivados del ID; rol y eliminado; `date_trunc('month',
created_at)::date`; zona horaria; agrupación únicamente rol × mes; agregaciones,
FULL OUTER JOIN, EXCEPT ALL en ambos sentidos y comparación de totales con excepción.
Las diferencias son preparación de fixtures/guardas/ACL y nombres. CTAS omite
`id_anon` identity, ajeno a la consulta, para no consumir secuencias; tampoco copia
PK, NOT NULL ni UNIQUE del objeto original. Las comprobaciones explícitas verifican
los datos del ensayo. Se endurece `search_path` a `pg_catalog, pg_temp` en vez de
`public, pg_temp`, calificando los objetos públicos. Son diferencias de estructura
y preparación que no cambian población ni agregación. No se usa `\ir`:
el ROLLBACK propio del original cerraría la transacción y revertiría los fixtures.

Antes y después, en conexiones autorizadas, capturar solo conteos, ausencia de los
seis IDs/correos y de ambos objetos (incluidos tipos asociados); comparar conteos
por tabla. Inventariar todas las secuencias existentes de usuario y otras tablas,
guardar `last_value` e `is_called` por secuencia y compararlos tras cerrar el ensayo.
Una ventana sin actividad es indispensable: diferencias concurrentes no se pueden
atribuir al script; ROLLBACK por sí solo no acredita conservación de secuencias.
La tabla temporal debe estar ausente en la sesión y la copia pública ausente en
una conexión nueva. Revisar también que ACL/objetos originales no cambiaron.

El ensayo compara exactamente las filas esperadas con las insertadas, comprueba
distribución y presencia de eliminados en la copia, y hace fallar diferencias
bidireccionales o de totales. Mostrar solo agregados y métricas; no filas originales,
contraseñas ni hashes. Resultados obtenidos: diferencias 0/0 y totales 8/8 (informe D, §6).

Con autorización posterior, guardar salida nueva fechada y código de salida en
`docs/evidencias/salida_psql_usuario_anon_cobertura_AAAAMMDD_HHMMSS.txt`, conservando
también comprobaciones previas/posteriores sin secretos. No sobrescribir archivos.
Revisar la salida antes de compartirla. Actualizar después informe, guía y bitácora
con autorización nueva, separando cobertura nueva de evidencia histórica íntegra.
Esta revisión estática no acredita equivalencia ejecutada ni estado actual de PostgreSQL.
