// FoodStore Unidad 7. Migración ejecutada manualmente por Amanda y documentada.
// Registro: docs/resultado_migracion.md. El asistente no ejecutó los motores.
// Fuente fija: TP1_FoodStore_NoSQL/evidencias/extraccion_20261028_170446.json (bytes originales).
// SHA-256: 3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243
// Leer TP1_FoodStore_NoSQL/mongodb/README.md. No crea conexiones ni altera la configuración del destino.
// La primera inserción puede crear implícitamente una colección inexistente.
// Antes de insertar: conexión revisada con retryWrites=false.
(() => {
  const BASE = "foodstore_unidad7", COLECCION = "pedidos";
  const FUENTE = "TP1_FoodStore_NoSQL/evidencias/extraccion_20261028_170446.json";
  const SHA = "3973789e22039731d20c1b5227d6907b09fa8065830e88c798264006eeaae243";
  const modo = globalThis.FOODSTORE_MODO || "validar";
  globalThis.FOODSTORE_MODO = "validar"; // No reutilizar una orden de inserción.
  let fase = "validacion_local";
  function exigir(condicion, mensaje) {
    if (!condicion) throw new Error(mensaje);
  }
  // Solo se aceptan los campos del subconjunto; no se copian datos adicionales.
  function campos(objeto, lista) {
    exigir(objeto && Object.keys(objeto).sort().join(",") ===
      lista.split(",").sort().join(","), "Campos inesperados o ausentes");
  }
  function id(texto) {
    exigir(typeof texto === "string" && /^(0|[1-9]\d*)$/.test(texto), "ID no textual");
    exigir(BigInt(texto) <= 9223372036854775807n, "ID fuera de Long");
    return Long(texto);
  }
  // Centavos exactos: exclusivamente BigInt. No Number ni Double para importes.
  function centavos(texto) {
    exigir(typeof texto === "string" && /^(0|[1-9]\d*)\.\d{2}$/.test(texto),
      "Importe no negativo con dos decimales requerido");
    return BigInt(texto.replace(".", ""));
  }
  function decimal(texto) {
    centavos(texto);
    const valor = Decimal128(texto);
    exigir(valor.toString() === texto, "Conversión Decimal128 no exacta");
    return valor;
  }
  function fecha(texto) {
    exigir(typeof texto === "string" &&
      /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}000Z$/.test(texto),
    "Fecha inválida o con precisión submilisegundo: conversión bloqueada");
    const milisegundos = texto.replace(/(\.\d{3})000Z$/, "$1Z");
    const valor = new Date(milisegundos);
    exigir(!Number.isNaN(valor.getTime()) && valor.toISOString() === milisegundos,
      "La fecha no conserva exactamente el instante");
    return valor;
  }
  // Comparar todos los campos y BSON sin depender del orden de claves.
  function ordenar(valor) {
    if (Array.isArray(valor)) return valor.map(ordenar);
    if (valor && typeof valor === "object") {
      return Object.fromEntries(Object.keys(valor).sort().map(k => [k, ordenar(valor[k])]));
    }
    return valor;
  }
  function canonico(valor) {
    return JSON.stringify(ordenar(EJSON.serialize(valor, { relaxed: false })));
  }
  try {
    exigir(["validar", "insertar", "verificar"].includes(modo), "Modo desconocido");
    const fs = require("fs"), path = require("path"), crypto = require("crypto");
    const { Buffer } = require("buffer");
    const raiz = globalThis.FOODSTORE_RAIZ;
    exigir(typeof raiz === "string" && path.isAbsolute(raiz), "Indicar FOODSTORE_RAIZ absoluta");
    const bytes = fs.readFileSync(path.join(raiz, FUENTE));
    exigir(crypto.createHash("sha256").update(bytes).digest("hex") === SHA,
      "SHA-256 distinto: detenerse y revisar la evidencia");
    const texto = bytes.toString("utf8");
    exigir(Buffer.from(texto, "utf8").equals(bytes), "La fuente no es UTF-8 válido");
    const informe = JSON.parse(texto), contexto = informe.contexto;
    exigir(contexto.base === "foodstore_dev" && contexto.esquema === "public" &&
      contexto.solo_lectura === "on" && contexto.aislamiento === "repeatable read",
    "Contexto de extracción incorrecto");
    const controles = informe.controles;
    campos(controles, "extraer,pedidos_ok,detalles_ok,base_correcta,cinco_pedidos,siete_detalles,fechas_compatibles_bson_date");
    exigir(Object.values(controles).every(v => v === true), "Extracción no habilitada");
    const origen = informe.extraccion;
    exigir(Array.isArray(origen) && origen.length === 5 &&
      origen.map(p => p._id).join(",") === "1,2,3,4,5", "Subconjunto incorrecto");
    let numeroLineas = 0;
    const lote = origen.map(p => {
      campos(p, "_id,total,estado,lineas,cliente,fecha_hora,forma_pago");
      campos(p.cliente, "id,alias");
      exigir(p.cliente.alias === "Cliente " + p.cliente.id, "Alias no sintético");
      exigir(typeof p.estado === "string" && typeof p.forma_pago === "string",
        "Estado o forma de pago inválidos");
      exigir(Array.isArray(p.lineas) && p.lineas.length > 0, "Pedido sin líneas");
      const productos = new Set();
      let total = 0n;
      const lineas = p.lineas.map(l => {
        campos(l, "id_producto,nombre_producto,cantidad,precio_unitario,subtotal");
        exigir(!productos.has(l.id_producto), "Producto duplicado en pedido " + p._id);
        productos.add(l.id_producto);
        exigir(Number.isInteger(l.cantidad) && l.cantidad > 0 && l.cantidad <= 2147483647,
          "Cantidad fuera de Int32 positivo");
        exigir(typeof l.nombre_producto === "string", "Nombre descriptivo inválido");
        const subtotal = centavos(l.precio_unitario) * BigInt(l.cantidad);
        exigir(subtotal === centavos(l.subtotal), "Subtotal incoherente");
        total += subtotal;
        numeroLineas++;
        return { id_producto: id(l.id_producto), nombre_producto: l.nombre_producto,
          cantidad: Int32(l.cantidad), precio_unitario: decimal(l.precio_unitario),
          subtotal: decimal(l.subtotal) };
      });
      exigir(total === centavos(p.total), "Total incoherente en pedido " + p._id);
      return { _id: id(p._id), fecha_hora: fecha(p.fecha_hora),
        forma_pago: p.forma_pago, estado: p.estado,
        cliente: { id: id(p.cliente.id), alias: p.cliente.alias },
        lineas, total: decimal(p.total) };
    });
    exigir(numeroLineas === 7, "El lote no tiene siete líneas");
    printjson({ modo, fuente: FUENTE, sha256: SHA, destino: BASE + "." + COLECCION,
      pedidos: lote.length, lineas: numeroLineas, validacionLocal: "satisfactoria" });
    if (modo === "validar") return; // Sin consultas ni escrituras al motor.

    fase = "comprobacion_destino";
    exigir(db.getName() === BASE, "Seleccionar explícitamente la base " + BASE);
    const info = db.getCollectionInfos({ name: COLECCION });
    exigir(info.length === 0 || (info.length === 1 && info[0].type === "collection" &&
      !info[0].options?.timeseries && !info[0].options?.capped),
    "El destino no es una colección ordinaria compatible");
    const coleccion = db.getCollection(COLECCION);
    const filtro = { _id: { $in: lote.map(p => p._id) } };
    if (modo === "insertar") {
      const existentes = coleccion.find(filtro, { _id: 1 }).toArray();
      exigir(existentes.length === 0,
        "IDs existentes: " + existentes.map(p => p._id.toString()).join(", "));
      // Existe una ventana de concurrencia: otro escritor puede ganar después.
      // El índice de _id rechazará el conflicto; puede quedar una carga parcial.
      fase = "insercion";
      const resultado = coleccion.insertMany(lote, { ordered: true, writeConcern: { w: 1 } });
      exigir(resultado.acknowledged === true, "Inserción sin confirmación");
      printjson({ insercionConfirmada: true, ids: resultado.insertedIds });
    }

    fase = "verificacion_posterior";
    const leidos = coleccion.aggregate([
      { $match: filtro }, { $sort: { _id: 1 } },
      { $project: { _id: 0, documento: "$$ROOT", tipos: {
        id: { $type: "$_id" }, cliente: { $type: "$cliente.id" },
        fecha: { $type: "$fecha_hora" }, total: { $type: "$total" },
        lineas: { $map: { input: "$lineas", as: "l", in: {
          producto: { $type: "$$l.id_producto" }, cantidad: { $type: "$$l.cantidad" },
          precio: { $type: "$$l.precio_unitario" }, subtotal: { $type: "$$l.subtotal" }
        } } }
      } } }
    ]).toArray();
    exigir(leidos.length === 5, "No se recuperaron los cinco documentos del lote");
    let lineasLeidas = 0;
    leidos.forEach((r, i) => {
      const t = r.tipos;
      exigir(t.id === "long" && t.cliente === "long" && t.fecha === "date" &&
        t.total === "decimal", "Tipos BSON incorrectos en cabecera");
      exigir(t.lineas.every(l => l.producto === "long" && l.cantidad === "int" &&
        l.precio === "decimal" && l.subtotal === "decimal"), "Tipos BSON incorrectos en líneas");
      exigir(canonico(r.documento) === canonico(lote[i]),
        "Diferencia campo por campo en pedido " + origen[i]._id);
      lineasLeidas += r.documento.lineas.length;
    });
    exigir(lineasLeidas === 7, "No se recuperaron siete líneas");
    printjson({ verificacion: "satisfactoria", pedidos: 5, lineas: lineasLeidas,
      tiposBSON: "correctos", correspondencia: "todos los campos del lote fuente",
      fuente: FUENTE, sha256: SHA });
  } catch (error) {
    printjson({ estado: "DETENIDO", fase, fuente: FUENTE, sha256: SHA,
      fechaUTC: new Date().toISOString(), codigo: error.code ?? null,
      mensaje: error.message,
      accion: "Sin reintento ni recuperación automática. Conservar salida y revisar." });
    throw error;
  }
})();
