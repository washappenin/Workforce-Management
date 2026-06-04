import type { Request, Response } from "express";

import { login, getCurrentUser, logout } from "./auth.service";
import type { LoginInput } from "./auth.validation";

export const loginController = async (req: Request, res: Response) => {
  const result = await login(req.body as LoginInput, {
    deviceId: req.header("x-device-id"),
    platform: req.header("x-device-platform") ?? req.header("user-agent")
  });

  res.status(200).json({ data: result });
};

export const meController = async (req: Request, res: Response) => {
  const user = await getCurrentUser(req.user!.id);

  res.status(200).json({ data: { user } });
};

export const logoutController = async (req: Request, res: Response) => {
  const result = await logout(req.user!);

  res.status(200).json({ data: result });
};
