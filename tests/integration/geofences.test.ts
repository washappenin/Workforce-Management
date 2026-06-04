import type { AuditActionCategory, DeviceSessionStatus, GeofenceStatus, UserStatus } from "@prisma/client";
import request from "supertest";

import { app } from "../../src/app";
import type { AuditLogInput, AuditRepository } from "../../src/lib/audit";
import { resetAuditRepositoryForTests, setAuditRepositoryForTests } from "../../src/lib/audit";
import { hashPassword } from "../../src/lib/password";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";
import type {
  GeofenceRecord,
  GeofencesRepository,
  UpdateGeofenceRepositoryInput
} from "../../src/modules/geofences/geofences.repository";
import { resetGeofencesRepositoryForTests, setGeofencesRepositoryForTests } from "../../src/modules/geofences/geofences.repository";
import type { Role } from "../../src/types/auth";

interface MemoryState {
  companies: Map<string, { id: string }>;
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  geofences: Map<string, GeofenceRecord>;
  audits: AuditLogInput[];
  counters: Record<string, number>;
}

const now = () => new Date("2026-06-03T00:00:00.000Z");

const compact = <T extends object>(input: T) =>
  Object.fromEntries(Object.entries(input as Record<string, unknown>).filter(([, value]) => value !== undefined)) as Partial<T>;

const makeUser = (
  id: string,
  email: string,
  companyId: string | null,
  roles: Role[],
  passwordHash: string
): AuthUserRecord => ({
  id,
  email,
  passwordHash,
  status: "ACTIVE" as UserStatus,
  companyId,
  roles
});

const makeGeofence = (
  id: string,
  companyId: string,
  name: string,
  status: GeofenceStatus = "ACTIVE"
): GeofenceRecord => ({
  id,
  companyId,
  name,
  latitude: 9.0301,
  longitude: 38.74,
  radiusMeters: 100,
  status,
  createdAt: now(),
  updatedAt: now()
});

const createState = (passwordHash: string): MemoryState => {
  const users = [
    makeUser("user-super-admin", "superadmin@example.test", null, ["SUPER_ADMIN"], passwordHash),
    makeUser("user-company-admin", "companyadmin@example.test", "company-1", ["COMPANY_ADMIN"], passwordHash),
    makeUser("user-hr-admin", "hradmin@example.test", "company-1", ["HR_ADMIN"], passwordHash),
    makeUser("user-manager", "manager@example.test", "company-1", ["MANAGER"], passwordHash),
    makeUser("user-employee", "employee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-company2-admin", "company2admin@example.test", "company-2", ["COMPANY_ADMIN"], passwordHash),
    makeUser("user-company3-employee", "company3employee@example.test", "company-3", ["EMPLOYEE"], passwordHash)
  ];

  return {
    companies: new Map([["company-1", { id: "company-1" }], ["company-2", { id: "company-2" }], ["company-3", { id: "company-3" }]]),
    users: new Map(users.map((user) => [user.id, user])),
    sessions: new Map(),
    geofences: new Map([
      ["geofence-1", makeGeofence("geofence-1", "company-1", "HQ")],
      ["geofence-2", makeGeofence("geofence-2", "company-2", "Other Company HQ")]
    ]),
    audits: [],
    counters: {
      session: 0,
      geofence: 0
    }
  };
};

