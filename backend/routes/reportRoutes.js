import express from 'express';
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js';
import * as reportController from '../controllers/reportController.js';

const router = express.Router();

/**
 * @swagger
 * /api/reportes/orders/{month}:
 *   get:
 *     summary: Obtener ordenes por mes
 *     tags: [Reportes]
 *     parameters:
 *       - in: path
 *         name: month
 *         required: true
 *         description: El mes por el que se filtraran las ordenes (1-12).
 *         schema:
 *           type: integer
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de ordenes filtradas por mes
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get(
  '/orders/:month',
  authenticateJWT,
  reportController.getOrdersByMonth,
);

export default router;
