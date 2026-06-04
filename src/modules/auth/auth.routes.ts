import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import { loginController, logoutController, meController } from "./auth.controller";
import { loginSchema } from "./auth.validation";

export const authRouter = Router();

authRouter.post("/login", validateRequest({ body: loginSchema }, { statusCode: 400 }), asyncHandler(loginController));
authRouter.get("/me", requireAuthentication, asyncHandler(meController));
authRouter.post("/logout", requireAuthentication, asyncHandler(logoutController));
