import { query } from '../../config/database/db.js';
import { SQL_GET_ALL_STAGES } from './sql.js';

export const getAllStages = async (req, res) => {
  try {
    const result = await query(SQL_GET_ALL_STAGES);
    res.success(result.rows);
  } catch (error) {
    console.error('Error al obtener estados:', error);
    res.error('Error al obtener estados');
  }
};
