import { query } from '../../config/database/db.js';
import { SQL_GET_ALL_VALUES } from './sql.js';

export const getAllValues = async (req, res) => {
  try {
    const result = await query(SQL_GET_ALL_VALUES);
    res.success(result.rows);
  } catch (error) {
    console.error('Error al obtener valores:', error);
    res.error('Error al obtener valores');
  }
};
