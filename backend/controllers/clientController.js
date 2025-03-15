import sql from '../db.js'

export const getAllClients = async (req,res) => {
    try{
        const clients = await sql`
        SELECT id_cliente, nombre, telefono, correo, direccion 
        FROM clientes;`

        res.send(clients)
    } catch (error){
        console.error("Error al obtener clientes: ", error)
        res.status(500).json({ message: "Error al obtener clientes" })
    }
}

export const getClientById = async (req, res) => {
    const { id_cliente } = req.params
    try {
        const client = await sql`
        SELECT id_cliente, nombre, telefono, correo, direccion 
        FROM clientes 
        WHERE id_cliente =${id_cliente}`
        
        if( client.length === 0 ){
            return res.status(404).json({message : "Cliente no encontrado" })
        }

        res.json(client[0])
    } catch (error) {
        console.error("Error al obtener este Cliente", error )
        res.status(500).json({ message: "Error al obtener datos de este cliente"})
    }
}

export const updateClient = async (req, res) => {
    const { id_cliente } = req.params;
    const { nombre, telefono, correo, direccion } = req.body;

    try {
        const fieldsToUpdate = {};
        if (nombre !== undefined) fieldsToUpdate.nombre = nombre;
        if (telefono !== undefined) fieldsToUpdate.telefono = telefono;
        if (correo !== undefined) fieldsToUpdate.correo = correo;
        if (direccion !== undefined) fieldsToUpdate.direccion = direccion;

        if (Object.keys(fieldsToUpdate).length === 0) {
            return res.status(400).json({ message: "No se enviaron datos para actualizar" });
        }

        const result = await sql`
            UPDATE clientes 
            SET ${sql(fieldsToUpdate)}
            WHERE id_cliente = ${id_cliente}
            RETURNING *;
        `;

        if (result.length === 0) {
            return res.status(404).json({ message: "Cliente no encontrado" });
        }

        res.json({ message: "Cliente actualizado correctamente", cliente: result[0] });

    } catch (error) {
        console.error("Error al actualizar el cliente", error);
        res.status(500).json({ message: "Error al actualizar el cliente" });
    }
};

export const deleteClient = async (req,res) => {
    const { id_cliente } = req.params

    try {
        const result = await sql`
            DELETE FROM clientes
            WHERE id_cliente = ${id_cliente}
            RETURNING *
        `;

        if(result.length === 0){
            return res.status(404).json({ message: "Cliente no encontrado"})
        }

        res.status(200).json({
            message: "Cliente elinminado correctamente:",
            cliente: result[0]
        })
        
    } catch (error) {
        console.error("Error al eliminar cliente",error)
        res.status(500).json({ message: "Error al eliminar cliente"})
        
    }
}

export const addClient = async (req, res) => {
    const { nombre, telefono, correo, direccion } = req.body;

    try {
        const existingPhone = await sql`
            SELECT * FROM clientes WHERE telefono = ${telefono}
        `;

        if (existingPhone.length > 0) {
            return res.status(400).json({ message: "Ya existe un cliente con ese teléfono" });
        }

        const result = await sql`
            INSERT INTO clientes (nombre, telefono, correo, direccion)
            VALUES (${nombre}, ${telefono}, ${correo}, ${direccion})
            RETURNING *;
        `;

        res.status(201).json({ message: "Cliente agregado correctamente", cliente: result[0] });

    } catch (error) {
        console.error("Error al agregar el cliente", error);
        res.status(500).json({ message: "Error al agregar el cliente" });
    }
};
