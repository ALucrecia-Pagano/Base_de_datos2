# Practicos Base de Datos II
Entrega de Practicos para la Materia BDII, desde un repositorio de GIT
Alumnos: Liendo Mateo, Avila Lucas, Pagano Amanda.
Comisión: 4.
Profesor: Neira Sergio.

## Estructura del repositorio

Todo el trabajo gira en torno a un mismo proyecto integrador: **FoodStore**, un sistema de pedidos tipo delivery (categorías, clientes, productos, pedidos y detalle de pedidos). Cada TP retoma y amplía ese mismo esquema.

```
Practicos/
├── TP1_FoodStore/          # TP1: modelado ER, normalización y DDL en PostgreSQL (trabajo grupal)
├── TP2_Concurrencia_IA/    # TP2: concurrencia, integridad y uso de IA (OpenCode/Kiro) — individual
│   └── parte1/             # Restricciones de integridad versionadas
├── protocolo_seguridad.md  # Protocolo de seguridad para el trabajo con IA (TP2, Parte 0)
├── AGENTS.md               # Contexto del repo generado con OpenCode
└── .kiro/steering/         # Documentos de contexto generados con Kiro
```

## TP1 — FoodStore (modelado y DDL)

Proyecto integrador de Base de Datos I: diseño completo de la base de datos FoodStore, con modelo entidad-relación, derivación al modelo relacional, normalización hasta BCNF y el script DDL final (`schema.sql`) para PostgreSQL, junto con la Declaración de Uso de IA (DUIA) del trabajo original.

## TP2 — Concurrencia e IA

sobre el mismo esquema de FoodStore. Trabajo práctico de laboratorio sobre integridad, transacciones y concurrencia. Incluye:

- **Parte 0** (`protocolo_seguridad.md`, en la raíz): protocolo de copia, transacción y respaldo para trabajar de forma segura con scripts generados por IA.
- **Parte 1** (`TP2_Concurrencia_IA/parte1/`): restricciones de integridad generadas con OpenCode (transición de estado de pedidos, fecha no futura, validación de stock), probadas y aplicadas sobre una copia de trabajo, con su respectiva Declaración de Uso de IA (DUIA).
- **Parte 2** (en curso): laboratorio de anomalías de concurrencia con dos sesiones simultáneas.
- **Parte 3** (pendiente): ejercicio de lectura crítica de scripts SQL.
