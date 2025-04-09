import express from 'express';
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js';
import * as ordersController from '../controllers/orders/ordersController.js';
import e from 'express';

const router = express.Router();

/**
 * @swagger
 * /api/pedidos:
 *   get:
 *     summary: Obtiene todos los pedidos
 *     tags: [Pedidos]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: estado
 *         description: Filtrar pedidos por estado
 *         schema:
 *           type: string
 *       - in: query
 *         name: nombre_cliente
 *         description: Filtrar pedidos por nombre cliente
 *         schema:
 *           type: string
 *       - in: query
 *         name: pedido_id
 *         description: Filtrar pedidos por ID de pedido
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Lista de pedidos
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get('/', authenticateJWT, ordersController.getAllOrders);

export default router;
