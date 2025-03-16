import { query } from '../db.js';

export const getAllClients = async (req, res) => {
  try {
    const result = await query(
      'SELECT id_cliente, nombre, telefono, correo, direccion FROM clientes',
    );
    res.success(result.rows);
  } catch (error) {
    console.error('Error al obtener clientes: ', error);
    res.error('Error al obtener clientes');
  }
};

export const getClientById = async (req, res) => {
  const { id_cliente } = req.params;
  try {
    const result = await query(
      'SELECT id_cliente, nombre, telefono, correo, direccion FROM clientes WHERE id_cliente = $1',
      [id_cliente],
    );

    if (result.rows.length === 0) {
      return res.error('Cliente no encontrado', 404);
    }

    res.success(result.rows[0]);
  } catch (error) {
    console.error('Error al obtener este Cliente', error);
    res.error('Error al obtener datos de este cliente');
  }
};

export const updateClient = async (req, res) => {
  const { id_cliente } = req.params;
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

    values.push(id_cliente);

    const result = await query(
      `UPDATE clientes SET ${updates.join(', ')} WHERE id_cliente = $${paramCounter} RETURNING *`,
      values,
    );

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
  const { id_cliente } = req.params;

  try {
    const result = await query(
      'DELETE FROM clientes WHERE id_cliente = $1 RETURNING *',
      [id_cliente],
    );

    if (result.rows.length === 0) {
      return res.error('Cliente no encontrado', 404);
    }

    res.success(result.rows[0], 'Cliente eliminado correctamente');
  } catch (error) {
    console.error('Error al eliminar cliente:', error);
    res.error('Error al eliminar cliente:');
  }
};

export const addClient = async (req, res) => {
  const { nombre, telefono, correo, direccion } = req.body;

  try {
    const existingPhone = await query(
      'SELECT * FROM clientes WHERE telefono = $1',
      [telefono],
    );

    if (existingPhone.rows.length > 0) {
      return res.error('El teléfono ya está registrado', 400);
    }

    const result = await query(
      'INSERT INTO clientes (nombre, telefono, correo, direccion) VALUES ($1, $2, $3, $4) RETURNING *',
      [nombre, telefono, correo, direccion],
    );

    res.success(result.rows[0], 'Cliente agregado correctamente', 201);
  } catch (error) {
    console.log('Error al agregar cliente:', error);
    res.error('Error al agregar cliente');
  }
};
