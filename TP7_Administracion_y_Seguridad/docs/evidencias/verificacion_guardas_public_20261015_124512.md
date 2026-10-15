# TP7 — Pruebas negativas de guardas y consulta PUBLIC

- Fecha: 2026-10-15 (UTC-3). Inicio de preparación: 12:45:12.
  Registro completado: 2026-10-15T12:47:38-03:00.
- Autorización: pedido del usuario para estos diez casos negativos y la consulta de diseño §7.6.
  La aprobación humana del resultado está pendiente; no se atribuye al grupo.
- Base/usuario confirmados: `foodstore_dev`, `postgres` (session_user también postgres).
  Motor: PostgreSQL 17.11. `default_transaction_read_only=on` y `transaction_read_only=on`.
- Sin instalación, simulacro completo, cambios de permisos/datos/configuración persistente,
  commit, push ni merge. Todas las conexiones usan `psql -X -w`, host localhost y puerto 5432.
- [Salida completa nueva](salida_guardas_public_20261015_124512.txt), con stdout/stderr y códigos de salida. Las evidencias
  anteriores, los scripts y README permanecen intactos.

## Preparación y autenticación

Se revisó el contenido real antes de conectar: las cinco guardas y ON_ERROR_STOP preceden
al BEGIN principal (preparar: guardas líneas 15/19 y BEGIN 22; instalar: 23/27 y BEGIN 30;
simulacro: 34 y BEGIN 37). Nunca se proporcionaron todas las variables requeridas.

La primera conexión con `-w` no encontró contraseña disponible: terminó con exit 2
(`fe_sendauth: no password supplied`), sin ejecutar SQL ni casos. Se indicó después mediante
PGPASSFILE el archivo de autenticación ya existente `C:/Users/hp/.pgpass`; no se creó,
modificó ni publicó su contenido. No se imprimieron credenciales.

Entorno exclusivo de cada proceso psql (sin cambiar configuración persistente):

```text
PGPASSFILE=C:/Users/hp/.pgpass
PGOPTIONS=-c default_transaction_read_only=on -c transaction_read_only=on
PGCLIENTENCODING=UTF8
PGCONNECT_TIMEOUT=5
PGAPPNAME=TP7_verificacion_guardas_solo_lectura
```

Consulta de preparación, exit 0:

```sql
SELECT current_database() AS base, current_user AS usuario, session_user AS usuario_sesion, current_setting('server_version') AS version, current_setting('default_transaction_read_only') AS default_solo_lectura, current_setting('transaction_read_only') AS transaccion_solo_lectura;
```

Resultado capturado:

```text
     base      | usuario  | usuario_sesion | version | default_solo_lectura | transaccion_solo_lectura 
---------------+----------+----------------+---------+----------------------+--------------------------
 foodstore_dev | postgres | postgres       | 17.11   | on                   | on
(1 row)
```

## Diez pruebas negativas

Antes de cada caso se ejecutó explícitamente `\unset` para lab_c_password_01,
lab_c_password_02 y lab_sim_password_ok. Para probar la segunda variable se definió
únicamente la primera con el valor sintético `SinteticaSoloGuarda_20261015`.
El padre temporal también activa ON_ERROR_STOP. Los padres se guardaron fuera del repositorio,
en `C:/Users/hp/AppData/Local/Temp/tp7_guardas_20261015_124512`.

| Caso | Script | Variable ausente | Modalidad | Exit | Error de guarda | Marcador posterior |
|---|---|---|---|---|---|---|
| 01 | preparar_entorno_local.sql | lab_c_password_01 | directa | 3 | Esperado, observado | No corresponde |
| 02 | preparar_entorno_local.sql | lab_c_password_01 | incluida | 3 | Esperado, observado | Ausente |
| 03 | preparar_entorno_local.sql | lab_c_password_02 | directa | 3 | Esperado, observado | No corresponde |
| 04 | preparar_entorno_local.sql | lab_c_password_02 | incluida | 3 | Esperado, observado | Ausente |
| 05 | instalar_entorno_local.sql | lab_c_password_01 | directa | 3 | Esperado, observado | No corresponde |
| 06 | instalar_entorno_local.sql | lab_c_password_01 | incluida | 3 | Esperado, observado | Ausente |
| 07 | instalar_entorno_local.sql | lab_c_password_02 | directa | 3 | Esperado, observado | No corresponde |
| 08 | instalar_entorno_local.sql | lab_c_password_02 | incluida | 3 | Esperado, observado | Ausente |
| 09 | simulacro_incidente.sql | lab_sim_password_ok | directa | 3 | Esperado, observado | No corresponde |
| 10 | simulacro_incidente.sql | lab_sim_password_ok | incluida | 3 | Esperado, observado | Ausente |

