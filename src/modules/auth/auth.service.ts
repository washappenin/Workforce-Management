import { AuthenticationError } from "../../lib/errors";
import { signAccessToken, verifyAccessToken } from "../../lib/jwt";
import { verifyPassword } from "../../lib/password";
import type { AuthenticatedUser } from "../../types/auth";
import { getAuthRepository } from "./auth.repository";
import type { LoginInput } from "./auth.validation";

const invalidCredentialsError = () => new AuthenticationError("Invalid email or password");

export interface AuthenticatedUserResponse {
  id: string;
  email: string;
  companyId: string | null;
  roles: string[];
  status: string;
}

export interface LoginContext {
  deviceId?: string | null;
  platform?: string | null;
}

const toUserResponse = (user: {
  id: string;
  email: string;
  companyId: string | null;
  roles: string[];
  status: string;
}): AuthenticatedUserResponse => ({
  id: user.id,
  email: user.email,
  companyId: user.companyId,
  roles: user.roles,
  status: user.status
});

export const login = async (input: LoginInput, context: LoginContext = {}) => {
  const repository = getAuthRepository();
  const users = await repository.findUsersByEmail(input.email);

  if (users.length !== 1) {
    throw invalidCredentialsError();
  }

  const user = users[0];

  if (user.status !== "ACTIVE") {
    throw invalidCredentialsError();
  }

  const passwordMatches = await verifyPassword(input.password, user.passwordHash);

  if (!passwordMatches) {
    throw invalidCredentialsError();
  }

  const session = await repository.createDeviceSession({
    userId: user.id,
    companyId: user.companyId,
    deviceId: context.deviceId,
    platform: context.platform
  });

  await repository.updateLastLoginAt(user.id, new Date());

  const responseUser = toUserResponse(user);
  const accessToken = signAccessToken({
    userId: user.id,
    email: user.email,
    companyId: user.companyId,
    roles: user.roles,
    status: user.status,
    sessionId: session.id
  });

  return {
    user: responseUser,
    accessToken,
    tokenType: "Bearer" as const
  };
};

export const authenticateAccessToken = async (token: string): Promise<AuthenticatedUser> => {
  const payload = verifyAccessToken(token);
  const repository = getAuthRepository();
  const session = await repository.findActiveDeviceSessionById(payload.sessionId);

  if (!session || session.userId !== payload.userId) {
    throw new AuthenticationError("Invalid or expired token");
  }

  const user = await repository.findUserById(payload.userId);

  if (!user || user.status !== "ACTIVE") {
    throw new AuthenticationError("Invalid or expired token");
  }

  return {
    id: user.id,
    email: user.email,
    companyId: user.companyId,
    roles: user.roles,
    status: user.status,
    sessionId: session.id
  };
};

export const getCurrentUser = async (userId: string) => {
  const user = await getAuthRepository().findUserById(userId);

  if (!user || user.status !== "ACTIVE") {
    throw new AuthenticationError("Invalid or expired token");
  }

  return toUserResponse(user);
};

export const logout = async (user: AuthenticatedUser) => {
  await getAuthRepository().revokeDeviceSession(user.sessionId, user.id);

  return {
    success: true
  };
};
