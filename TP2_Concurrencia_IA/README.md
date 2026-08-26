# TP2 — Concurrencia e IA

Trabajo Práctico de Laboratorio — Base de Datos II (UTN FRM)
Unidad 1 · Integridad, Transacciones y Concurrencia — Semana 2

Alumna: Liendo Mateo, Avila Lucas, Pagano Amanda  — Comisión 4
Trabajo grupal, sobre el esquema del proyecto integrador FoodStore (ver `TP1_FoodStore/`).

## Entorno de trabajo

- PostgreSQL 17.11, instalado y administrado localmente por línea de comandos (`psql`, Git Bash).
- Base de desarrollo: `foodstore_dev`, cargada desde `TP1_FoodStore/schema.sql`.
- Base de trabajo/pruebas: `foodstore_copia_trabajo`, copia exacta de `foodstore_dev` usada para todas las pruebas riesgosas.
- Herramientas de IA: OpenCode (generación de restricciones) y Kiro (steering docs de contexto del proyecto).

## Estructura de esta carpeta

```
TP2_Concurrencia_IA/
└── parte1/
    ├── restricciones_integridad.sql   # Triggers de integridad generados con OpenCode
    ├── respaldo_foodstore_copia_trabajo.sql   # Respaldo previo a aplicar el cambio (protocolo de seguridad)
    └── DUIA_parte1.md                 # Declaración de Uso de IA de esta parte
```

## Contenido por parte

- **Parte 0** — Protocolo de seguridad: ver `protocolo_seguridad.md` en la raíz del repositorio.
- **Parte 1** — Integridad versionada con OpenCode (`parte1/`): tres restricciones de negocio hoy no garantizadas por el motor:
  1. Un pedido en estado `ENTREGADO` o `CANCELADO` no puede volver a `PENDIENTE` ni `EN_PREPARACION`.
  2. La `fecha_hora` de un pedido no puede ser posterior al momento actual.
  3. La `cantidad` de una línea de `detalle_pedido` no puede superar el `stock` disponible del producto.

  Cada restricción se probó dentro de una transacción sobre `foodstore_copia_trabajo`, con casos inválidos (que deben fallar) y un caso válido (que debe aplicarse sin problema), antes de confirmar con `COMMIT`.
- **Parte 2** — Laboratorio de anomalías de concurrencia (en curso).
- **Parte 3** — Lectura crítica de scripts SQL (pendiente).