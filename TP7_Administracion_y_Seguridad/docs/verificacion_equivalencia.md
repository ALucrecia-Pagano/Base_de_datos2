# TP7 Parte D — Verificación de equivalencia (usuario_anon)

> Estado: **ejecutado una vez** el 2026-10-15 (~09:16 UTC-3) sobre `foodstore_dev`
> (PostgreSQL 17.11), `PSQL_EXIT=0`, `ROLLBACK` final. Salida íntegra en
> `docs/evidencias/salida_psql_usuario_anon_20261015_091628.txt`.

## 1. Transformación

`sql/usuario_anon.sql` crea `public.usuario_anon` solo dentro de una transacción
que termina en `ROLLBACK`:

- Columnas: `id_anon` (subrogada), `nombre_lab`, `mail_lab`, `rol`, `eliminado`,
  `mes_alta DATE` (día 1 del mes).
- Sintéticos deterministas: `'LabD-Anon-' || id` y
  `'lab_d_anon_' || id || '@example.invalid'` (dominio `.invalid`, como en C).
- Se conservan únicamente `rol`, `eliminado` y el mes de alta, lo necesario
  para la agregación pedida. Se descartan: `celular`, `contrasena`/hash
  (ni siquiera hay columna), `apellido` y `nombre` reales, `mail` real,
  `id` original y la precisión completa de `created_at`.
- Alcance: todas las filas de `usuario`, incluidas las eliminadas, en ambas
  consultas y sin filtros diferentes.

Limitación: los valores derivan del `id` —el `id` original es recuperable a
partir de `nombre_lab`/`mail_lab`— y los grupos pequeños permiten
reidentificar por `rol × mes`. Es seudonimización de laboratorio, no
anonimización irreversible: no desaparece toda posibilidad de identificación.

## 2. Zona horaria e instantánea

- Transacción `REPEATABLE READ`: ambas agregaciones leen la misma instantánea.
- `SET LOCAL TIME ZONE 'America/Argentina/Buenos_Aires'`: el truncado mensual
  `date_trunc('month', created_at)::date` usa el mismo criterio en la
  población de `mes_alta` y en la consulta sobre `usuario`.

## 3. Consultas

El [prompt literal propio de preparación de D](registro_prompts_opencode_codex_20261015.md#p75926) solicita las dos consultas equivalentes por rol y mes, con la misma población y comparación en ambos sentidos. Se conserva también el [pedido literal de ejecución y evidencia](registro_prompts_opencode_codex_20261015.md#p81604). Ambos se recuperaron del chat de trabajo y se relacionaron con los resultados aportados por la usuaria; no son reconstrucciones posteriores.

Agregación — cantidad de usuarios por rol y mes de alta:

- Sobre anonimizada: `SELECT rol, mes_alta, COUNT(*) … GROUP BY rol, mes_alta`.
- Sobre real: `SELECT rol, (date_trunc('month', created_at)::date) … GROUP BY …`.
- Comparación lado a lado con `FULL OUTER JOIN` por `(rol, mes_alta)`.
- Equivalencia que aborta: `EXCEPT ALL` en ambos sentidos más comparación de
  conteos totales; cualquier diferencia eleva `RAISE EXCEPTION`. El `NOTICE`
  final solo resume, no sustituye la comprobación.
- Ninguna consulta toca `contrasena` ni muestra identificadores reales.

## 4. Ejecución y evidencia real

Comando ejecutado (una pasada, conexión administrativa explícita):

```bash
psql -X -w -U postgres -d foodstore_dev -f TP7_Administracion_y_Seguridad/sql/usuario_anon.sql
```

- Respaldo previo (fuera del repo, sin sobrescribir):
  `C:/Users/hp/Respaldos_BD2/respaldo_foodstore_dev_20261015_091557_antes_tp7_parte_d.dump`
  (custom, 76543 bytes). `pg_dump` exit 0; `pg_restore --list` exit 0 y legible
  (284 entradas TOC según su cabecera, `Format: CUSTOM`). Legible no equivale a restauración probada.
- Conteos previos (solo conteos, sin datos personales): categoria 2, cliente 3,
  producto 3, pedido 5, detalle_pedido 7, usuario 2.

### Consultas ejecutadas (§3a sobre anonimizada, §3b sobre real)

```sql
-- §3a: sobre public.usuario_anon (todas las filas, sin filtro).
SELECT rol, mes_alta, COUNT(*) AS cantidad
FROM public.usuario_anon
GROUP BY rol, mes_alta
ORDER BY rol, mes_alta;

-- §3b: equivalente sobre public.usuario (todas las filas, sin filtro;
-- misma zona horaria de sesión fijada al inicio de la transacción).
SELECT rol, (date_trunc('month', created_at)::date) AS mes_alta, COUNT(*) AS cantidad
FROM public.usuario
GROUP BY rol, (date_trunc('month', created_at)::date)
ORDER BY rol, mes_alta;
```

### Resultados reales lado a lado (§3a = §3b; §3c con ambas cantidades)

```text
   rol    |  mes_alta  | cantidad_anon | cantidad_real
----------+------------+---------------+---------------
 VENDEDOR | 2026-10-01 |             1 |             1
 USUARIO  | 2026-10-01 |             1 |             1
(2 rows)
```

### Equivalencia §4

`NOTICE: equivalencia verificada: 2 filas totales, 2 grupos rol×mes`
(`EXCEPT ALL` en ambos sentidos: 0 filas; totales anon = real = 2).
Secuencia final de la salida: `DO` → `ROLLBACK`, `PSQL_EXIT=0`.

### Comprobación posterior

- `public.usuario_anon`: ausente (`to_regclass` NULL) — nada persistió.
- Conteos post: 2/3/3/5/7 + usuario 2 — coinciden con el previo.

### Alcance de lo validado (sin extrapolar)

- Muestra de 2 usuarios en un único mes (2026-10-01) y dos roles
  (`USUARIO`, `VENDEDOR`). No había usuarios eliminados en la muestra
  (`eliminado=f`: 2), por lo que **no** se probó el caso eliminado, ni
  múltiples meses: el resultado solo valida los datos presentes.

## 5. Qué no debe salir hacia una IA sin protección previa

Los datos personales de usuario —nombre, apellido, mail, celular y fecha exacta de alta— y de cliente —`nombre_completo`, `email`, `telefono` y `direccion`— no deben enviarse a un asistente de IA sin protección previa mediante el proceso de anonimización.
El script D ensaya la transformación de `usuario`; no transforma ni valida una copia de `cliente`, cuyos datos también deben protegerse antes de compartirlos.
Las contraseñas y sus hashes (`contrasena`) deben excluirse siempre: no se anonimizan, se omiten por completo, porque su exposición habilita robo de credenciales y escalada de privilegios.
