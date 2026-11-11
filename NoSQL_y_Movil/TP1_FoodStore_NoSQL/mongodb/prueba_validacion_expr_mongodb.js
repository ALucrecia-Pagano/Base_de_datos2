// FoodStore - Unidad 7 NoSQL. Consigna 7: contraste de la afirmacion 1 de la IA.
// Responsable: Lucas. Prueba de laboratorio de un validador $expr en MongoDB.
// Se ejecuta SOLO en una base de ensayo propia (prueba_validacion_lucas) con
// documentos sinteticos. No usa foodstore_unidad7 ni datos reales.
// Ejecucion: mongosh --quiet --file prueba_validacion_expr_mongodb.js

const bd = db.getSiblingDB("prueba_validacion_lucas");
const COLECCION = "pedidos_validados";

print("== Entorno ==");
print("Servidor MongoDB: " + bd.version());
print("Base de ensayo: " + bd.getName());

if (bd.getCollectionNames().includes(COLECCION)) {
  print("DETENIDO: la coleccion " + COLECCION + " ya existe en la base de ensayo.");
  print("No se borra ni se reemplaza automaticamente.");
  quit(1);
}

// Regla 1: total = suma de subtotales.
// Regla 2: cada subtotal = cantidad * precio_unitario.
bd.createCollection(COLECCION, {
  validator: {
    $expr: {
      $and: [
        { $eq: ["$total", { $sum: "$lineas.subtotal" }] },
        {
          $allElementsTrue: [
            {
              $map: {
                input: "$lineas",
                as: "l",
                in: {
                  $eq: [
                    "$$l.subtotal",
                    { $multiply: ["$$l.cantidad", "$$l.precio_unitario"] }
                  ]
                }
              }
            }
          ]
        }
      ]
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});
print("Coleccion creada con validador $expr.");

function pedido(id, subtotal1, total) {
  return {
    _id: Long(id),
    estado: "ENTREGADO",
    lineas: [
      { id_producto: Long(1), cantidad: NumberInt(2),
        precio_unitario: Decimal128("1000.00"), subtotal: Decimal128(subtotal1) },
      { id_producto: Long(2), cantidad: NumberInt(1),
        precio_unitario: Decimal128("800.00"), subtotal: Decimal128("800.00") }
    ],
    total: Decimal128(total)
  };
}

function probar(titulo, doc, esperaAceptado) {
  print("");
  print("== " + titulo + " ==");
  let aceptado = false;
  try {
    bd.getCollection(COLECCION).insertOne(doc);
    aceptado = true;
    print("Resultado: ACEPTADO");
  } catch (e) {
    print("Resultado: RECHAZADO (codigo " + e.code + ", " + e.codeName + "): " + e.message);
  }
  print(aceptado === esperaAceptado ? "Coincide con lo esperado: SI" : "Coincide con lo esperado: NO");
}

probar("A. Pedido coherente (subtotales y total correctos): se espera ACEPTADO",
       pedido(9001, "2000.00", "2800.00"), true);
probar("B. Total incorrecto (2900.00; subtotales correctos): se espera RECHAZADO",
       pedido(9002, "2000.00", "2900.00"), false);
probar("C. Subtotal incorrecto (1999.00; total = suma de subtotales 2799.00): se espera RECHAZADO",
       pedido(9003, "1999.00", "2799.00"), false);

print("");
print("== Estado final de la coleccion de ensayo ==");
print("Documentos guardados (se espera 1, el pedido 9001): " +
      bd.getCollection(COLECCION).countDocuments({}));
