import { query } from '../../db.js';
import { SQL_GET_ORDERS_BY_MONTH } from './sql.js';

export const getOrdersByMonth = async (req, res) => {
  try {
    const { startDate, endDate, offset, limit } = req.query;

    // if (!startDate || !endDate) {
    //   return res.error('Faltan fechas para filtrar los pedidos', 400);
    // }

    const result = await query(SQL_GET_ORDERS_BY_MONTH, [
      startDate || null,
      endDate || null,
      offset || null,
      limit || null,
    ]);
    res.success(result.rows);
  } catch (error) {
    console.error('Error fetching orders by month:', error);
    res.error('Error al obtener pedidos realizados por mes');
  }
};
