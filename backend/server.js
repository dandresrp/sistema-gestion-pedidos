import dotenv from 'dotenv';
import express from 'express';
import cors from 'cors';
import { swaggerSpec } from './config/swagger/swagger.js';
import swaggerUi from 'swagger-ui-express';
import userRoutes from './routes/userRoutes.js';
import authRoutes from './routes/authRoutes.js';
import clientRoutes from './routes/clientRoutes.js';
import reportRoutes from './routes/reportRoutes.js';
import roleRoutes from './routes/roleRoutes.js';
import valueRoutes from './routes/valueRoutes.js';
import stagesRoutes from './routes/stagesRoutes.js';
import shippingMethodsRoutes from './routes/shippingMethodsRouter.js';
import orderRoutes from './routes/orderRoutes.js';
import { responseHandler } from './middlewares/responseHandler.js';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());
app.use(cors());
app.use(responseHandler);

app.use('/api/docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));
app.use('/api/auth', authRoutes);
app.use('/api/usuarios', userRoutes);
app.use('/api/clientes', clientRoutes);
app.use('/api/reportes', reportRoutes);
app.use('/api/roles', roleRoutes);
app.use('/api/valores', valueRoutes);
app.use('/api/estados', stagesRoutes);
app.use('/api/metodos-de-envio', shippingMethodsRoutes);
app.use('/api/pedidos', orderRoutes);

app.listen(port, () => {
  console.log(`Servidor ejecutándose en: http://localhost:${port}`);
  console.log(`Documentación de la API en: http://localhost:${port}/api/docs`);
});
