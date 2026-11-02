# Preparación del informe

## Requisitos

- PDF de hasta cinco páginas, sin contar código adjunto.
- Conclusión de hasta 200 palabras, con revisión del equipo completo.
- Adjuntar [consultas_mongodb.js](../mongodb/consultas_mongodb.js) y [consultas_postgresql.sql](../postgresql/consultas_postgresql.sql), o equivalentes.
- Incluir modelo documental, migración y verificación, consultas, comparación b) y c) por cantidades e IDs, contraste de dos afirmaciones de IA y fundamento de elección tecnológica.
- Usar evidencias anonimizadas y distinguir propuestas de resultados comprobados según [AGENTS.md](../../AGENTS.md).

## Esquema orientativo del PDF

1. Datos académicos, objetivo, alcance y modelo documental.
2. Migración, conservación de datos y reglas de integridad.
3. Consultas y comparación de resultados entre motores.
4. Consulta a IA, contraste de dos afirmaciones y fuentes.
5. Fundamentación tecnológica y conclusión de hasta 200 palabras.

## Borrador del informe final

El borrador está en esta carpeta: [informe_final.html](informe_final.html) es la fuente editable y [BDII_Unidad7_FoodStore_NoSQL_Com4.pdf](BDII_Unidad7_FoodStore_NoSQL_Com4.pdf) su exportación. Se armó a partir de los aportes de [Amanda](aporte_amanda.md), [Mateo](aporte_mateo.md) y [Lucas](aporte_lucas.md); la conclusión reproduce textualmente la de Lucas. Las capturas se recortan solo con CSS; los originales de `evidencias/` no se modifican.

Para regenerar el PDF desde Git Bash, con rutas absolutas:

```bash
"/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="RUTA/informe/BDII_Unidad7_FoodStore_NoSQL_Com4.pdf" "file:///RUTA/informe/informe_final.html"
```

**Pendiente:** OK de Mateo y Lucas a la conclusión y al PDF, captura de la respuesta original de Gemini (solicitada a Lucas) y confirmación docente del cliente con ID más alias. Al aprobarse, quitar del encabezado la línea de versión borrador y volver a exportar. Consultar el [plan de trabajo](../docs/plan_trabajo.md).
