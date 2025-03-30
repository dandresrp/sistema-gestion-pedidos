import { query } from '../../config/database/db.js';
import {
  SQL_GET_ALL_USERS,
  SQL_GET_USER_BY_ID,
  SQL_UPDATE_USER,
  SQL_DELETE_USER,
} from './sql.js';

export const getAllUsers = async (req, res) => {
  try {
    const result = await query(SQL_GET_ALL_USERS);
    res.success(result.rows);
  } catch (error) {
    console.error('Error al obtener usuarios:', error);
    res.error('Error al obtener usuarios');
  }
};

export const getUserById = async (req, res) => {
  try {
    const { id_usuario } = req.params;
    const result = await query(SQL_GET_USER_BY_ID, [id_usuario]);

    if (result.rows.length === 0) {
      return res.error('Usuario no encontrado', 404);
    }

    res.success(result.rows[0]);
  } catch (error) {
    console.error('Error al obtener usuario:', error);
    res.error('Error al obtener datos del usuario');
  }
};

export const updateUser = async (req, res) => {
  try {
    const { id_usuario } = req.params;
    const { nombre_usuario } = req.body;

    if (!nombre_usuario || nombre_usuario.trim() === '') {
      return res.error('El nombre de usuario es requerido', 400);
    }

    const existingUserResult = await query(SQL_GET_USER_BY_ID, [id_usuario]);

    if (existingUserResult.rows.length === 0) {
      return res.error('Usuario no encontrado', 404);
    }

    if (req.usuario.id_usuario != id_usuario) {
      return res.error('No tienes permiso para modificar este usuario', 403);
    }

    await query(SQL_UPDATE_USER, [nombre_usuario, id_usuario]);

    res.success(
      { id_usuario, nombre_usuario },
      'Usuario actualizado correctamente',
    );
  } catch (error) {
    console.error('Error al actualizar usuario:', error);
    res.error('Error al actualizar usuario');
  }
};

export const deleteUser = async (req, res) => {
  try {
    const { id_usuario } = req.params;

    await query(SQL_DELETE_USER, [id_usuario]);

    res.success(null, 'Usuario eliminado correctamente');
  } catch (error) {
    console.error('Error al eliminar usuario:', error);
    res.error('Error al eliminar usuario');
  }
};
