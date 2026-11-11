# TP7 Parte D: ensayo adicional 20261017_233704

Estado: ensayo ejecutado con comparacion y controles posteriores correctos.

## Autorizacion y alcance

Una unica pasada del archivo revisado, sin modificarlo; sin ejecutar el original D. No COMMIT, restauracion, cambios persistentes de configuracion, autenticacion ni reset de fixtures. Inicio 2026-10-17T23:37:49.242213-03:00; fin 2026-10-17T23:37:49.670480-03:00. Identidad: foodstore_dev, postgres, PostgreSQL 17.11, instancia local (::1:5432).

## Respaldo previo

Ruta: `C:/Users/hp/Respaldos_BD2/respaldo_foodstore_dev_20261017_233704_antes_tp7_d_cobertura.dump`. Formato custom; 46877 bytes; SHA-256 `0094b46d8e36c95a949dd2cf7506edb33b7b230e37e569c821c3b182102849af`. pg_dump exit 0; pg_restore --list exit 0, 155 lineas, cabecera de base confirmada. No hubo stderr. No se restauro: un listado legible no acredita restaurabilidad.

## Controles previos

Conexion configurada solo lectura; BEGIN READ ONLY, ROLLBACK y exit 0. Actividad concurrente incompatible 0 y transacciones preparadas 0. Conflictos de IDs/correos 0; tabla publica y tipo ausentes. Nueve columnas, seis restricciones validadas, enum ADMIN/VENDEDOR/USUARIO; sin RLS, herencia, reglas, triggers de usuario habilitados ni event triggers habilitados. Captura integra de conteos, secuencias y ACL de relaciones, columnas, funciones publicas, esquema y defaults en la salida enlazada.

## Esperado frente a obtenido

Esperado exclusivo de fixtures: seis usuarios, dos eliminados; ADMIN/enero 2026=2 (uno eliminado), VENDEDOR/febrero=2 (ninguno eliminado), USUARIO/marzo=2 (uno eliminado). Los totales generales no se presuponian. Las comprobaciones exactas de filas, distribucion e inclusion de eliminados son excepciones del guion; su bloque DO finalizo sin error.

Salida real integra y controles: [salida psql](salida_psql_usuario_anon_cobertura_20261017_233704.txt).

```text
BEGIN
SET
SET
DO
LOCK TABLE
DO
CREATE TABLE
DO
INSERT 0 6
INSERT 0 6
CREATE TABLE AS
DO
INSERT 0 8
DO
   rol    |  mes_alta  | cantidad 
----------+------------+----------
 ADMIN    | 2026-01-01 |        2
 VENDEDOR | 2026-02-01 |        2
 VENDEDOR | 2026-10-01 |        1
 USUARIO  | 2026-03-01 |        2
 USUARIO  | 2026-10-01 |        1
(5 rows)

   rol    |  mes_alta  | cantidad 
----------+------------+----------
 ADMIN    | 2026-01-01 |        2
 VENDEDOR | 2026-02-01 |        2
 VENDEDOR | 2026-10-01 |        1
 USUARIO  | 2026-03-01 |        2
 USUARIO  | 2026-10-01 |        1
(5 rows)

   rol    |  mes_alta  | cantidad_anon | cantidad_real 
----------+------------+---------------+---------------
 ADMIN    | 2026-01-01 |             2 |             2
 VENDEDOR | 2026-02-01 |             2 |             2
 VENDEDOR | 2026-10-01 |             1 |             1
 USUARIO  | 2026-03-01 |             2 |             2
 USUARIO  | 2026-10-01 |             1 |             1
(5 rows)

psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/usuario_anon_cobertura.sql:173: NOTICE:  Comparacion adicional: diferencias 0/0, totales 8/8
DO
ROLLBACK

PSQL_EXIT=0
```

## Controles posteriores

Se realizaron tras cerrar la sesion del ensayo, mediante conexion nueva configurada solo lectura; codigo de salida 0.

| Control | Resultado |
|---|---|
| post_read_only | True |
| fixtures_and_objects_absent | True |
| counts_unchanged | True |
| sequences_unchanged | True |
| acls_unchanged | True |
| metadata_unchanged | True |
| rollback_in_output | True |
| files_unchanged | True |

Conteos originales antes/despues: `{"categoria": 2, "cliente": 3, "pedido": 5, "producto": 3, "detalle_pedido": 7, "usuario": 2}` / `{"categoria": 2, "cliente": 3, "pedido": 5, "producto": 3, "detalle_pedido": 7, "usuario": 2}`.

Secuencias antes/despues (last_value/is_called): `{"categoria": {"last_value": 2, "is_called": true}, "cliente": {"last_value": 3, "is_called": true}, "pedido": {"last_value": 5, "is_called": true}, "producto": {"last_value": 3, "is_called": true}, "usuario": {"last_value": 2, "is_called": true}}` / `{"categoria": {"last_value": 2, "is_called": true}, "cliente": {"last_value": 3, "is_called": true}, "pedido": {"last_value": 5, "is_called": true}, "producto": {"last_value": 3, "is_called": true}, "usuario": {"last_value": 2, "is_called": true}}`.

La tabla temporal deja de existir al cerrar su sesion; no fue inspeccionada desde la conexion posterior. Conteos, secuencias y ACL coincidentes no sustituyen una comparacion fila a fila de datos originales. Se comprobo ausencia de fixtures y del objeto publico y su tipo. No se muestra informacion personal, contrasenas ni hashes almacenados; las huellas publicadas corresponden a archivos. SQL y plan conservaron sus SHA-256. La evidencia historica permanece intacta. No se actualizaron informe, guia ni bitacora.
## Parametros de sesion y revision de salida

El ensayo uso psql -X -w, ON_ERROR_STOP=on y archivo -f sin echo de sentencias; sesion nueva. PGOPTIONS solo del proceso: lock_timeout=3000 ms, statement_timeout=30000 ms e idle_in_transaction_session_timeout=30000 ms; modo read-write para el ensayo. El archivo establecio REPEATABLE READ y America/Argentina/Buenos_Aires. Las conexiones de control usaron default_transaction_read_only=on y transaction_read_only=on con BEGIN READ ONLY y ROLLBACK. No se cambio configuracion persistente. La salida combinada stdout/stderr se reviso antes de guardarla: contiene metadatos, agregados y huellas de archivos, sin valores personales ni contrasenas o hashes almacenados.

La captura PREVIO enlazada corresponde al segundo control completo, realizado despues de verificar el respaldo e inmediatamente antes de la unica invocacion del ensayo. Tambien hubo un primer inventario de solo lectura anterior al respaldo, compatible con ese estado; no se presenta como una captura independiente adjunta.