const createRepositories = (state: MemoryState) => {
  const authRepository: AuthRepository = {
    async findUsersByEmail(email) {
      return Array.from(state.users.values()).filter((user) => user.email === email);
    },

    async findUserById(userId) {
      return state.users.get(userId) ?? null;
    },

    async updateLastLoginAt() {
      return undefined;
    },

    async createDeviceSession(input) {
      state.counters.session += 1;
      const session = {
        id: `session-${state.counters.session}`,
        userId: input.userId,
        companyId: input.companyId ?? null,
        status: "ACTIVE" as DeviceSessionStatus
      };

      state.sessions.set(session.id, session);
      return session;
    },

    async findActiveDeviceSessionById(sessionId) {
      const session = state.sessions.get(sessionId);
      return session?.status === "ACTIVE" ? session : null;
    },

    async revokeDeviceSession(sessionId, userId) {
      const session = state.sessions.get(sessionId);

      if (session?.userId === userId) {
        state.sessions.set(sessionId, { ...session, status: "REVOKED" as DeviceSessionStatus });
      }
    }
  };

  const geofencesRepository: GeofencesRepository = {
    async findCompanyById(companyId) {
      return state.companies.get(companyId) ?? null;
    },

    async create(input) {
      state.counters.geofence += 1;
      const geofence = {
        id: `geofence-new-${state.counters.geofence}`,
        companyId: input.companyId,
        name: input.name,
        latitude: input.latitude,
        longitude: input.longitude,
        radiusMeters: input.radiusMeters,
        status: input.status ?? ("ACTIVE" as GeofenceStatus),
        createdAt: now(),
        updatedAt: now()
      };

      state.geofences.set(geofence.id, geofence);
      return geofence;
    },

    async list(companyId) {
      return Array.from(state.geofences.values()).filter((geofence) => geofence.companyId === companyId);
    },

    async listActive(companyId) {
      return Array.from(state.geofences.values()).filter(
        (geofence) => geofence.companyId === companyId && geofence.status === "ACTIVE"
      );
    },

    async findByIdInCompany(geofenceId, companyId) {
      const geofence = state.geofences.get(geofenceId);
      return geofence?.companyId === companyId ? geofence : null;
    },

    async findByNameInCompany(name, companyId) {
      return Array.from(state.geofences.values()).find((geofence) => geofence.companyId === companyId && geofence.name === name) ?? null;
    },

    async update(geofenceId, companyId, input: UpdateGeofenceRepositoryInput) {
      const current = await this.findByIdInCompany(geofenceId, companyId);
      const updated = { ...current!, ...compact(input), updatedAt: now() };

      state.geofences.set(geofenceId, updated);
      return updated;
    },

    async updateStatus(geofenceId, companyId, status) {
      const current = await this.findByIdInCompany(geofenceId, companyId);
      const updated = { ...current!, status, updatedAt: now() };

      state.geofences.set(geofenceId, updated);
      return updated;
    }
  };

  const auditRepository: AuditRepository = {
    async create(input) {
      state.audits.push(input);
    }
  };

  return { authRepository, geofencesRepository, auditRepository };
};

