import { query, pool } from '../db.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export const signUp = async (req, res) => {
  try {
    const { nombre_usuario, contrasena, nombre, correo, rol } = req.body;

    if (!nombre_usuario || !contrasena || !nombre || !correo || !rol) {
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

      const hashedPassword = await bcrypt.hash(contrasena, 10);

      const nextIdResult = await client.query(
        "SELECT nextval('usuarios_id_usuario_seq')",
      );
      const nextId = nextIdResult.rows[0].nextval;

      await client.query(
        'INSERT INTO usuarios (id_usuario, nombre, correo, contrasena, rol, nombre_usuario) VALUES ($1, $2, $3, $4, $5, $6)',
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
        id_usuario: usuario.id_usuario,
        rol: usuario.rol,
      },
      process.env.JWT_SECRET,
      {
        expiresIn: process.env.JWT_EXPIRES_IN,
      },
    );

    const refreshToken = jwt.sign(
      { id_usuario: usuario.id_usuario },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN },
    );

    await query(
      'INSERT INTO refresh_tokens (token, user_id, expires_at) VALUES ($1, $2, $3) ON CONFLICT (user_id) DO UPDATE SET token = $1, expires_at = $3',
      [
        refreshToken,
        usuario.id_usuario,
        new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      ],
    );

    res.success({
      token,
      refreshToken,
      id_usuario: usuario.id_usuario,
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
      'SELECT * FROM refresh_tokens WHERE token = $1 AND user_id = $2 AND expires_at > NOW()',
      [refreshToken, decoded.id_usuario],
    );
    const tokens = tokensResult.rows;

    if (tokens.length === 0) {
      return res.error('Refresh token inválido o expirado', 401);
    }

    const usuariosResult = await query(
      'SELECT * FROM usuarios WHERE id_usuario = $1',
      [decoded.id_usuario],
    );
    const usuarios = usuariosResult.rows;

    if (usuarios.length === 0) {
      return res.error('Usuario no encontrado', 404);
    }

    const usuario = usuarios[0];

    const newToken = jwt.sign(
      {
        nombre_usuario: usuario.nombre_usuario,
        id_usuario: usuario.id_usuario,
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
