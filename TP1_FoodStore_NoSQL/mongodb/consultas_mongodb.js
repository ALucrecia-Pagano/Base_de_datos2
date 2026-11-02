// FoodStore — Unidad 7 NoSQL. Responsable: Mateo, consignas 4 y 5.
// Lectura únicamente. Ejecutar en foodstore_unidad7, con la colección pedidos
// cargada previamente y sin publicar la URI de conexión.

const loteIds = [1, 2, 3, 4, 5].map((id) => Long(id));
const estadoBuscado = "ENTREGADO";
const productoBuscado = Long(1);
const umbralTotal = Decimal128("3000.00");

// a) Identificador y estado de cada pedido del subconjunto migrado.
printjson(db.pedidos.find(
  { _id: { $in: loteIds } },
  { _id: 1, estado: 1 }
).sort({ _id: 1 }).toArray());

// b) Pedidos con un estado existente en el lote.
printjson(db.pedidos.find(
  { _id: { $in: loteIds }, estado: estadoBuscado },
  { _id: 1, estado: 1 }
).sort({ _id: 1 }).toArray());

// c) Pedidos que contienen el producto, conservando cantidad e importe histórico.
printjson(db.pedidos.aggregate([
  { $match: { _id: { $in: loteIds }, "lineas.id_producto": productoBuscado } },
  {
    $project: {
      _id: 1,
      estado: 1,
      lineas: {
        $filter: {
          input: "$lineas",
          as: "linea",
          cond: { $eq: ["$$linea.id_producto", productoBuscado] }
        }
      }
    }
  },
  { $sort: { _id: 1 } }
]).toArray());

// d) Totales estrictamente superiores a $3000.00.
// El lote suma $14700.00 en 5 pedidos (promedio $2940.00): el umbral selecciona
// los pedidos por encima del promedio y excluye el de $2800.00, cercano a él.
// Decimal128 evita convertir dinero a Number/Double.
printjson(db.pedidos.find(
  { _id: { $in: loteIds }, total: { $gt: umbralTotal } },
  { _id: 1, total: 1, estado: 1 }
).sort({ _id: 1 }).toArray());
