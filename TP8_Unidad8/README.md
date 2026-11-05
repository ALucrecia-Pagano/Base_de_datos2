# Food Store — Trabajo Práctico N.º 8

**Base de Datos II — UTN FRM — 2026**

## Descripción

Este trabajo práctico simula el funcionamiento de una tablet para un puesto de
Food Store en una feria sin conexión. La tablet utiliza SQLite para consultar
una instantánea del catálogo y crear borradores de pedidos. La sincronización
se simula comparando esos borradores con una instantánea de PostgreSQL mediante
un semáforo.

La regla funcional central es que la aplicación móvil propone y el servidor
decide. PostgreSQL conserva la autoridad sobre precios, stock y ventas.

## Estructura del repositorio

La estructura de entrega solicitada por la cátedra, con los archivos que ya
existen en `TP8_Unidad8/`, es:

```text
TP8_Unidad8/
├── README.md
├── movil/
│   ├── schema_sqlite.sql
│   ├── pruebas_sqlite.sql
│   ├── importar_snapshot.sql
│   ├── recargar_snapshot.sql
│   ├── semaforo.sql
│   ├── casos_2c.sql
│   ├── servidor_snapshot.csv
│   ├── servidor_snapshot_2c.csv
│   └── foodstore_movil.db
├── postgresql/
│   ├── vista_snapshot_movil.sql
│   ├── preparar_casos_2c.sql
│   └── verificar_sin_cambios_2c.sql
└── docs/
    ├── informe.pdf
    ├── kiro/
    │   ├── requirements.md
    │   ├── design.md
    │   └── tasks.md
    ├── bitacora_ia.md
    └── DUIA.md
```

Durante el desarrollo también se conservan bases de prueba y documentación
intermedia (`docs/consigna_*.md`, `docs/resultado_*.md`) dentro de `movil/` y
`docs/`.

## Estado del trabajo práctico

### Módulos completados

| Módulo | Estado | Resultado |
|---|---|---|
| Consigna 1.a — Qué datos viajan | **[COMPLETADO]** | Se definió el catálogo mínimo que viaja a SQLite: identificador, nombre, precio observado en centavos, stock observado, disponibilidad, baja lógica y fecha de copia. |
| Consigna 1.b — `schema_sqlite.sql` | **[COMPLETADO]** | Se crearon las tablas `producto_cache`, `pedido_borrador`, `item_borrador` y `cola_sync`, con `STRICT`, claves foráneas y restricciones `CHECK`. |
| Consigna 1.c — `pruebas_sqlite.sql` | **[COMPLETADO]** | Reejecutada con SQLite CLI: `COMMIT`, `ROLLBACK`, consulta offline C1 y rechazo de C7 por cantidad cero y producto inexistente. Veredicto: aprobado. |
| Consigna 2.a — `v_snapshot_movil` | **[COMPLETADO]** | Se creó la vista de lectura en PostgreSQL, se exportaron tres productos y se importaron a SQLite mediante `servidor_snapshot.csv`. |
| Consigna 2.b — `semaforo.sql` | **[COMPLETADO]** | Reejecutada con SQLite CLI: solicitud compatible clasificada como `SIMULADO_APROBADO`, con idempotencia y una única solicitud conservada. Veredicto: aprobado. |
| Consigna 2.c — Casos C2 a C6 | **[COMPLETADO]** | Los cambios de C2 (precio) y C4 (baja lógica) se hacen en una copia de PostgreSQL (`foodstore_tp8_feria`) con `postgresql/preparar_casos_2c.sql`, que exporta `movil/servidor_snapshot_2c.csv`. La tablet la recarga con `movil/recargar_snapshot.sql`. `postgresql/verificar_sin_cambios_2c.sql` muestra que pedidos y stock no cambiaron. Detalle en `docs/consigna_2c.md` y `docs/resultado_casos_2c.md`. |
| Consigna 3.a — Mapa de la capa de datos | **[COMPLETADO]** | PostgreSQL, MongoDB (Unidad 7) y SQLite: qué guarda cada motor y quién manda sobre cada dato (`docs/consigna_3a.md`). |
| Consigna 3.b — Plan de mantenimiento | **[COMPLETADO]** | Agregado al plan de la Unidad 6: respaldo y prueba por motor, qué hacen las tablets si se restaura un respaldo viejo y revisión de `CONFLICTO` y `RECHAZADO` (`docs/consigna_3b.md`). |
| Consigna 3.c — Code review con IA | **[COMPLETADO]** | Revisión de los 75 scripts de la cursada con Antigravity en modo Plan: 24 hallazgos con decisión; tres desarrollados y comprobados en la base (F05 aceptado, F07 corregido, F09 descartado) (`docs/consigna_3c.md`). |
| Consigna 4.a — Spec en Kiro | **[COMPLETADO]** | `docs/kiro/requirements.md` con cuatro requisitos EARS (REQ-01 a REQ-04, probados con C2, C3, C4 y C6), `design.md` y `tasks.md`. La spec es retroactiva: se escribió después del código y se comprobó contra él (ver `docs/bitacora_ia.md`). |

La lógica móvil quedó validada con SQLite: la tablet consulta la instantánea y
arma borradores, mientras que PostgreSQL continúa siendo la fuente de verdad.
Las pruebas no modificaron PostgreSQL ni MongoDB.

### Módulos pendientes

| Módulo | Responsable | Entregables faltantes |
|---|---|---|
| Consigna 4.b — Bitácora de IA y DUIA | Mateo | Completar su parte (agente de GitHub Copilot) en `docs/bitacora_ia.md` y `docs/DUIA.md`. |
| Consigna 4.c — Ensayo de defensa | Los tres | Ensayo de diez minutos en la clase de la semana 13: mapa, caso en vivo y hallazgo de la revisión con IA. |

