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

La estructura de entrega solicitada por la cátedra es:

```text
food-store/
├── README.md
├── movil/
│   ├── schema_sqlite.sql
│   ├── pruebas_sqlite.sql
│   ├── semaforo.sql
│   ├── servidor_snapshot.csv
│   └── foodstore_movil.db
├── docs/
│   └── informe.pdf
└── kiro/
    ├── bitacora_ia.md
    ├── DUIA.md
    ├── requirements.md
    ├── design.md
    └── tasks.md
```

Durante el desarrollo también se conservan scripts, bases de prueba y
documentación intermedia dentro de `movil/`, `postgresql/` y `docs/`.

## Estado del trabajo práctico

### Módulos completados

| Módulo | Estado | Resultado |
|---|---|---|
| Consigna 1.a — Qué datos viajan | **[COMPLETADO]** | Se definió el catálogo mínimo que viaja a SQLite: identificador, nombre, precio observado en centavos, stock observado, disponibilidad, baja lógica y fecha de copia. |
| Consigna 1.b — `schema_sqlite.sql` | **[COMPLETADO]** | Se crearon las tablas `producto_cache`, `pedido_borrador`, `item_borrador` y `cola_sync`, con `STRICT`, claves foráneas y restricciones `CHECK`. |
| Consigna 1.c — `pruebas_sqlite.sql` | **[COMPLETADO]** | Reejecutada con SQLite CLI: `COMMIT`, `ROLLBACK`, consulta offline C1 y rechazo de C7 por cantidad cero y producto inexistente. Veredicto: aprobado. |
| Consigna 2.a — `v_snapshot_movil` | **[COMPLETADO]** | Se creó la vista de lectura en PostgreSQL, se exportaron tres productos y se importaron a SQLite mediante `servidor_snapshot.csv`. |
| Consigna 2.b — `semaforo.sql` | **[COMPLETADO]** | Reejecutada con SQLite CLI: solicitud compatible clasificada como `SIMULADO_APROBADO`, con idempotencia y una única solicitud conservada. Veredicto: aprobado. |
| Consigna 2.c — Casos C2 a C6 | **[COMPLETADO]** | Se verificaron cambio de precio, stock insuficiente, baja lógica, solicitud sin cambios y reenvío con UUID repetido. C1 y C7 quedaron probados en la Consigna 1. |

La lógica móvil quedó validada con SQLite: la tablet consulta la instantánea y
arma borradores, mientras que PostgreSQL continúa siendo la fuente de verdad.
Las pruebas no modificaron PostgreSQL ni MongoDB.

### Módulos pendientes

| Módulo | Responsable | Entregables faltantes |
|---|---|---|
| Consigna 3.a — Mapa de la capa de datos | Amanda | Tabla o diagrama que integre PostgreSQL, MongoDB de TP7/Unidad 7 y SQLite, indicando qué conserva cada motor y quién es la autoridad sobre cada dato. |
| Consigna 3.b — Plan de mantenimiento | Amanda | Sección sobre respaldos, pruebas de restauración, comportamiento de las tablets ante la restauración de un respaldo antiguo y revisión periódica de solicitudes `CONFLICTO` o `RECHAZADO`. |
| Consigna 3.c — Code review con IA | Amanda | Revisión de los scripts de la cursada con OpenCode, usando el Plan Agent; tabla de hallazgos con decisión y motivo, más el desarrollo de al menos tres hallazgos de dos unidades distintas, incluyendo uno descartado con fundamento. |
| Consigna 4.a — Spec en Kiro | Lucas | `requirements.md` con cuatro requisitos EARS y sus casos de prueba, además de `design.md` y `tasks.md`. |
| Consigna 4.b — Bitácora de IA y DUIA | Lucas | `bitacora_ia.md` con al menos tres entradas sobre solicitudes, decisiones y descartes de IA, junto con `DUIA.md`. |
| Consigna 4.c — README, informe y defensa | Lucas | README final, `docs/informe.pdf` de hasta seis páginas y ensayo de defensa de diez minutos con mapa, caso en vivo y hallazgo de la revisión con IA. |

## Guía de ejecución

Los siguientes pasos reproducen lo realizado hasta el momento. Deben
ejecutarse sobre copias de prueba y con datos ficticios. PostgreSQL se utiliza
como origen de lectura; no se modifican sus tablas.

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
