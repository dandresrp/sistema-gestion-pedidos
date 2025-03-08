import express from "express";
import * as authController from "../controllers/authController.js";

const router = express.Router();

router.post("/signup", authController.signUp);
router.post("/signin", authController.signIn);

export default router;