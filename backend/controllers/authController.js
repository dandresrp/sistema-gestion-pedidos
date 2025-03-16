import { query, pool } from '../db.js';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

export const signUp = async (req, res) => {
  try {
    const { nombre_usuario, contrasena, nombre, correo, rol } = req.body;

    if (!nombre_usuario || !contrasena || !nombre || !correo || !rol) {
      return res
        .status(400)
        .json({ message: 'Todos los campos son requeridos' });
    }

    if (contrasena.length < 10) {
      return res.status(400).json({
        message: 'La contraseña debe tener al menos 10 caracteres',
      });
    }

    // Use a client for transaction management
    const client = await pool.connect();

    try {
      await client.query('BEGIN');

      // Check if user exists
      const existingUsersResult = await client.query(
        'SELECT * FROM usuarios WHERE nombre_usuario = $1',
        [nombre_usuario],
      );

      if (existingUsersResult.rows.length > 0) {
        throw new Error('El usuario ya existe');
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
      res.status(201).json({ message: 'Usuario registrado exitosamente' });
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  } catch (error) {
    console.error('Error en el registro:', error);
    if (error.message === 'El usuario ya existe') {
      return res.status(400).json({ message: 'El usuario ya existe' });
    }
    res.status(500).json({ message: 'Error al registrar usuario' });
  }
};

export const signIn = async (req, res) => {
  try {
    const { nombre_usuario, contrasena } = req.body;

    if (!nombre_usuario || !contrasena) {
      return res
        .status(400)
        .json({ message: 'Usuario y contraseña son requeridos' });
    }

    const result = await query(
      'SELECT * FROM usuarios WHERE nombre_usuario = $1',
      [nombre_usuario],
    );
    const usuarios = result.rows;

    if (usuarios.length === 0) {
      return res
        .status(400)
        .json({ message: 'Usuario o contraseña incorrectos' });
    }

    const usuario = usuarios[0];

    const isPasswordValid = await bcrypt.compare(
      contrasena,
      usuario.contrasena,
    );
    if (!isPasswordValid) {
      return res
        .status(400)
        .json({ message: 'Usuario o contraseña incorrectos' });
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

    res.json({
      message: 'Inicio de sesión exitoso',
      token,
      refreshToken,
      id_usuario: usuario.id_usuario,
    });
  } catch (error) {
    console.error('Error en el inicio de sesión:', error);
    res.status(500).json({ message: 'Error al iniciar sesión' });
  }
};

export const refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ message: 'Refresh token es requerido' });
    }

    const decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);

    const tokensResult = await query(
      'SELECT * FROM refresh_tokens WHERE token = $1 AND user_id = $2 AND expires_at > NOW()',
      [refreshToken, decoded.id_usuario],
    );
    const tokens = tokensResult.rows;

    if (tokens.length === 0) {
      return res
        .status(401)
        .json({ message: 'Refresh token inválido o expirado' });
    }

    const usuariosResult = await query(
      'SELECT * FROM usuarios WHERE id_usuario = $1',
      [decoded.id_usuario],
    );
    const usuarios = usuariosResult.rows;

    if (usuarios.length === 0) {
      return res.status(401).json({ message: 'Usuario no encontrado' });
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

    res.json({
      message: 'Token actualizado exitosamente',
      token: newToken,
    });
  } catch (error) {
    console.error('Error al refrescar token:', error);
    res.status(401).json({ message: 'Error al refrescar token' });
  }
};
