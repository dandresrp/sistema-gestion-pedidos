import { query } from '../db.js';

export const getAllUsers = async (req, res) => {
  try {
    const result = await query(
      'SELECT id_usuario, nombre_usuario, nombre, correo, rol FROM usuarios',
    );
    res.send(result.rows);
  } catch (error) {
    console.error('Error al obtener usuarios:', error);
    res.status(500).json({ message: 'Error al obtener usuarios' });
  }
};

export const getUserById = async (req, res) => {
  try {
    const { id_usuario } = req.params;
    const result = await query(
      'SELECT id_usuario, nombre_usuario FROM usuarios WHERE id_usuario = $1',
      [id_usuario],
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error al obtener usuario:', error);
    res.status(500).json({ message: 'Error al obtener datos del usuario' });
  }
};

export const updateUser = async (req, res) => {
  try {
    const { id_usuario } = req.params;
    const { nombre_usuario } = req.body;

    if (!nombre_usuario || nombre_usuario.trim() === '') {
      return res
        .status(400)
        .json({ message: 'El nombre de usuario es requerid_usuarioo' });
    }

    const existingUserResult = await query(
      'SELECT * FROM usuarios WHERE id_usuario = $1',
      [id_usuario],
    );

    if (existingUserResult.rows.length === 0) {
      return res.status(404).json({ message: 'Usuario no encontrado' });
    }

    if (req.usuario.id_usuario != id_usuario) {
      return res
        .status(403)
        .json({ message: 'No tienes permiso para modificar este usuario' });
    }

    await query(
      'UPDATE usuarios SET nombre_usuario = $1 WHERE id_usuario = $2',
      [nombre_usuario, id_usuario],
    );

    res.json({ message: 'Usuario actualizado correctamente' });
  } catch (error) {
    console.error('Error al actualizar usuario:', error);
    res.status(500).json({ message: 'Error al actualizar usuario' });
  }
};

export const deleteUser = async (req, res) => {
  try {
    const { id_usuario } = req.params;

    if (req.usuario.id_usuario != id_usuario) {
      return res
        .status(403)
        .json({ message: 'No tienes permiso para eliminar este usuario' });
    }

    await query('DELETE FROM usuarios WHERE id_usuario = $1', [id_usuario]);

    res.json({ message: 'Usuario eliminado correctamente' });
  } catch (error) {
    console.error('Error al eliminar usuario:', error);
    res.status(500).json({ message: 'Error al eliminar usuario' });
  }
};
