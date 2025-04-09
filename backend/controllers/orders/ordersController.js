import { query } from '../../config/database/db.js';
import { SQL_GET_ALL_ORDERS } from './sql.js';

export const getAllOrders = async (req, res) => {
  try {
    const { nombre_cliente, pedido_id, estado } = req.query;
    const result = await query(SQL_GET_ALL_ORDERS, [
      estado,
      nombre_cliente,
      pedido_id,
    ]);
    res.status(200).json(result.rows);
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
