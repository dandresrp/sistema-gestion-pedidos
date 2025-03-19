export const SQL_GET_ALL_USERS = `
SELECT id_usuario, nombre_usuario, nombre, correo, rol FROM usuarios
`;
export const SQL_GET_USER_BY_ID = `
SELECT id_usuario, nombre_usuario FROM usuarios WHERE id_usuario = $1
`;

export const SQL_UPDATE_USER = `
UPDATE usuarios SET nombre_usuario = $1 WHERE id_usuario = $2
`;

export const SQL_DELETE_USER = `
DELETE FROM usuarios WHERE id_usuario = $1
`;
