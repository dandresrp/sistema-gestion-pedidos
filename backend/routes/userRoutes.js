import express from "express";
import {authenticateJWT, authorizeAdmin} from "../middlewares/auth.js";
import * as userController from "../controllers/userController.js";

const router = express.Router();

router.get("/", authenticateJWT, userController.getAllUsers);
router.get("/:id_usuario", authenticateJWT, userController.getUserById);
router.put("/:id_usuario", [authenticateJWT, authorizeAdmin], userController.updateUser);
router.delete("/:id_usuario", [authenticateJWT, authorizeAdmin], userController.deleteUser);

export default router;