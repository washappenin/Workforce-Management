import jwt, { type JwtPayload, type SignOptions } from "jsonwebtoken";

import { env, isTest } from "../config/env";
import { AuthenticationError } from "./errors";
import type { Role } from "../types/auth";

export interface AccessTokenPayload {
  userId: string;
  email: string;
  companyId?: string | null;
  roles: Role[];
  status: string;
  sessionId: string;
}

const getAccessSecret = () => {
  const accessSecret = env.JWT_ACCESS_SECRET ?? env.JWT_SECRET;

  if (accessSecret) {
    return accessSecret;
  }

  if (isTest) {
    return "test-only-access-secret";
  }

  throw new Error("JWT_SECRET or JWT_ACCESS_SECRET is required");
};

const isAccessTokenPayload = (payload: string | JwtPayload): payload is AccessTokenPayload & JwtPayload => {
  if (typeof payload === "string") {
    return false;
  }

  return (
    typeof payload.userId === "string" &&
    typeof payload.email === "string" &&
    Array.isArray(payload.roles) &&
    typeof payload.status === "string" &&
    typeof payload.sessionId === "string"
  );
};

export const signAccessToken = (payload: AccessTokenPayload) =>
  jwt.sign(payload, getAccessSecret(), {
    expiresIn: env.JWT_ACCESS_TTL as SignOptions["expiresIn"]
  });

export const verifyAccessToken = (token: string): AccessTokenPayload => {
  try {
    const payload = jwt.verify(token, getAccessSecret());

    if (!isAccessTokenPayload(payload)) {
      throw new AuthenticationError("Invalid or expired token");
    }

    return {
      userId: payload.userId,
      email: payload.email,
      companyId: payload.companyId ?? null,
      roles: payload.roles,
      status: payload.status,
      sessionId: payload.sessionId
    };
  } catch (error) {
    if (error instanceof AuthenticationError) {
      throw error;
    }

    throw new AuthenticationError("Invalid or expired token");
  }
};
