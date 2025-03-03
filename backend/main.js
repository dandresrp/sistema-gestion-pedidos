import dotenv from "dotenv";
import express from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import sql from "./db.js";

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

// Endpoint para ver todos los usuarios
app.get("/users", async (req, res) => {
  const users = await sql`
           SELECT * FROM users;
      `;
  res.send(users);
});

// Endpoint de registro
app.post("/auth/sign-up", async (req, res) => {
  const { username, password } = req.body;

  // Verificar si el usuario ya existe
  const userExists = users.find((user) => user.username === username);
  if (userExists) {
    return res.status(400).json({ message: "El usuario ya existe" });
  }

  // Encriptar la contraseña
  const hashedPassword = await bcrypt.hash(password, 10);

  // Guardar usuario en la "base de datos"
  users.push({
    username,
    password: hashedPassword,
  });

  res.status(201).json({ message: "Usuario registrado exitosamente" });
});

// Endpoint de inicio de sesión
app.post("/auth/sign-in", async (req, res) => {
  const { username, password } = req.body;

  // Buscar usuario en la "base de datos"
  const user = users.find((user) => user.username === username);
  if (!user) {
    return res
      .status(400)
      .json({ message: "Usuario o contraseña incorrectos" });
  }

  // Verificar la contraseña
  const isPasswordValid = await bcrypt.compare(password, user.password);
  if (!isPasswordValid) {
    return res
      .status(400)
      .json({ message: "Usuario o contraseña incorrectos" });
  }

  // Generar token JWT
  const token = jwt.sign({ username: user.username }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN,
  });

  res.json({ message: "Inicio de sesión exitoso", token });
});

// Middleware para proteger rutas
const authenticateJWT = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (authHeader) {
    const token = authHeader.split(" ")[1];

    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
      if (err) {
        return res.sendStatus(403);
      }

      req.user = user;
      next();
    });
  } else {
    res.sendStatus(401);
  }
};

// Ruta protegida
app.get("/protected", authenticateJWT, (req, res) => {
  res.json({ message: "Accediste a una ruta protegida", user: req.user });
});

// Iniciar el servidor
app.listen(port, () => {
  console.log(`Servidor ejecutándose en: http://localhost:${port}`);
});
