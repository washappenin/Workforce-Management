import type { DeviceSessionStatus, UserStatus } from "@prisma/client";
import request from "supertest";

import { app } from "../../src/app";
import { hashPassword } from "../../src/lib/password";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";
import type { Role } from "../../src/types/auth";

const createMemoryAuthRepository = (users: AuthUserRecord[]): AuthRepository => {
  const userStore = new Map(users.map((user) => [user.id, user]));
  const sessions = new Map<string, AuthDeviceSessionRecord>();
  let sessionCounter = 0;

  return {
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
        sessions.set(sessionId, { ...session, status: "REVOKED" });
      }
    }
  };
};

const makeUser = (role: Role, companyId: string | null = "company-1"): Omit<AuthUserRecord, "passwordHash"> => ({
  id: role.toLowerCase().replace("_", "-"),
  email: `${role.toLowerCase().replace("_", "")}@example.test`,
  status: "ACTIVE" as UserStatus,
  companyId,
  roles: [role]
});

describe("CP4 authorization and company scoping", () => {
  let passwordHash: string;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    setAuthRepositoryForTests(
      createMemoryAuthRepository([
        { ...makeUser("SUPER_ADMIN", null), passwordHash },
        { ...makeUser("COMPANY_ADMIN"), passwordHash },
        { ...makeUser("HR_ADMIN"), passwordHash },
        { ...makeUser("MANAGER"), passwordHash },
        { ...makeUser("EMPLOYEE"), passwordHash },
        {
          id: "orphan-manager",
          email: "orphanmanager@example.test",
          passwordHash,
          status: "ACTIVE" as UserStatus,
          companyId: null,
          roles: ["MANAGER"]
        }
      ])
    );
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
  });

  const loginAs = async (role: Role) => {
    const response = await request(app)
      .post("/api/auth/login")
      .send({ email: `${role.toLowerCase().replace("_", "")}@example.test`, password: "Password123!" })
      .expect(200);

    return response.body.data.accessToken as string;
  };

  const loginOrphanManager = async () => {
    const response = await request(app)
      .post("/api/auth/login")
      .send({ email: "orphanmanager@example.test", password: "Password123!" })
      .expect(200);

    return response.body.data.accessToken as string;
  };

  describe("authentication boundary", () => {
    it("returns 401 when a protected route has no token", async () => {
      const response = await request(app).get("/api/system/auth-check").expect(401);

      expect(response.body.error).toMatchObject({
        code: "UNAUTHENTICATED",
        message: "Authentication required"
      });
    });

    it("returns 401 when a protected route has an invalid token", async () => {
      const response = await request(app).get("/api/system/auth-check").set("Authorization", "Bearer nope").expect(401);

      expect(response.body.error).toMatchObject({
        code: "UNAUTHENTICATED",
        message: "Invalid or expired token"
      });
    });

    it("allows a valid token to reach a protected route", async () => {
      const token = await loginAs("EMPLOYEE");
      const response = await request(app).get("/api/system/auth-check").set("Authorization", `Bearer ${token}`).expect(200);

      expect(response.body.data).toMatchObject({
        authenticated: true,
        user: {
          email: "employee@example.test",
          companyId: "company-1",
          roles: ["EMPLOYEE"]
        }
      });
    });
  });

  describe("role checks", () => {
    it("allows SUPER_ADMIN to access the super-admin route", async () => {
      const token = await loginAs("SUPER_ADMIN");
      await request(app).get("/api/system/role-check/super-admin").set("Authorization", `Bearer ${token}`).expect(200);
    });

    it("rejects COMPANY_ADMIN from the super-admin route", async () => {
      const token = await loginAs("COMPANY_ADMIN");
      await request(app).get("/api/system/role-check/super-admin").set("Authorization", `Bearer ${token}`).expect(403);
    });

    it("rejects HR_ADMIN from the company-admin-only route", async () => {
      const token = await loginAs("HR_ADMIN");
      await request(app).get("/api/system/role-check/company-admin").set("Authorization", `Bearer ${token}`).expect(403);
    });

    it("rejects MANAGER from the HR route", async () => {
      const token = await loginAs("MANAGER");
      await request(app).get("/api/system/role-check/hr-admin").set("Authorization", `Bearer ${token}`).expect(403);
    });

    it("rejects EMPLOYEE from manager/admin/super-admin routes", async () => {
      const token = await loginAs("EMPLOYEE");

      await request(app).get("/api/system/role-check/manager").set("Authorization", `Bearer ${token}`).expect(403);
      await request(app).get("/api/system/role-check/company-admin").set("Authorization", `Bearer ${token}`).expect(403);
      await request(app).get("/api/system/role-check/super-admin").set("Authorization", `Bearer ${token}`).expect(403);
    });

    it("allows requireAnyRole for COMPANY_ADMIN and HR_ADMIN only", async () => {
      const companyAdminToken = await loginAs("COMPANY_ADMIN");
      const hrAdminToken = await loginAs("HR_ADMIN");
      const employeeToken = await loginAs("EMPLOYEE");

      await request(app).get("/api/system/role-check/admin-or-hr").set("Authorization", `Bearer ${companyAdminToken}`).expect(200);
      await request(app).get("/api/system/role-check/admin-or-hr").set("Authorization", `Bearer ${hrAdminToken}`).expect(200);
      await request(app).get("/api/system/role-check/admin-or-hr").set("Authorization", `Bearer ${employeeToken}`).expect(403);
    });
  });

  describe("company scoping", () => {
    it("allows COMPANY_ADMIN to access their own company scope", async () => {
      const token = await loginAs("COMPANY_ADMIN");
      const response = await request(app)
        .get("/api/system/company-scope/company-1")
        .set("Authorization", `Bearer ${token}`)
        .expect(200);

      expect(response.body.data.companyScope).toEqual({
        companyId: "company-1",
        isSuperAdmin: false,
        requestedCompanyId: "company-1"
      });
    });

    it.each(["COMPANY_ADMIN", "HR_ADMIN", "MANAGER", "EMPLOYEE"] as Role[])(
      "rejects %s from another company scope",
      async (role) => {
        const token = await loginAs(role);
        const response = await request(app)
          .get("/api/system/company-scope/company-2")
          .set("Authorization", `Bearer ${token}`)
          .expect(403);

        expect(response.body.error).toMatchObject({
          code: "FORBIDDEN",
          message: "Company scope mismatch"
        });
      }
    );

    it("allows SUPER_ADMIN to access any company scope", async () => {
      const token = await loginAs("SUPER_ADMIN");
      const response = await request(app)
        .get("/api/system/company-scope/company-2")
        .set("Authorization", `Bearer ${token}`)
        .expect(200);

      expect(response.body.data.companyScope).toEqual({
        companyId: "company-2",
        isSuperAdmin: true,
        requestedCompanyId: "company-2"
      });
    });

    it("rejects body companyId mismatch", async () => {
      const token = await loginAs("COMPANY_ADMIN");
      await request(app)
        .post("/api/system/company-scope/company-1")
        .set("Authorization", `Bearer ${token}`)
        .send({ companyId: "company-2" })
        .expect(403);
    });

    it("rejects query companyId mismatch", async () => {
      const token = await loginAs("COMPANY_ADMIN");
      await request(app)
        .get("/api/system/company-scope/company-1?companyId=company-2")
        .set("Authorization", `Bearer ${token}`)
        .expect(403);
    });

    it("rejects missing required companyId for non-super-admin routes", async () => {
      const token = await loginAs("COMPANY_ADMIN");
      await request(app).get("/api/system/company-scope-required").set("Authorization", `Bearer ${token}`).expect(403);
    });

    it("rejects non-super-admin users without a company when company scope is required", async () => {
      const token = await loginOrphanManager();
      await request(app).get("/api/system/company-scope/company-1").set("Authorization", `Bearer ${token}`).expect(403);
    });
  });
});
