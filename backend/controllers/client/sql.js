export const SQL_GET_ALL_CLIENTS =
  'SELECT id_cliente, nombre, telefono, correo, direccion FROM clientes';

export const SQL_GET_CLIENT_BY_ID =
  'SELECT id_cliente, nombre, telefono, correo, direccion FROM clientes WHERE id_cliente = $1';

export const SQL_GET_CLIENT_BY_PHONE =
  'SELECT id_cliente, nombre, telefono, correo, direccion FROM clientes WHERE telefono = $1';

export const SQL_ADD_CLIENT =
  'INSERT INTO clientes (nombre, telefono, correo, direccion) VALUES ($1, $2, $3, $4) RETURNING *';

export const buildUpdateClientSQL = (updates, paramCounter) => {
  return `UPDATE clientes SET ${updates.join(', ')} WHERE id_cliente = $${paramCounter} RETURNING *`;
};

export const SQL_DELETE_CLIENT =
  'DELETE FROM clientes WHERE id_cliente = $1 RETURNING *';
