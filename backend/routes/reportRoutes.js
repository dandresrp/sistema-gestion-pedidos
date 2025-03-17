import express from 'express';
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js';
import * as reportController from '../controllers/reportController.js';

const router = express.Router();

/**
 * @swagger
 * /api/reportes/orders:
 *   get:
 *     summary: Obtener pedidos por mes
 *     tags: [Reportes]
 *     parameters:
 *       - in: query
 *         name: startDate
 *         required: true
 *         description: Fecha de inicio para filtrar pedidos (formato string)
 *         schema:
 *           type: string
 *       - in: query
 *         name: endDate
 *         required: true
 *         description: Fecha final para filtrar pedidos (formato string)
 *         schema:
 *           type: string
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de pedidos filtrados por mes
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get('/orders', authenticateJWT, reportController.getOrdersByMonth);

export default router;
