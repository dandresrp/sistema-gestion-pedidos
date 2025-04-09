import express from 'express';
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js';
import * as valueController from '../controllers/value/valueController.js';

const router = express.Router();

/**
 * @swagger
 * /api/valores:
 *   get:
 *     summary: Obtener todos los valores
 *     tags: [Valores]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de valores
 *       401:
 *         description: No autorizado
 */
router.get('/', authenticateJWT, valueController.getAllValues);

export default router;
