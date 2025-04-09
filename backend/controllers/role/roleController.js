import { query, pool } from '../../config/database/db.js';
import { SQL_GET_ALL_ROLES } from './sql.js';

export const getAllRoles = async (req, res) => {
  try {
    const result = await query(SQL_GET_ALL_ROLES);
    res.success(result.rows);
  } catch (error) {
    console.error('Error al obtener roles: ', error);
    res.error('Error al obtener roles');
  }
};
