import sql from "../db.js";

export const getAllUsers = async (req, res) => {
  try {
    const users = await sql`SELECT id, username FROM users;`;
    res.send(users);
  } catch (error) {
    console.error("Error al obtener usuarios:", error);
    res.status(500).json({ message: "Error al obtener usuarios" });
  }
}

export const getUserById = async (req, res) => {
    try {
        const { id } = req.params;
        const users = await sql`SELECT id, username FROM users WHERE id = ${id}`;

        if (users.length === 0) {
            return res.status(404).json({ message: "Usuario no encontrado" });
        }

        res.json(users[0]);
    } catch (error) {
        console.error("Error al obtener usuario:", error);
        res.status(500).json({ message: "Error al obtener datos del usuario" });
    }
}

export const updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const { username } = req.body;

        if (!username || username.trim() === '') {
            return res.status(400).json({ message: "El nombre de usuario es requerido" });
        }

        const existingUser = await sql`SELECT * FROM users WHERE id = ${id}`;
        if (existingUser.length === 0) {
            return res.status(404).json({ message: "Usuario no encontrado" });
        }

        if (req.user.userId != id) {
            return res.status(403).json({ message: "No tienes permiso para modificar este usuario" });
        }

        await sql`UPDATE users SET username = ${username} WHERE id = ${id}`;

        res.json({ message: "Usuario actualizado correctamente" });
    } catch (error) {
        console.error("Error al actualizar usuario:", error);
        res.status(500).json({ message: "Error al actualizar usuario" });
    }
}

export const deleteUser = async (req, res) => {
    try {
        const { id } = req.params;

        if (req.user.userId != id) {
            return res.status(403).json({ message: "No tienes permiso para eliminar este usuario" });
        }

        await sql`DELETE FROM users WHERE id = ${id}`;

        res.json({ message: "Usuario eliminado correctamente" });
    } catch (error) {
        console.error("Error al eliminar usuario:", error);
        res.status(500).json({ message: "Error al eliminar usuario" });
    }
}

