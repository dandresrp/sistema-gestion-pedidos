export const SQL_GET_ALL_USERS = `
  SELECT u.usuario_id,
        u.nombre_usuario,
        u.nombre,
        u.correo,
        r.nombre AS rol
  FROM usuarios u
          JOIN public.rol r ON u.rol = r.rol_id
`;
export const SQL_GET_USER_BY_ID = `
  SELECT usuario_id, nombre_usuario FROM usuarios WHERE usuario_id = $1
`;

export const SQL_UPDATE_USER = `
  UPDATE usuarios SET nombre_usuario = $1 WHERE usuario_id = $2
`;

export const SQL_DELETE_USER = `
  DELETE FROM usuarios WHERE usuario_id = $1
`;
