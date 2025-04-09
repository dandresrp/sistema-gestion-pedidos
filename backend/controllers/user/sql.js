export const SQL_GET_ALL_USERS = `
SELECT usuario_id, nombre_usuario, nombre, correo, rol FROM usuarios
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