## Guía de ejecución

**Requisitos previos:** PostgreSQL 17 con una copia de pruebas de Food Store (`foodstore_tp8_feria`, creada con `createdb -U postgres -T foodstore_dev foodstore_tp8_feria`),
SQLite CLI 3.37 o superior (las tablas `STRICT` lo exigen) y una copia de este
repositorio. Todos los comandos se ejecutan desde la raíz del repositorio,
porque `casos_2c.sql` usa rutas relativas a `TP8_Unidad8/`.

Los siguientes pasos reproducen lo realizado hasta el momento. Deben
ejecutarse sobre copias de prueba y con datos ficticios. PostgreSQL se utiliza
como origen de lectura; solo la preparación de la consigna 2.c cambia un precio
y una baja lógica en la copia de pruebas.

### 1. Exportar la instantánea desde PostgreSQL

Crear la vista de lectura con
`postgresql/vista_snapshot_movil.sql` y, desde `psql`, exportar:

```sql
\copy (SELECT * FROM v_snapshot_movil) TO 'TP8_Unidad8/movil/servidor_snapshot.csv' CSV HEADER
```

La exportación contiene los productos, el precio en centavos, el stock, la
disponibilidad, la baja lógica derivada y la fecha de copia.

### 2. Crear la base SQLite

Desde la raíz del repositorio:

```powershell
sqlite3 TP8_Unidad8\movil\foodstore_sync_2a.db
```

Dentro de SQLite:

```sql
.read TP8_Unidad8\movil\schema_sqlite.sql
```

### 3. Importar la instantánea y ejecutar las pruebas

Importar el CSV omitiendo los encabezados de PostgreSQL:

```sql
.mode csv
.import --csv --skip 1 TP8_Unidad8\movil\servidor_snapshot.csv snapshot_servidor_import
.read TP8_Unidad8\movil\importar_snapshot.sql
```

Para reproducir la Consigna 1 sobre una base independiente:

```sql
.read TP8_Unidad8\movil\pruebas_sqlite.sql
```

Las sentencias C7 deben producir errores de restricciones de forma
intencional: `CHECK constraint failed` y `FOREIGN KEY constraint failed`.
Cada caso se ejecuta dentro de una transacción con inserciones previas y
termina con `ROLLBACK`; las consultas posteriores deben mostrar cero filas
parciales.

### 4. Ejecutar la simulación del semáforo

Sobre una copia de trabajo que contenga la instantánea, borradores y
solicitudes:

```sql
.read TP8_Unidad8\movil\semaforo.sql
```

El semáforo solo evalúa solicitudes `PENDIENTE`. No descuenta stock, no cambia
precios y no confirma ventas en PostgreSQL.

### 5. Ejecutar los casos C2 a C6

Primero, en la copia de PostgreSQL y desde la raíz del repositorio:

```bash
psql -U postgres -d foodstore_tp8_feria -f TP8_Unidad8/postgresql/verificar_sin_cambios_2c.sql
psql -U postgres -d foodstore_tp8_feria -f TP8_Unidad8/postgresql/preparar_casos_2c.sql
```

El primero registra la cantidad de pedidos y el stock. El segundo sube el
precio del producto 1, da de baja el producto 3 y exporta
`movil/servidor_snapshot_2c.csv` (ya incluido en el repositorio). Después,
sobre una copia nueva de SQLite con el esquema y la instantánea inicial
importados (pasos 2 y 3, sin ejecutar antes `pruebas_sqlite.sql`):

```sql
.read TP8_Unidad8\movil\casos_2c.sql
```

El script ejecuta el semáforo por su cuenta, y como `semaforo.sql` termina con un
`SELECT`, durante la ejecución aparece primero una lista parcial de solicitudes
(esto es normal). La última consulta debe mostrar
cinco solicitudes: `c2-solicitud-1` en `CONFLICTO`, `c2-solicitud-2` y
`c5-solicitud` en `SIMULADO_APROBADO`, y `c3-solicitud` y `c4-solicitud` en
`RECHAZADO`. Antes de esa consulta aparece el error intencional de C6:
`UNIQUE constraint failed: cola_sync.solicitud_uuid`.

Al final, volver a ejecutar `verificar_sin_cambios_2c.sql`: la cantidad de
pedidos y el stock deben ser iguales a los del inicio.

### 6. Qué prueba cada requisito de la spec

| Requisito (`docs/kiro/requirements.md`) | Caso | Se ve en |
|---|---|---|
| REQ-01 — precio distinto → `CONFLICTO` | C2 | `c2-solicitud-1` |
| REQ-02 — stock insuficiente → `RECHAZADO` | C3 | `c3-solicitud` |
| REQ-03 — producto dado de baja → `RECHAZADO` | C4 | `c4-solicitud` |
| REQ-04 — UUID repetido no se duplica ni se reevalúa | C6 | error de unicidad y estado de `c5-solicitud` sin cambios |

## Entrega

Un `.zip` o el enlace al repositorio con la etiqueta `tp8`, en el campus, antes
del cierre de la semana 13. No hay entregas tardías.

## Regla de oro del proyecto

> **El móvil propone, el servidor dispone. La tablet solo consulta y arma
> borradores. Precio, stock y ventas los decide PostgreSQL.**

## Restricciones de trabajo

- Utilizar copias y datos inventados para las pruebas.
- No incluir contraseñas, correos ni datos personales reales.
- No modificar PostgreSQL desde SQLite ni presentar
  `SIMULADO_APROBADO` como una venta.
- Leer y probar todo código generado con IA antes de utilizarlo.
- Conservar scripts y evidencias reproducibles, no solamente capturas.
