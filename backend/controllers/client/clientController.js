import { query, pool } from '../../config/database/db.js';
import {
  buildUpdateClientSQL,
  SQL_ADD_CLIENT,
  SQL_DELETE_CLIENT,
  SQL_GET_ALL_CLIENTS,
  SQL_GET_CLIENT_BY_ID,
  SQL_GET_CLIENT_BY_PHONE,
} from './sql.js';

export const getAllClients = async (req, res) => {
  try {
    const result = await query(SQL_GET_ALL_CLIENTS);
    res.success(result.rows);
  } catch (error) {
    console.error('Error al obtener clientes: ', error);
    res.error('Error al obtener clientes');
  }
};

export const getClientById = async (req, res) => {
  const { cliente_id } = req.params;
  try {
    const result = await query(SQL_GET_CLIENT_BY_ID, [cliente_id]);

    if (result.rows.length === 0) {
      return res.error('Cliente no encontrado', 404);
    }

    res.success(result.rows[0]);
  } catch (error) {
    console.error('Error al obtener este Cliente', error);
    res.error('Error al obtener datos de este cliente');
  }
};

export const addClient = async (req, res) => {
  const { nombre, telefono, correo, direccion } = req.body;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const existingClient = await client.query(SQL_GET_CLIENT_BY_PHONE, [
      telefono,
    ]);

    if (existingClient.rows.length > 0) {
      return res.error('El cliente ya está registrado', 400);
    }

    const lastIdResult = await client.query(
      'SELECT cliente_id FROM clientes WHERE cliente_id LIKE $1 ORDER BY cliente_id DESC LIMIT 1',
      ['CL%'],
    );

    let nextNum = 1;
    if (lastIdResult.rows.length > 0) {
      const lastId = lastIdResult.rows[0].cliente_id;
      const lastNum = parseInt(lastId.substring(2), 10);
      nextNum = lastNum + 1;
    }

    const clienteId = `CL${nextNum.toString().padStart(3, '0')}`;

    const insertQuery =
      'INSERT INTO clientes (cliente_id, nombre, telefono, correo, direccion) VALUES ($1, $2, $3, $4, $5) RETURNING *';
    const result = await client.query(insertQuery, [
      clienteId,
      nombre,
      telefono,
      correo,
      direccion,
    ]);

    await client.query('COMMIT');
    res.success(result.rows[0], 'Cliente agregado correctamente', 201);
  } catch (error) {
    await client.query('ROLLBACK');
    console.log('Error al agregar cliente:', error);
    res.error('Error al agregar cliente');
  } finally {
    client.release();
  }
};

export const updateClient = async (req, res) => {
  const { cliente_id } = req.params;
  const { nombre, telefono, correo, direccion } = req.body;

  try {
    const updates = [];
    const values = [];
    let paramCounter = 1;

    if (nombre !== undefined) {
      updates.push(`nombre = $${paramCounter}`);
      values.push(nombre);
      paramCounter++;
    }
    if (telefono !== undefined) {
      updates.push(`telefono = $${paramCounter}`);
      values.push(telefono);
      paramCounter++;
    }
    if (correo !== undefined) {
      updates.push(`correo = $${paramCounter}`);
      values.push(correo);
      paramCounter++;
    }
    if (direccion !== undefined) {
      updates.push(`direccion = $${paramCounter}`);
      values.push(direccion);
      paramCounter++;
    }

    if (updates.length === 0) {
      return res.error('No se proporcionaron datos para actualizar', 400);
    }

    values.push(cliente_id);

    const SQL_UPDATE_CLIENT = buildUpdateClientSQL(updates, paramCounter);
    const result = await query(SQL_UPDATE_CLIENT, values);

    if (result.rows.length === 0) {
      return res.error('Cliente no encontrado', 404);
    }

    res.success(result.rows[0], 'Cliente actualizado correctamente');
  } catch (error) {
    console.error('Error al actualizar cliente:', error);
    res.error('Error al actualizar cliente:');
  }
};

export const deleteClient = async (req, res) => {
  const { cliente_id } = req.params;

  try {
    const result = await query(SQL_DELETE_CLIENT, [cliente_id]);

    if (result.rows.length === 0) {
      return res.error('Cliente no encontrado', 404);
    }

    res.success(result.rows[0], 'Cliente eliminado correctamente');
  } catch (error) {
    console.error('Error al eliminar cliente:', error);
    res.error('Error al eliminar cliente:');
  }
};
