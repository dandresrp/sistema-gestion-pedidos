import dotenv from "dotenv";
import express from "express";
import cors from "cors";
import swaggerJsdoc from "swagger-jsdoc";
import swaggerUi from "swagger-ui-express";
import userRoutes from "./routes/userRoutes.js";
import authRoutes from "./routes/authRoutes.js";
import clientRoutes from "./routes/clientRoutes.js"

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

const swaggerOptions = {
  definition: {
    openapi: "3.0.0",
    info: {
      title: "Sistema de Gestión de Pedidos API",
      version: "1.0.0",
      description: "API para el sistema de gestión de pedidos",
    },
    servers: [
      {
        url: `http://localhost:${port}`,
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: "http",
          scheme: "bearer",
          bearerFormat: 'JWT',
        }
      }
    }
  },
  apis: ["./routes/*.js", './controllers/*.js'],
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

app.use(express.json());
app.use(cors());

app.use("/api/docs", swaggerUi.serve, swaggerUi.setup(swaggerSpec));

app.use("/api/auth", authRoutes);
app.use("/api/usuarios", userRoutes);
app.use("/api/clientes", clientRoutes)

app.listen(port, () => {
  console.log(`Servidor ejecutándose en: http://localhost:${port}`);
  console.log(`Documentación de la API en: http://localhost:${port}/api/docs`);
});