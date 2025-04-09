import express from 'express';
import * as authController from '../controllers/auth/authController.js';
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js';

const router = express.Router();

/**
 * @swagger
 * /api/auth/sign-up:
 *   post:
 *     summary: Registrar un nuevo usuario
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre:
 *                 type: string
 *               nombre_usuario:
 *                 type: string
 *               rol:
 *                 type: integer
 *               correo:
 *                 type: string
 *               contrasena:
 *                 type: string

 *     responses:
 *       200:
 *         description: Usuario registrado exitosamente
 *       400:
 *         description: Error en la solicitud
 *       401:
 *         description: No autorizado
 */
router.post(
  '/sign-up',
  [authenticateJWT, authorizeAdmin],
  authController.signUp,
);
router.post('/sign-in', authController.signIn);
router.post('/refresh-token', authController.refreshToken);

export default router;
