import sql from '../db.js';
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

    await sql.begin(async transaction => {
      const existingUsers = await transaction`
                SELECT * FROM usuarios WHERE nombre_usuario = ${nombre_usuario}
            `;

      if (existingUsers.length > 0) {
        throw new Error('El usuario ya existe');
      }

      const hashedPassword = await bcrypt.hash(contrasena, 10);

      const nextIdResult =
        await transaction`SELECT nextval('usuarios_id_usuario_seq')`;
      const nextId = nextIdResult[0].nextval;

      await transaction`
                INSERT INTO usuarios (id_usuario, nombre, correo, contrasena, rol, nombre_usuario)
                VALUES (${nextId}, ${nombre}, ${correo}, ${hashedPassword}, ${rol}, ${nombre_usuario})
            `;
    });

    res.status(201).json({ message: 'Usuario registrado exitosamente' });
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

    const usuarios = await sql`
      SELECT * FROM usuarios WHERE nombre_usuario = ${nombre_usuario}
    `;

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

    await sql`
            INSERT INTO refresh_tokens (token, user_id, expires_at)
            VALUES (${refreshToken}, ${usuario.id_usuario}, ${new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)})
            ON CONFLICT (user_id) DO UPDATE
            SET token = ${refreshToken}, expires_at = ${new Date(Date.now() + 7 * 24 * 60 * 60 * 1000)}
        `;

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

    const tokens = await sql`
          SELECT * FROM refresh_tokens
          WHERE token = ${refreshToken}
          AND user_id = ${decoded.id_usuario}
          AND expires_at > NOW()
      `;

    if (tokens.length === 0) {
      return res
        .status(401)
        .json({ message: 'Refresh token inválido o expirado' });
    }

    const usuarios = await sql`
          SELECT * FROM usuarios WHERE id_usuario = ${decoded.id_usuario}
      `;

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
