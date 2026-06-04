import type { DeviceSessionStatus, UserStatus } from "@prisma/client";
import request from "supertest";

import { app } from "../../src/app";
import { hashPassword } from "../../src/lib/password";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";

const createMemoryAuthRepository = (users: AuthUserRecord[]): AuthRepository & { sessions: Map<string, AuthDeviceSessionRecord> } => {
  const userStore = new Map(users.map((user) => [user.id, user]));
  const sessions = new Map<string, AuthDeviceSessionRecord>();
  let sessionCounter = 0;

  return {
    sessions,

    async findUsersByEmail(email) {
      return Array.from(userStore.values()).filter((user) => user.email === email);
    },

    async findUserById(userId) {
      return userStore.get(userId) ?? null;
    },

    async updateLastLoginAt() {
      return undefined;
    },

    async createDeviceSession(input) {
      sessionCounter += 1;
      const session = {
        id: `session-${sessionCounter}`,
        userId: input.userId,
        companyId: input.companyId ?? null,
        status: "ACTIVE" as DeviceSessionStatus
      };

      sessions.set(session.id, session);
      return session;
    },

    async findActiveDeviceSessionById(sessionId) {
      const session = sessions.get(sessionId);
      return session?.status === "ACTIVE" ? session : null;
    },

    async revokeDeviceSession(sessionId, userId) {
      const session = sessions.get(sessionId);

      if (session?.userId === userId) {
        sessions.set(sessionId, {
          ...session,
          status: "REVOKED"
        });
      }
    }
  };
};

describe("auth endpoints", () => {
  let repository: ReturnType<typeof createMemoryAuthRepository>;
  let testPasswordHash: string;

  beforeAll(async () => {
    testPasswordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    repository = createMemoryAuthRepository([
      {
        id: "user-active",
        email: "employee@example.test",
        passwordHash: testPasswordHash,
        status: "ACTIVE" as UserStatus,
        companyId: "company-1",
        roles: ["EMPLOYEE"]
      },
      {
        id: "user-disabled",
        email: "disabled@example.test",
        passwordHash: testPasswordHash,
        status: "DISABLED" as UserStatus,
        companyId: "company-1",
        roles: ["EMPLOYEE"]
      }
    ]);

    setAuthRepositoryForTests(repository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
  });

  describe("POST /api/auth/login", () => {
    it("logs in an active user and returns a bearer token without passwordHash", async () => {
      const response = await request(app)
        .post("/api/auth/login")
        .send({ email: "EMPLOYEE@EXAMPLE.TEST", password: "Password123!" })
        .expect(200);

      expect(response.body.data).toEqual({
        user: {
          id: "user-active",
          email: "employee@example.test",
          companyId: "company-1",
          roles: ["EMPLOYEE"],
          status: "ACTIVE"
        },
        accessToken: expect.any(String),
        tokenType: "Bearer"
      });
      expect(JSON.stringify(response.body)).not.toContain("passwordHash");
    });

    it("rejects an invalid password with a generic 401", async () => {
      const response = await request(app)
        .post("/api/auth/login")
        .send({ email: "employee@example.test", password: "wrong" })
        .expect(401);

      expect(response.body.error).toMatchObject({
        code: "UNAUTHENTICATED",
        message: "Invalid email or password"
      });
    });

    it("rejects an unknown email with the same generic 401", async () => {
      const response = await request(app)
        .post("/api/auth/login")
        .send({ email: "unknown@example.test", password: "Password123!" })
        .expect(401);

      expect(response.body.error).toMatchObject({
        code: "UNAUTHENTICATED",
        message: "Invalid email or password"
      });
    });

    it("rejects an inactive user with the same generic 401", async () => {
      const response = await request(app)
        .post("/api/auth/login")
        .send({ email: "disabled@example.test", password: "Password123!" })
        .expect(401);

      expect(response.body.error).toMatchObject({
        code: "UNAUTHENTICATED",
        message: "Invalid email or password"
      });
    });

    it("returns 400 for validation failures", async () => {
      const response = await request(app).post("/api/auth/login").send({ email: "bad" }).expect(400);

      expect(response.body.error).toMatchObject({
        code: "VALIDATION_ERROR",
        message: "Invalid body"
      });
    });
  });

  it("does not expose a public registration endpoint", async () => {
    await request(app).post("/api/auth/register").send({ email: "new@example.test", password: "Password123!" }).expect(404);
  });

  describe("GET /api/auth/me", () => {
    it("returns the current user with a valid token and no passwordHash", async () => {
      const loginResponse = await request(app)
        .post("/api/auth/login")
        .send({ email: "employee@example.test", password: "Password123!" })
        .expect(200);

      const response = await request(app)
        .get("/api/auth/me")
        .set("Authorization", `Bearer ${loginResponse.body.data.accessToken}`)
        .expect(200);

      expect(response.body.data).toEqual({
        user: {
          id: "user-active",
          email: "employee@example.test",
          companyId: "company-1",
          roles: ["EMPLOYEE"],
          status: "ACTIVE"
        }
      });
      expect(JSON.stringify(response.body)).not.toContain("passwordHash");
    });

    it("rejects missing tokens", async () => {
      const response = await request(app).get("/api/auth/me").expect(401);

      expect(response.body.error).toMatchObject({
        code: "UNAUTHENTICATED",
        message: "Authentication required"
      });
    });

    it("rejects invalid tokens", async () => {
      const response = await request(app).get("/api/auth/me").set("Authorization", "Bearer invalid").expect(401);

      expect(response.body.error).toMatchObject({
        code: "UNAUTHENTICATED",
        message: "Invalid or expired token"
      });
    });
  });

  describe("POST /api/auth/logout", () => {
    it("revokes the current device session", async () => {
      const loginResponse = await request(app)
        .post("/api/auth/login")
        .send({ email: "employee@example.test", password: "Password123!" })
        .expect(200);

      const token = loginResponse.body.data.accessToken;
      await request(app).post("/api/auth/logout").set("Authorization", `Bearer ${token}`).expect(200);

      expect(Array.from(repository.sessions.values())).toEqual([
        {
          id: "session-1",
          userId: "user-active",
          companyId: "company-1",
          status: "REVOKED"
        }
      ]);

      await request(app).get("/api/auth/me").set("Authorization", `Bearer ${token}`).expect(401);
    });

    it("rejects missing tokens", async () => {
      const response = await request(app).post("/api/auth/logout").expect(401);

      expect(response.body.error).toMatchObject({
        code: "UNAUTHENTICATED",
        message: "Authentication required"
      });
    });
  });
});
