import express from 'express';
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js';
import * as clientController from '../controllers/client/clientController.js';

const router = express.Router();

/**
 * @swagger
 * /api/clientes:
 *   get:
 *     summary: Obtiene todos los clientes
 *     tags: [Clientes]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Lista de clientes
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.get('/', authenticateJWT, clientController.getAllClients);

/**
 * @swagger
 * /api/clientes/{cliente_id}:
 *   get:
 *     summary: Obtiene un cliente por ID
 *     tags: [Clientes]
 *     parameters:
 *       - in: path
 *         name: cliente_id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID del cliente
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Datos del cliente
 *       404:
 *         description: Cliente no encontrado
 *       500:
 *         description: Error del servidor
 */
router.get('/:cliente_id', authenticateJWT, clientController.getClientById);

/**
 * @swagger
 * /api/clientes:
 *   post:
 *     summary: Crea un nuevo cliente
 *     tags: [Clientes]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre:
 *                 type: string
 *               telefono:
 *                 type: string
 *               correo:
 *                 type: string
 *               direccion:
 *                 type: string
 *             required:
 *               - nombre
 *               - telefono
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       201:
 *         description: Cliente creado
 *       400:
 *         description: Solicitud no válida
 *       401:
 *         description: No autorizado
 *       500:
 *         description: Error del servidor
 */
router.post('/', [authenticateJWT, authorizeAdmin], clientController.addClient);

/**
 * @swagger
 * /api/clientes/{cliente_id}:
 *   put:
 *     summary: Actualiza un cliente por ID
 *     tags: [Clientes]
 *     parameters:
 *       - in: path
 *         name: cliente_id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID del cliente
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               nombre:
 *                 type: string
 *               telefono:
 *                 type: string
 *               correo:
 *                 type: string
 *               direccion:
 *                 type: string
 *             required:
 *               - nombre
 *               - telefono
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Cliente actualizado
 *       400:
 *         description: Solicitud no válida
 *       401:
 *         description: No autorizado
 *       404:
 *         description: Cliente no encontrado
 */
router.put(
  '/:cliente_id',
  [authenticateJWT, authorizeAdmin],
  clientController.updateClient,
);

/**
 * @swagger
 * /api/clientes/{cliente_id}:
 *   delete:
 *     summary: Elimina un cliente por ID
 *     tags: [Clientes]
 *     parameters:
 *       - in: path
 *         name: cliente_id
 *         schema:
 *           type: string
 *         required: true
 *         description: ID del cliente
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Cliente eliminado
 *       401:
 *         description: No autorizado
 *       404:
 *         description: Cliente no encontrado
 */
router.delete(
  '/:cliente_id',
  [authenticateJWT, authorizeAdmin],
  clientController.deleteClient,
);

export default router;
