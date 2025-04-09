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
    res.success(result.rows);
  } catch (error) {
    console.error('Error fetching orders:', error);
    res.error('Internal server error', 500);
  }
};

export const getOrderById = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await query('SELECT * FROM pedidos WHERE id = $1', [id]);
    if (result.rows.length === 0) {
      return res.error('Order not found', 404);
    }
    res.success(result.rows[0]);
  } catch (error) {
    console.error('Error fetching order:', error);
    res.error('Internal server error', 500);
  }
};
