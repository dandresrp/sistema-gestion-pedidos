import express from "express";
import {authenticateJWT} from "../middlewares/auth.js";
import * as userController from "../controllers/userController.js";

const router = express.Router();

router.get("/", authenticateJWT, userController.getAllUsers);
router.get("/:id", authenticateJWT, userController.getUserById);
router.put("/:id", authenticateJWT, userController.updateUser);
router.delete("/:id", authenticateJWT, userController.deleteUser);

export default router;