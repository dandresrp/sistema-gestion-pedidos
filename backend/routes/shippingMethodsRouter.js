import express from 'express';
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js';
import * as shippingMethodsController from '../controllers/shippingMethods/shippingMethodsController.js';

const router = express.Router();

/**
 * @swagger
 * /api/metodos-de-envio:
 *   get:
 *     summary: Obtener todos los métodos de envío
 *     tags: [Métodos de Envío]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de métodos de envío
 *       401:
 *         description: No autorizado
 */
router.get(
  '/',
  authenticateJWT,
  shippingMethodsController.getAllShippingMethods,
);

export default router;
