import { query, pool } from '../../config/database/db.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export const signUp = async (req, res) => {
  try {
    const { nombre, nombre_usuario, rol, correo, contrasena } = req.body;

    if (!nombre || !nombre_usuario || !rol || !correo || !contrasena) {
      return res.error('Todos los campos son requeridos', 400);
    }

    if (contrasena.length < 10) {
      return res.error('La contraseña debe tener al menos 10 caracteres', 400);
    }

    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      const existingUsersResult = await client.query(
        'SELECT * FROM usuarios WHERE nombre_usuario = $1',
        [nombre_usuario],
      );

      if (existingUsersResult.rows.length > 0) {
        res.error('El usuario ya existe');
      }

      const rolResult = await client.query(
        'SELECT nombre FROM rol WHERE rol_id = $1',
        [rol],
      );

      if (rolResult.rows.length === 0) {
        throw new Error('Rol no válido');
      }

      const rolNombre = rolResult.rows[0].nombre;
      const rolPrefix = rolNombre.charAt(0).toUpperCase();

      const lastIdResult = await client.query(
        'SELECT usuario_id FROM usuarios WHERE usuario_id LIKE $1 ORDER BY usuario_id DESC LIMIT 1',
        [`${rolPrefix}%`],
      );

      let nextNum = 1;
      if (lastIdResult.rows.length > 0) {
        const lastId = lastIdResult.rows[0].usuario_id;
        const lastNum = parseInt(lastId.substring(1), 10);
        nextNum = lastNum + 1;
      }

      const nextId = `${rolPrefix}${nextNum.toString().padStart(3, '0')}`;

      const hashedPassword = await bcrypt.hash(contrasena, 10);

      await client.query(
        'INSERT INTO usuarios (usuario_id, nombre, correo, contrasena, rol, nombre_usuario) VALUES ($1, $2, $3, $4, $5, $6)',
        [nextId, nombre, correo, hashedPassword, rol, nombre_usuario],
      );

      await client.query('COMMIT');
      res.success('Usuario registrado exitosamente', 201);
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    if (error.message === 'El usuario ya existe') {
      return res.error('El nombre de usuario ya está registrado', 400);
    }
    if (error.message === 'Rol no válido') {
      return res.error('El rol seleccionado no es válido', 400);
    }
    res.error(
      'Error al registrar el usuario. Por favor, inténtelo de nuevo más tarde.',
    );
  }
};

export const signIn = async (req, res) => {
  try {
    const { nombre_usuario, contrasena } = req.body;

    if (!nombre_usuario || !contrasena) {
      return res.error('Usuario y contraseña son requeridos', 400);
    }

    const result = await query(
      'SELECT * FROM usuarios WHERE nombre_usuario = $1',
      [nombre_usuario],
    );
    const usuarios = result.rows;

    if (usuarios.length === 0) {
      return res.error('Usuario o contraseña incorrectos', 400);
    }

    const usuario = usuarios[0];

    const isPasswordValid = await bcrypt.compare(
      contrasena,
      usuario.contrasena,
    );
    if (!isPasswordValid) {
      return res.error('Usuario o contraseña incorrectos', 400);
    }

    const token = jwt.sign(
      {
        nombre_usuario: usuario.nombre_usuario,
        usuario_id: usuario.usuario_id,
        rol: usuario.rol,
      },
      process.env.JWT_SECRET,
      {
        expiresIn: process.env.JWT_EXPIRES_IN,
      },
    );

    const refreshToken = jwt.sign(
      { usuario_id: usuario.usuario_id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN },
    );

    await query(
      'INSERT INTO refresh_tokens (token, usuario_id, expires_at) VALUES ($1, $2, $3) ON CONFLICT (usuario_id) DO UPDATE SET token = $1, expires_at = $3',
      [
        refreshToken,
        usuario.usuario_id,
        new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      ],
    );

    res.success({
      token,
      refreshToken,
      usuario_id: usuario.usuario_id,
    });
  } catch (error) {
    res.error('Error al iniciar sesión');
  }
};

export const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.error('Refresh token es requerido', 400);
    }

    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

    const tokensResult = await query(
      'SELECT * FROM refresh_tokens WHERE token = $1 AND usuario_id = $2 AND expires_at > NOW()',
      [refreshToken, decoded.usuario_id],
    );
    const tokens = tokensResult.rows;

    if (tokens.length === 0) {
      return res.error('Refresh token inválido o expirado', 401);
    }

    const usuariosResult = await query(
      'SELECT * FROM usuarios WHERE usuario_id = $1',
      [decoded.usuario_id],
    );
    const usuarios = usuariosResult.rows;

    if (usuarios.length === 0) {
      return res.error('Usuario no encontrado', 404);
    }

    const usuario = usuarios[0];

    const newToken = jwt.sign(
      {
        nombre_usuario: usuario.nombre_usuario,
        usuario_id: usuario.usuario_id,
        rol: usuario.rol,
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN },
    );

    res.success({
      message: 'Token actualizado exitosamente',
      token: newToken,
    });
  } catch (error) {
    res.error('Error al refrescar token', 401);
  }
};
