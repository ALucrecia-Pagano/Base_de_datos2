# TP7 — Roles y permisos vigentes (`\du` + `role_table_grants`)

- Fecha: 2026-10-15 (UTC-3). Base: `foodstore_dev`, solo lectura
  (`psql -X -w -U postgres`; sin contraseñas ni hashes en este archivo).
- La evidencia histórica de la Parte A.3 (`docs/kiro_roles_spec/verificacion_permisos.md`, 2026-10-14)
  solo listaba nombre y `LOGIN`: no equivale al `\du` completo. Esta captura sí incluye atributos
  (`CONNECTION LIMIT`, `Cannot login`, superusuario) y los `GRANT` vigentes.
- Estado capturado: **posterior a la corrección de seguridad** (catálogos revocados, funciones
  endurecidas). No describe el estado de la Parte A original; para ese veredicto histórico ver
  `verificacion_permisos.md`.

## 1. `\du` real

```text
                                 List of roles
     Role name     |                         Attributes
-------------------+------------------------------------------------------------
 admin_datos       | 5 connections
 app_web           | 20 connections
 postgres          | Superuser, Create role, Create DB, Replication, Bypass RLS
 rol_app_escritura | Cannot login
 rol_app_lectura   | Cannot login
 rol_auditoria     | Cannot login
 rol_reportes      | Cannot login
 rol_soporte       | Cannot login
 tp5_reportes      | Cannot login
```

Nota: `tp5_reportes` es un rol heredado de TP5, ajeno al modelo TP7; se conserva sin cambios.

## 2. `information_schema.role_table_grants` (roles TP7, schema `public`)

97 filas. Resumen verificado contra la especificación (salida cruda completa en
`salida_roles_vigentes_20261015.txt`):

- `admin_datos`: `ALL` (77 filas = 7 privilegios × 11 objetos: 6 tablas + 5 vistas; ver nota).
- `rol_app_escritura`: `INSERT, UPDATE` en las 5 tablas de negocio; sin `DELETE`; nada en `usuario`.
- `rol_app_lectura`: `SELECT` en las 5 tablas + 3 vistas operativas.
- `rol_reportes`: `SELECT` en `v_reporte_ventas_cliente` y `v_usuario_publico`.
- `rol_soporte`, `rol_auditoria`: sin filas a nivel de tabla (soporte opera por columnas, RF-03).

Nota: `mv_resumen_ventas_categoria_mes` no aparece en `role_table_grants` (las vistas materializadas no
forman parte de esa vista del esquema); sus permisos constan en la especificación y en `roles.sql §7`.