### Comandos y errores efectivamente observados

**Caso 01.**

Comando Windows (sin secretos; el único valor de variable suministrado es sintético):

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -c "\set ON_ERROR_STOP on" -c "\unset lab_c_password_01" -c "\unset lab_c_password_02" -c "\unset lab_sim_password_ok" -f C:\Users\hp\Practicos\TP7_Administracion_y_Seguridad\sql\preparar_entorno_local.sql
```

Error capturado:

```text
psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/preparar_entorno_local.sql:15: ERROR:  Falta -v lab_c_password_01 (sintética, no real), STOP
CONTEXT:  función PL/pgSQL inline_code_block en la línea 1 en RAISE
PSQL_EXIT=3
```

**Caso 02.**

Comando Windows (sin secretos; el único valor de variable suministrado es sintético):

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -f C:\Users\hp\AppData\Local\Temp\tp7_guardas_20261015_124512\padre_caso_02.sql
```

Contenido exacto del padre temporal:

```sql
\set ON_ERROR_STOP on
\unset lab_c_password_01
\unset lab_c_password_02
\unset lab_sim_password_ok
\ir 'C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/preparar_entorno_local.sql'
SELECT 'TP7_GUARDA_NO_DEBE_ALCANZARSE_CASO_02_20261015_124512' AS marcador_posterior;
```

Error capturado:

```text
psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/preparar_entorno_local.sql:15: ERROR:  Falta -v lab_c_password_01 (sintética, no real), STOP
CONTEXT:  función PL/pgSQL inline_code_block en la línea 1 en RAISE
PSQL_EXIT=3
```

Marcador buscado en stdout y stderr: `TP7_GUARDA_NO_DEBE_ALCANZARSE_CASO_02_20261015_124512`, ausente.

**Caso 03.**

Comando Windows (sin secretos; el único valor de variable suministrado es sintético):

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -c "\set ON_ERROR_STOP on" -c "\unset lab_c_password_01" -c "\unset lab_c_password_02" -c "\unset lab_sim_password_ok" -c "\set lab_c_password_01 SinteticaSoloGuarda_20261015" -f C:\Users\hp\Practicos\TP7_Administracion_y_Seguridad\sql\preparar_entorno_local.sql
```

Error capturado:

```text
psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/preparar_entorno_local.sql:19: ERROR:  Falta -v lab_c_password_02 (sintética, no real), STOP
CONTEXT:  función PL/pgSQL inline_code_block en la línea 1 en RAISE
PSQL_EXIT=3
```

**Caso 04.**

Comando Windows (sin secretos; el único valor de variable suministrado es sintético):

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -f C:\Users\hp\AppData\Local\Temp\tp7_guardas_20261015_124512\padre_caso_04.sql
```

Contenido exacto del padre temporal:

```sql
\set ON_ERROR_STOP on
\unset lab_c_password_01
\unset lab_c_password_02
\unset lab_sim_password_ok
\set lab_c_password_01 SinteticaSoloGuarda_20261015
\ir 'C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/preparar_entorno_local.sql'
SELECT 'TP7_GUARDA_NO_DEBE_ALCANZARSE_CASO_04_20261015_124512' AS marcador_posterior;
```

Error capturado:

```text
psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/preparar_entorno_local.sql:19: ERROR:  Falta -v lab_c_password_02 (sintética, no real), STOP
CONTEXT:  función PL/pgSQL inline_code_block en la línea 1 en RAISE
PSQL_EXIT=3
```

