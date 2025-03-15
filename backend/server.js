import dotenv from "dotenv";
import express from "express";
import cors from "cors";
import userRoutes from "./routes/userRoutes.js";
import authRoutes from "./routes/authRoutes.js";
import clienteRoutes from "./routes/clientRoutes.js"

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(cors());

app.use("/api/auth", authRoutes);
app.use("/api/usuarios", userRoutes);
app.use("/api/clients", clienteRoutes)

app.listen(port, () => {
  console.log(`Servidor ejecutándose en: http://localhost:${port}`);
});