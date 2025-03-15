import sql from '../db.js'

export const getAllClients = async (req,res) => {
    try{
        const clients = await sql`SELECT id_cliente, nombre, telefono, correo, direccion FROM clientes;`
        res.send(clients)
    } catch (error){
        console.error("Error al obtener clientes: ", error)
        res.status(500).json({ message: "Error al obtener clientes" })
    }
}

export const getClientById = async (req, res) => {
    const { id_cliente } = req.params
    try {
        const client = await sql`SELECT id_cliente, nombre, telefono, correo, direccion FROM cliente WHERE id_cliente =${id_cliente} `
        
        if( client.length === 0 ){
            return res.status(404).json({message : "Cliente no encontrado" })
        }
        res.json(client[0])
    } catch (error) {
        console.error("Error al obtener este Cliente", error )
        res.status(500).json({ message: "Error al obtener datos de este cliente"})
    }
}