Marcador buscado en stdout y stderr: `TP7_GUARDA_NO_DEBE_ALCANZARSE_CASO_04_20261015_124512`, ausente.

**Caso 05.**

Comando Windows (sin secretos; el único valor de variable suministrado es sintético):

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -c "\set ON_ERROR_STOP on" -c "\unset lab_c_password_01" -c "\unset lab_c_password_02" -c "\unset lab_sim_password_ok" -f C:\Users\hp\Practicos\TP7_Administracion_y_Seguridad\sql\instalar_entorno_local.sql
```

Error capturado:

```text
psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/instalar_entorno_local.sql:23: ERROR:  Falta -v lab_c_password_01 (sintética, no real), STOP
CONTEXT:  función PL/pgSQL inline_code_block en la línea 1 en RAISE
PSQL_EXIT=3
```

**Caso 06.**

Comando Windows (sin secretos; el único valor de variable suministrado es sintético):

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -f C:\Users\hp\AppData\Local\Temp\tp7_guardas_20261015_124512\padre_caso_06.sql
```

Contenido exacto del padre temporal:

```sql
\set ON_ERROR_STOP on
\unset lab_c_password_01
\unset lab_c_password_02
\unset lab_sim_password_ok
\ir 'C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/instalar_entorno_local.sql'
SELECT 'TP7_GUARDA_NO_DEBE_ALCANZARSE_CASO_06_20261015_124512' AS marcador_posterior;
```

Error capturado:

```text
psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/instalar_entorno_local.sql:23: ERROR:  Falta -v lab_c_password_01 (sintética, no real), STOP
CONTEXT:  función PL/pgSQL inline_code_block en la línea 1 en RAISE
PSQL_EXIT=3
```

Marcador buscado en stdout y stderr: `TP7_GUARDA_NO_DEBE_ALCANZARSE_CASO_06_20261015_124512`, ausente.

**Caso 07.**

Comando Windows (sin secretos; el único valor de variable suministrado es sintético):

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -c "\set ON_ERROR_STOP on" -c "\unset lab_c_password_01" -c "\unset lab_c_password_02" -c "\unset lab_sim_password_ok" -c "\set lab_c_password_01 SinteticaSoloGuarda_20261015" -f C:\Users\hp\Practicos\TP7_Administracion_y_Seguridad\sql\instalar_entorno_local.sql
```

Error capturado:

```text
psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/instalar_entorno_local.sql:27: ERROR:  Falta -v lab_c_password_02 (sintética, no real), STOP
CONTEXT:  función PL/pgSQL inline_code_block en la línea 1 en RAISE
PSQL_EXIT=3
```

**Caso 08.**

Comando Windows (sin secretos; el único valor de variable suministrado es sintético):

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -f C:\Users\hp\AppData\Local\Temp\tp7_guardas_20261015_124512\padre_caso_08.sql
```

Contenido exacto del padre temporal:

```sql
\set ON_ERROR_STOP on
\unset lab_c_password_01
\unset lab_c_password_02
\unset lab_sim_password_ok
\set lab_c_password_01 SinteticaSoloGuarda_20261015
\ir 'C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/instalar_entorno_local.sql'
SELECT 'TP7_GUARDA_NO_DEBE_ALCANZARSE_CASO_08_20261015_124512' AS marcador_posterior;
```

Error capturado:

```text
psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/instalar_entorno_local.sql:27: ERROR:  Falta -v lab_c_password_02 (sintética, no real), STOP
CONTEXT:  función PL/pgSQL inline_code_block en la línea 1 en RAISE
PSQL_EXIT=3
```

Marcador buscado en stdout y stderr: `TP7_GUARDA_NO_DEBE_ALCANZARSE_CASO_08_20261015_124512`, ausente.

**Caso 09.**

Comando Windows (sin secretos; el único valor de variable suministrado es sintético):

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -c "\set ON_ERROR_STOP on" -c "\unset lab_c_password_01" -c "\unset lab_c_password_02" -c "\unset lab_sim_password_ok" -f C:\Users\hp\Practicos\TP7_Administracion_y_Seguridad\sql\simulacro_incidente.sql
```

Error capturado:

```text
psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/simulacro_incidente.sql:34: ERROR:  Falta -v lab_sim_password_ok (sintética, no real), STOP
CONTEXT:  función PL/pgSQL inline_code_block en la línea 1 en RAISE
PSQL_EXIT=3
```

**Caso 10.**

Comando Windows (sin secretos; el único valor de variable suministrado es sintético):

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -f C:\Users\hp\AppData\Local\Temp\tp7_guardas_20261015_124512\padre_caso_10.sql
```

