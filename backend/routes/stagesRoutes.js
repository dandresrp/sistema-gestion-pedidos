import express from 'express';
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js';
import * as stagesController from '../controllers/stages/stagesController.js';

const router = express.Router();

/**
 * @swagger
 * /api/estados:
 *   get:
 *     summary: Obtener todos los estados
 *     tags: [Estados]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de estados
 *       401:
 *         description: No autorizado
 */
router.get('/', authenticateJWT, stagesController.getAllStages);

export default router;
