import express from 'express'
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js'
import * as clientController from '../controllers/clientController.js'

const router = express.Router()

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
router.get('/', authenticateJWT, clientController.getAllClients)

/**
 * @swagger
 * /api/clientes/{id_cliente}:
 *   get:
 *     summary: Obtiene un cliente por ID
 *     tags: [Clientes]
 *     parameters:
 *       - in: path
 *         name: id_cliente
 *         schema:
 *           type: integer
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
router.get('/:id_cliente', authenticateJWT, clientController.getClientById)

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
 *               name:
 *                 type: string
 *               email:
 *                 type: string
 *               phone:
 *                 type: string
 *             required:
 *               - name
 *               - email
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
router.post('/', [authenticateJWT, authorizeAdmin], clientController.addClient)

/**
 * @swagger
 * /api/clientes/{id_cliente}:
 *   put:
 *     summary: Actualiza un cliente por ID
 *     tags: [Clientes]
 *     parameters:
 *       - in: path
 *         name: id_cliente
 *         schema:
 *           type: integer
 *         required: true
 *         description: ID del cliente
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *               email:
 *                 type: string
 *               phone:
 *                 type: string
 *             required:
 *               - name
 *               - email
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
router.put('/:id_cliente', [authenticateJWT, authorizeAdmin], clientController.updateClient)

/**
 * @swagger
 * /api/clientes/{id_cliente}:
 *   delete:
 *     summary: Elimina un cliente por ID
 *     tags: [Clientes]
 *     parameters:
 *       - in: path
 *         name: id_cliente
 *         schema:
 *           type: integer
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
router.delete('/:id_cliente',[authenticateJWT, authorizeAdmin], clientController.deleteClient)

export default router