Contenido exacto del padre temporal:

```sql
\set ON_ERROR_STOP on
\unset lab_c_password_01
\unset lab_c_password_02
\unset lab_sim_password_ok
\ir 'C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/simulacro_incidente.sql'
SELECT 'TP7_GUARDA_NO_DEBE_ALCANZARSE_CASO_10_20261015_124512' AS marcador_posterior;
```

Error capturado:

```text
psql:C:/Users/hp/Practicos/TP7_Administracion_y_Seguridad/sql/simulacro_incidente.sql:34: ERROR:  Falta -v lab_sim_password_ok (sintética, no real), STOP
CONTEXT:  función PL/pgSQL inline_code_block en la línea 1 en RAISE
PSQL_EXIT=3
```

Marcador buscado en stdout y stderr: `TP7_GUARDA_NO_DEBE_ALCANZARSE_CASO_10_20261015_124512`, ausente.

En los diez casos stdout estuvo vacío y el error esperado detuvo el archivo antes del BEGIN
principal. En los cinco incluidos no se alcanzó el SELECT posterior. Son pruebas negativas:
no prueban una ejecución completa de los instaladores ni del simulacro.

## Consulta PUBLIC, ejecutada una vez

Como postgres en foodstore_dev, con el mismo entorno de solo lectura:

```sql
SELECT grantor, grantee, table_schema, table_name, privilege_type, is_grantable
FROM information_schema.table_privileges
WHERE grantee = 'PUBLIC'
  AND table_schema = 'public'
ORDER BY table_name, privilege_type, grantor;
```

Comando:

```text
"C:\Program Files\PostgreSQL\17\bin\psql.exe" -X -w -h localhost -p 5432 -U postgres -d foodstore_dev -v ON_ERROR_STOP=on -c "SELECT grantor, grantee, table_schema, table_name, privilege_type, is_grantable
FROM information_schema.table_privileges
WHERE grantee = 'PUBLIC'
  AND table_schema = 'public'
ORDER BY table_name, privilege_type, grantor;"
```

Resultado real:

```text
 grantor | grantee | table_schema | table_name | privilege_type | is_grantable 
---------+---------+--------------+------------+----------------+--------------
(0 rows)
PSQL_EXIT=0
```

No se observaron otorgamientos en esta consulta: 0 filas. Alcance: otorgamientos a PUBLIC
sobre tablas y vistas regulares del esquema public visibles mediante table_privileges para
esta sesión. No verifica permisos de esquema, columnas, funciones, secuencias ni materializadas,
ni sustituye una comprobación exhaustiva de privilegios efectivos por herencia.

## Límites y revisión

No se ejecutaron los cuerpos de instalación, preparación o simulacro; no se proporcionó nunca
el conjunto completo de variables. Estas pruebas no revalidan las ejecuciones completas históricas,
ni prueban todos los caminos de error. No se ejecutaron DDL/DML ni ajustes de permisos/configuración.
La revisión humana y la publicación de los nuevos cambios documentales siguen pendientes.
No se reconstruyen prompts históricos faltantes.

La copia Markdown normaliza solo la visualización de saltos CR en los bloques citados;
el archivo de salida enlazado conserva los bytes stdout/stderr capturados, con separadores añadidos.

## Verificación final de archivos

Comparación SHA-256 con el inicio: 191 archivos previos intactos, incluidos todos los SQL,
evidencias anteriores, logs, respuesta íntegra C, README y otros TP. Solo se actualizaron siete
archivos documentales y se crearon esta evidencia y su salida. Se comprobaron 144 enlaces locales
con destino existente (decodificando %20), bitácora de 21 filas contando cabecera/separador con tres
columnas y git diff --check sin errores. No se hicieron commit, push ni merge.
