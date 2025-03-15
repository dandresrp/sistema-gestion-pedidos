import express from 'express'
import { authenticateJWT, authorizeAdmin } from '../middlewares/auth.js'
import * as clientController from '../controllers/clientController.js'

const router = express.Router()

router.get('/', authenticateJWT, clientController.getAllClients)
router.get('/:id_cliente', authenticateJWT, clientController.getClientById)
router.post('/', [authenticateJWT, authorizeAdmin], clientController.addClient)
router.put('/:id_cliente', [authenticateJWT, authorizeAdmin], clientController.updateClient)
router.delete('/:id_cliente',[authenticateJWT, authorizeAdmin], clientController.deleteClient)

export default router