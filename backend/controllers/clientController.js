import { query } from '../db.js';

export const getAllClients = async (req, res) => {
  try {
    const result = await query(
      'SELECT id_cliente, nombre, telefono, correo, direccion FROM clientes',
    );
    res.send(result.rows);
  } catch (error) {
    console.error('Error al obtener clientes: ', error);
    res.status(500).json({ message: 'Error al obtener clientes' });
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
      return res.status(404).json({ message: 'Cliente no encontrado' });
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error al obtener este Cliente', error);
    res.status(500).json({ message: 'Error al obtener datos de este cliente' });
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
      return res
        .status(400)
        .json({ message: 'No se enviaron datos para actualizar' });
    }

    values.push(id_cliente);

    const result = await query(
      `UPDATE clientes SET ${updates.join(', ')} WHERE id_cliente = $${paramCounter} RETURNING *`,
      values,
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Cliente no encontrado' });
    }

    res.json({
      message: 'Cliente actualizado correctamente',
      cliente: result.rows[0],
    });
  } catch (error) {
    console.error('Error al actualizar el cliente', error);
    res.status(500).json({ message: 'Error al actualizar el cliente' });
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
      return res.status(404).json({ message: 'Cliente no encontrado' });
    }

    res.status(200).json({
      message: 'Cliente eliminado correctamente:',
      cliente: result.rows[0],
    });
  } catch (error) {
    console.error('Error al eliminar cliente', error);
    res.status(500).json({ message: 'Error al eliminar cliente' });
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
      return res
        .status(400)
        .json({ message: 'Ya existe un cliente con ese teléfono' });
    }

    const result = await query(
      'INSERT INTO clientes (nombre, telefono, correo, direccion) VALUES ($1, $2, $3, $4) RETURNING *',
      [nombre, telefono, correo, direccion],
    );

    res
      .status(201)
      .json({
        message: 'Cliente agregado correctamente',
        cliente: result.rows[0],
      });
  } catch (error) {
    console.error('Error al agregar el cliente', error);
    res.status(500).json({ message: 'Error al agregar el cliente' });
  }
};