describe("CP6 geofence setup and location validation", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setGeofencesRepositoryForTests(repositories.geofencesRepository);
    setAuditRepositoryForTests(repositories.auditRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetGeofencesRepositoryForTests();
    resetAuditRepositoryForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const auditActions = (category?: AuditActionCategory) =>
    state.audits.filter((audit) => !category || audit.category === category).map((audit) => audit.action);

  describe("management", () => {
    it("allows COMPANY_ADMIN and HR_ADMIN to create geofences in their own company", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");

      const companyAdminResponse = await request(app)
        .post("/api/admin/geofences")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ name: "Warehouse", latitude: 9.032, longitude: 38.741, radiusMeters: 150 })
        .expect(201);
      const hrAdminResponse = await request(app)
        .post("/api/admin/geofences")
        .set("Authorization", `Bearer ${hrAdminToken}`)
        .send({ name: "Branch", latitude: 9.033, longitude: 38.742, radiusMeters: 200 })
        .expect(201);

      expect(companyAdminResponse.body.data.geofence.companyId).toBe("company-1");
      expect(hrAdminResponse.body.data.geofence.companyId).toBe("company-1");
      expect(auditActions("GEOFENCE")).toEqual(expect.arrayContaining(["GEOFENCE_CREATED", "GEOFENCE_CREATED"]));
    });

    it("allows SUPER_ADMIN to create a geofence with explicit companyId", async () => {
      const token = await login("superadmin@example.test");
      const response = await request(app)
        .post("/api/admin/geofences")
        .set("Authorization", `Bearer ${token}`)
        .send({ companyId: "company-2", name: "Super Scoped", latitude: 9.03, longitude: 38.74, radiusMeters: 100 })
        .expect(201);

      expect(response.body.data.geofence).toMatchObject({
        companyId: "company-2",
        name: "Super Scoped"
      });
    });

    it("rejects EMPLOYEE, MANAGER, and cross-company create attempts", async () => {
      const employeeToken = await login("employee@example.test");
      const managerToken = await login("manager@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/geofences")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ name: "Employee Blocked", latitude: 9.03, longitude: 38.74, radiusMeters: 100 })
        .expect(403);
      await request(app)
        .post("/api/admin/geofences")
        .set("Authorization", `Bearer ${managerToken}`)
        .send({ name: "Manager Blocked", latitude: 9.03, longitude: 38.74, radiusMeters: 100 })
        .expect(403);
      await request(app)
        .post("/api/admin/geofences")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .send({ companyId: "company-2", name: "Wrong Company", latitude: 9.03, longitude: 38.74, radiusMeters: 100 })
        .expect(403);
    });

    it("does not expose another company's geofence through detail reads", async () => {
      const token = await login("companyadmin@example.test");

      await request(app).get("/api/admin/geofences/geofence-2").set("Authorization", `Bearer ${token}`).expect(404);
    });

    it("updates geofence fields and status within the same company", async () => {
      const token = await login("companyadmin@example.test");

      const updateResponse = await request(app)
        .patch("/api/admin/geofences/geofence-1")
        .set("Authorization", `Bearer ${token}`)
        .send({ name: "HQ Updated", radiusMeters: 125 })
        .expect(200);
      const statusResponse = await request(app)
        .patch("/api/admin/geofences/geofence-1/status")
        .set("Authorization", `Bearer ${token}`)
        .send({ status: "INACTIVE" })
        .expect(200);

      expect(updateResponse.body.data.geofence).toMatchObject({ name: "HQ Updated", radiusMeters: 125 });
      expect(statusResponse.body.data.geofence.status).toBe("INACTIVE");
      expect(auditActions("GEOFENCE")).toEqual(expect.arrayContaining(["GEOFENCE_UPDATED", "GEOFENCE_STATUS_CHANGED"]));
    });

    it("rejects invalid latitude, longitude, and radius", async () => {
      const token = await login("companyadmin@example.test");

      await request(app)
        .post("/api/admin/geofences")
        .set("Authorization", `Bearer ${token}`)
        .send({ name: "Bad Latitude", latitude: 91, longitude: 38.74, radiusMeters: 100 })
        .expect(400);
      await request(app)
        .post("/api/admin/geofences")
        .set("Authorization", `Bearer ${token}`)
        .send({ name: "Bad Longitude", latitude: 9.03, longitude: 181, radiusMeters: 100 })
        .expect(400);
      await request(app)
        .post("/api/admin/geofences")
        .set("Authorization", `Bearer ${token}`)
        .send({ name: "Bad Radius", latitude: 9.03, longitude: 38.74, radiusMeters: 50001 })
        .expect(400);
    });
  });

  describe("location validation", () => {
    it("allows an employee to validate an inside location for their company without audit logging the attempt", async () => {
      const token = await login("employee@example.test");
      const response = await request(app)
        .post("/api/geofences/validate-location")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74 })
        .expect(200);

      expect(response.body.data).toEqual({
        isWithinGeofence: true,
        geofenceId: "geofence-1",
        distanceMeters: 0,
        radiusMeters: 100
      });
      expect(state.audits).toHaveLength(0);
    });

    it("returns false for a location outside active geofences", async () => {
      const token = await login("employee@example.test");
      const response = await request(app)
        .post("/api/geofences/validate-location")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.05, longitude: 38.74 })
        .expect(200);

      expect(response.body.data).toMatchObject({
        isWithinGeofence: false,
        nearestGeofenceId: "geofence-1",
        radiusMeters: 100
      });
      expect(response.body.data.distanceMeters).toBeGreaterThan(100);
    });

    it("returns a safe no-active-geofence response", async () => {
      const token = await login("company3employee@example.test");
      const response = await request(app)
        .post("/api/geofences/validate-location")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74 })
        .expect(200);

      expect(response.body.data).toEqual({
        isWithinGeofence: false,
        reason: "NO_ACTIVE_GEOFENCE"
      });
    });

    it("blocks non-super-admin companyId overrides and allows SUPER_ADMIN explicit validation scope", async () => {
      const employeeToken = await login("employee@example.test");
      const superAdminToken = await login("superadmin@example.test");

      await request(app)
        .post("/api/geofences/validate-location")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ companyId: "company-2", latitude: 9.0301, longitude: 38.74 })
        .expect(403);

      const response = await request(app)
        .post("/api/geofences/validate-location")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .send({ companyId: "company-2", latitude: 9.0301, longitude: 38.74 })
        .expect(200);

      expect(response.body.data).toMatchObject({
        isWithinGeofence: true,
        geofenceId: "geofence-2"
      });
    });

    it("returns 401 for missing auth and 400 for invalid coordinates", async () => {
      const token = await login("employee@example.test");

      await request(app)
        .post("/api/geofences/validate-location")
        .send({ latitude: 9.0301, longitude: 38.74 })
        .expect(401);
      await request(app)
        .post("/api/geofences/validate-location")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: -91, longitude: 38.74 })
        .expect(400);
    });
  });
});
