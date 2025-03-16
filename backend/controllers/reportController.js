import { query } from '../db.js';

export const getOrdersByMonth = async (req, res) => {
  try {
    const { month } = req.params;
    const SQL_GET_ORDERS_BY_MONTH = `
      SELECT p.fecha_creacion AS fecha,
         c.nombre         AS cliente,
         pr.nombre        AS producto,
         pr.precio        AS monto,
         p.estado         AS estado
      FROM pedidos AS p
      JOIN clientes AS c
      ON p.id_cliente = c.id_cliente
      JOIN detallespedido AS dp
      ON p.id_pedido = dp.id_pedido
      JOIN productos AS pr
      ON dp.id_producto = pr.id_producto
      WHERE EXTRACT(MONTH FROM p.fecha_creacion) = $1
    `;
    const result = await query(SQL_GET_ORDERS_BY_MONTH, [month]);
    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching orders by month:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
