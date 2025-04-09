import { query } from '../../config/database/db.js';
import { SQL_GET_ALL_SHIPPING_METHODS } from './sql.js';

export const getAllShippingMethods = async (req, res) => {
  try {
    const result = await query(SQL_GET_ALL_SHIPPING_METHODS);
    res.success(result.rows);
  } catch (error) {
    console.error('Error al obtener métodos de envío:', error);
    res.error('Error al obtener métodos de envío');
  }
};
