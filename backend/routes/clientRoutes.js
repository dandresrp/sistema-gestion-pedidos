import express from 'express'
import { authenticateJWT } from '../middlewares/auth.js'
import { authorizeAdmin } from '../middlewares/authAdmin.js'
import * as clientController from '../controllers/clientController.js'

const router = express.Router()

router.get('/', authenticateJWT, clientController.getAllClients)
router.get('/:id_cliente', authenticateJWT, clientController.getClientById)
router.put('/:id_cliente', authenticateJWT,  authorizeAdmin, clientController.updateClient)
router.delete('/:id_cliente',authenticateJWT, authorizeAdmin, clientController.deleteClient)
router.post('/',authenticateJWT, authorizeAdmin, clientController.addClient)

export default router