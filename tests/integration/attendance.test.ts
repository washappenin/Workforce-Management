import type {
  AttendanceEventType,
  AttendanceStatus,
  CompanyStatus,
  DeviceSessionStatus,
  EmployeeStatus,
  UserStatus
} from "@prisma/client";
import request from "supertest";

import { app } from "../../src/app";
import {
  resetFaceVerificationReferencesForTests,
  setFaceVerificationReferenceForTests
} from "../../src/lib/faceMatch";
import { hashPassword } from "../../src/lib/password";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";
import type {
  AttendanceEmployeeProfile,
  AttendanceEventRecord,
  AttendanceGeofenceRecord,
  AttendanceListFilters,
  AttendanceRepository,
  AttendanceSessionRecord,
  CloseAttendanceSessionInput,
  CreateAttendanceEventInput,
  CreateClockInSessionInput
} from "../../src/modules/attendance/attendance.repository";
import { resetAttendanceRepositoryForTests, setAttendanceRepositoryForTests } from "../../src/modules/attendance/attendance.repository";
import type { Role } from "../../src/types/auth";

interface StoredSession extends AttendanceSessionRecord {
  clockInLatitude: number;
  clockInLongitude: number;
  clockOutLatitude: number | null;
  clockOutLongitude: number | null;
}

interface MemoryState {
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  companies: Map<string, { id: string; status: CompanyStatus }>;
  employees: Map<string, AttendanceEmployeeProfile>;
  geofences: Map<string, AttendanceGeofenceRecord & { status: "ACTIVE" | "INACTIVE" | "ARCHIVED" }>;
  attendanceSessions: Map<string, StoredSession>;
  attendanceEvents: AttendanceEventRecord[];
  counters: Record<string, number>;
}

const now = () => new Date("2026-06-03T08:00:00.000Z");

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

const makeEmployeeProfile = (
  id: string,
  companyId: string,
  userId: string,
  status: EmployeeStatus = "ACTIVE"
): AttendanceEmployeeProfile => ({
  id,
  companyId,
  userId,
  status,
  companyStatus: "ACTIVE" as CompanyStatus
});

const makeGeofence = (
  id: string,
  companyId: string,
  status: "ACTIVE" | "INACTIVE" | "ARCHIVED" = "ACTIVE"
): AttendanceGeofenceRecord & { status: "ACTIVE" | "INACTIVE" | "ARCHIVED" } => ({
  id,
  companyId,
  latitude: 9.0301,
  longitude: 38.74,
  radiusMeters: 100,
  status
});

const makeSession = (
  id: string,
  companyId: string,
  employeeId: string,
  status: AttendanceStatus,
  clockInAt: Date
): StoredSession => ({
  id,
  companyId,
  employeeId,
  clockInAt,
  clockOutAt: status === "CLOSED" ? new Date(clockInAt.getTime() + 8 * 60 * 60 * 1000) : null,
  status,
  clockInFaceVerified: false,
  clockInGeofenceId: "geofence-1",
  clockOutGeofenceId: status === "CLOSED" ? "geofence-1" : null,
  createdAt: clockInAt,
  updatedAt: clockInAt,
  clockInLatitude: 9.0301,
  clockInLongitude: 38.74,
  clockOutLatitude: status === "CLOSED" ? 9.0301 : null,
  clockOutLongitude: status === "CLOSED" ? 38.74 : null
});

const createState = (passwordHash: string): MemoryState => {
  const users = [
    makeUser("user-super-admin", "superadmin@example.test", null, ["SUPER_ADMIN"], passwordHash),
    makeUser("user-company-admin", "companyadmin@example.test", "company-1", ["COMPANY_ADMIN"], passwordHash),
    makeUser("user-hr-admin", "hradmin@example.test", "company-1", ["HR_ADMIN"], passwordHash),
    makeUser("user-manager", "manager@example.test", "company-1", ["MANAGER"], passwordHash),
    makeUser("user-employee", "employee@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-noprofile", "noprofile@example.test", "company-1", ["EMPLOYEE"], passwordHash),
    makeUser("user-company2-employee", "company2employee@example.test", "company-2", ["EMPLOYEE"], passwordHash),
    makeUser("user-company3-employee", "company3employee@example.test", "company-3", ["EMPLOYEE"], passwordHash)
  ];

  const employees = [
    makeEmployeeProfile("employee-company-admin", "company-1", "user-company-admin"),
    makeEmployeeProfile("employee-hr-admin", "company-1", "user-hr-admin"),
    makeEmployeeProfile("employee-manager", "company-1", "user-manager"),
    makeEmployeeProfile("employee-self", "company-1", "user-employee"),
    makeEmployeeProfile("employee-company2", "company-2", "user-company2-employee"),
    makeEmployeeProfile("employee-company3", "company-3", "user-company3-employee")
  ];

  return {
    users: new Map(users.map((user) => [user.id, user])),
    sessions: new Map(),
    companies: new Map([
      ["company-1", { id: "company-1", status: "ACTIVE" as CompanyStatus }],
      ["company-2", { id: "company-2", status: "ACTIVE" as CompanyStatus }],
      ["company-3", { id: "company-3", status: "ACTIVE" as CompanyStatus }]
    ]),
    employees: new Map(employees.map((employee) => [employee.id, employee])),
    geofences: new Map([
      ["geofence-1", makeGeofence("geofence-1", "company-1")],
      ["geofence-2", makeGeofence("geofence-2", "company-2")]
    ]),
    attendanceSessions: new Map([
      [
        "session-company2-closed",
        makeSession("session-company2-closed", "company-2", "employee-company2", "CLOSED", new Date("2026-06-02T08:00:00.000Z"))
      ]
    ]),
    attendanceEvents: [],
    counters: {
      authSession: 0,
      attendanceSession: 0,
      attendanceEvent: 0
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
      state.counters.authSession += 1;
      const session = {
        id: `auth-session-${state.counters.authSession}`,
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

  const attendanceRepository: AttendanceRepository = {
    async findEmployeeProfileByUserId(userId) {
      const employee = Array.from(state.employees.values()).find((candidate) => candidate.userId === userId);
      const company = employee ? state.companies.get(employee.companyId) : null;

      return employee && company ? { ...employee, companyStatus: company.status } : null;
    },

    async verifyEmployeeBelongsToCompany(employeeId, companyId) {
      const employee = state.employees.get(employeeId);
      return employee?.companyId === companyId;
    },

    async findOpenSessionByEmployeeId(employeeId) {
      return (
        Array.from(state.attendanceSessions.values()).find(
          (session) => session.employeeId === employeeId && session.status === "OPEN"
        ) ?? null
      );
    },

    async findActiveGeofencesForCompany(companyId) {
      return Array.from(state.geofences.values()).filter(
        (geofence) => geofence.companyId === companyId && geofence.status === "ACTIVE"
      );
    },

    async createClockInSession(input: CreateClockInSessionInput) {
      state.counters.attendanceSession += 1;
      const session: StoredSession = {
        id: `attendance-session-${state.counters.attendanceSession}`,
        companyId: input.companyId,
        employeeId: input.employeeId,
        clockInAt: input.clockInAt,
        clockOutAt: null,
        status: "OPEN",
        clockInFaceVerified: input.clockInFaceVerified,
        clockInGeofenceId: input.geofenceId,
        clockOutGeofenceId: null,
        createdAt: input.clockInAt,
        updatedAt: input.clockInAt,
        clockInLatitude: input.latitude,
        clockInLongitude: input.longitude,
        clockOutLatitude: null,
        clockOutLongitude: null
      };

      state.attendanceSessions.set(session.id, session);
      return session;
    },

    async closeAttendanceSession(input: CloseAttendanceSessionInput) {
      const current = state.attendanceSessions.get(input.sessionId)!;
      const updated: StoredSession = {
        ...current,
        clockOutAt: input.clockOutAt,
        clockOutLatitude: input.latitude,
        clockOutLongitude: input.longitude,
        clockOutGeofenceId: input.geofenceId,
        status: "CLOSED",
        updatedAt: input.clockOutAt
      };

      state.attendanceSessions.set(updated.id, updated);
      return updated;
    },

    async createAttendanceEvent(input: CreateAttendanceEventInput) {
      state.counters.attendanceEvent += 1;
      const event: AttendanceEventRecord = {
        id: `attendance-event-${state.counters.attendanceEvent}`,
        companyId: input.companyId,
        employeeId: input.employeeId,
        attendanceSessionId: input.attendanceSessionId,
        type: input.type,
        createdAt: now()
      };

      state.attendanceEvents.push(event);
      return event;
    },

    async listMyAttendance(employeeId, filters: AttendanceListFilters) {
      return Array.from(state.attendanceSessions.values()).filter(
        (session) =>
          session.employeeId === employeeId &&
          (!filters.from || session.clockInAt >= filters.from) &&
          (!filters.to || session.clockInAt <= filters.to)
      );
    },

    async listCompanyAttendance(companyId, filters: AttendanceListFilters) {
      return Array.from(state.attendanceSessions.values()).filter(
        (session) =>
          session.companyId === companyId &&
          (!filters.employeeId || session.employeeId === filters.employeeId) &&
          (!filters.status || session.status === filters.status) &&
          (!filters.from || session.clockInAt >= filters.from) &&
          (!filters.to || session.clockInAt <= filters.to)
      );
    }
  };

  return { authRepository, attendanceRepository };
};

describe("CP7 attendance clock-in and clock-out", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setAttendanceRepositoryForTests(repositories.attendanceRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetAttendanceRepositoryForTests();
    resetFaceVerificationReferencesForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const setFaceReference = (reference = "face-ref", employeeId = "employee-self") => {
    setFaceVerificationReferenceForTests({
      reference,
      employeeId,
      provider: "mock",
      expiresAt: new Date(Date.now() + 60_000)
    });
  };

  describe("clock-in", () => {
    it("allows an employee to clock in inside an active geofence and creates a session/event", async () => {
      const token = await login("employee@example.test");
      setFaceReference();
      const response = await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74, accuracyMeters: 12.5, faceVerificationReference: "face-ref" })
        .expect(201);

      expect(response.body.data.attendanceSession).toMatchObject({
        employeeId: "employee-self",
        status: "OPEN",
        clockInGeofenceId: "geofence-1",
        clockInFaceVerified: true
      });
      expect(response.body.data.geofence).toEqual({
        id: "geofence-1",
        distanceMeters: 0,
        radiusMeters: 100
      });
      expect(JSON.stringify(response.body)).not.toContain("passwordHash");
      expect(state.attendanceSessions.size).toBe(2);
      expect(state.attendanceEvents).toEqual([
        expect.objectContaining({
          type: "CLOCK_IN" as AttendanceEventType,
          employeeId: "employee-self"
        })
      ]);
    });

    it("requires a valid single-use face verification reference for clock-in", async () => {
      const token = await login("employee@example.test");

      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74 })
        .expect(400);
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "missing-ref" })
        .expect(400);

      setFaceVerificationReferenceForTests({
        reference: "expired-ref",
        employeeId: "employee-self",
        provider: "mock",
        expiresAt: new Date(Date.now() - 1_000)
      });
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "expired-ref" })
        .expect(400);

      setFaceReference("different-employee-ref", "employee-company2");
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "different-employee-ref" })
        .expect(400);

      setFaceReference("single-use-ref");
      const response = await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "single-use-ref" })
        .expect(201);

      expect(response.body.data.attendanceSession.clockInFaceVerified).toBe(true);

      const openSession = Array.from(state.attendanceSessions.values()).find(
        (session) => session.employeeId === "employee-self" && session.status === "OPEN"
      );
      state.attendanceSessions.set(openSession!.id, {
        ...openSession!,
        status: "CLOSED" as AttendanceStatus,
        clockOutAt: now()
      });

      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "single-use-ref" })
        .expect(400);
    });

    it("rejects outside geofence, no active geofence, invalid coordinates, duplicate open session, no profile, and missing auth", async () => {
      const employeeToken = await login("employee@example.test");
      const company3Token = await login("company3employee@example.test");
      const noProfileToken = await login("noprofile@example.test");

      setFaceReference("outside-ref");
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ latitude: 9.05, longitude: 38.74, faceVerificationReference: "outside-ref" })
        .expect(400);
      setFaceReference("company3-ref", "employee-company3");
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${company3Token}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "company3-ref" })
        .expect(400);
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ latitude: 91, longitude: 38.74, faceVerificationReference: "invalid-coordinates-ref" })
        .expect(400);

      setFaceReference("valid-ref");
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "valid-ref" })
        .expect(201);
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${employeeToken}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "valid-ref" })
        .expect(400);
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${noProfileToken}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "no-profile-ref" })
        .expect(403);
      await request(app)
        .post("/api/attendance/clock-in")
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "missing-auth-ref" })
        .expect(401);
    });
  });

  describe("clock-out", () => {
    it("allows an employee to clock out after clocking in and creates a clock-out event", async () => {
      const token = await login("employee@example.test");

      setFaceReference();
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "face-ref" })
        .expect(201);

      const response = await request(app)
        .post("/api/attendance/clock-out")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74, accuracyMeters: 10 })
        .expect(200);

      expect(response.body.data.attendanceSession).toMatchObject({
        status: "CLOSED",
        employeeId: "employee-self",
        clockOutGeofenceId: "geofence-1"
      });
      expect(state.attendanceEvents.map((event) => event.type)).toEqual(["CLOCK_IN", "CLOCK_OUT"]);
    });

    it("rejects clock-out without an open session, outside geofence, and missing auth", async () => {
      const token = await login("employee@example.test");

      await request(app)
        .post("/api/attendance/clock-out")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74 })
        .expect(400);

      setFaceReference();
      await request(app)
        .post("/api/attendance/clock-in")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.0301, longitude: 38.74, faceVerificationReference: "face-ref" })
        .expect(201);

      await request(app)
        .post("/api/attendance/clock-out")
        .set("Authorization", `Bearer ${token}`)
        .send({ latitude: 9.05, longitude: 38.74 })
        .expect(400);
      await request(app).post("/api/attendance/clock-out").send({ latitude: 9.0301, longitude: 38.74 }).expect(401);
    });
  });

  describe("attendance lists", () => {
    beforeEach(() => {
      state.attendanceSessions.set(
        "session-self-old",
        makeSession("session-self-old", "company-1", "employee-self", "CLOSED", new Date("2026-05-01T08:00:00.000Z"))
      );
      state.attendanceSessions.set(
        "session-self-current",
        makeSession("session-self-current", "company-1", "employee-self", "CLOSED", new Date("2026-06-02T08:00:00.000Z"))
      );
      state.attendanceSessions.set(
        "session-manager-current",
        makeSession("session-manager-current", "company-1", "employee-manager", "CLOSED", new Date("2026-06-02T08:00:00.000Z"))
      );
    });

    it("allows an employee to list only their own attendance and use date filters", async () => {
      const token = await login("employee@example.test");

      const response = await request(app).get("/api/attendance/me").set("Authorization", `Bearer ${token}`).expect(200);
      const filteredResponse = await request(app)
        .get("/api/attendance/me?from=2026-06-01T00:00:00.000Z&to=2026-06-30T23:59:59.000Z")
        .set("Authorization", `Bearer ${token}`)
        .expect(200);

      expect(response.body.data.attendanceSessions.map((session: { employeeId: string }) => session.employeeId)).toEqual([
        "employee-self",
        "employee-self"
      ]);
      expect(JSON.stringify(response.body)).not.toContain("employee-manager");
      expect(filteredResponse.body.data.attendanceSessions).toHaveLength(1);
    });

    it("allows COMPANY_ADMIN, HR_ADMIN, and scoped SUPER_ADMIN to list company attendance", async () => {
      const companyAdminToken = await login("companyadmin@example.test");
      const hrAdminToken = await login("hradmin@example.test");
      const superAdminToken = await login("superadmin@example.test");

      const companyAdminResponse = await request(app)
        .get("/api/admin/attendance")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(200);
      const hrAdminResponse = await request(app).get("/api/admin/attendance").set("Authorization", `Bearer ${hrAdminToken}`).expect(200);
      const superAdminResponse = await request(app)
        .get("/api/admin/attendance?companyId=company-2")
        .set("Authorization", `Bearer ${superAdminToken}`)
        .expect(200);

      expect(companyAdminResponse.body.data.attendanceSessions).toHaveLength(3);
      expect(hrAdminResponse.body.data.attendanceSessions).toHaveLength(3);
      expect(superAdminResponse.body.data.attendanceSessions).toHaveLength(1);
    });

    it("rejects employee admin access, cross-company employee filters, and non-super companyId overrides", async () => {
      const employeeToken = await login("employee@example.test");
      const companyAdminToken = await login("companyadmin@example.test");

      await request(app).get("/api/admin/attendance").set("Authorization", `Bearer ${employeeToken}`).expect(403);
      await request(app)
        .get("/api/admin/attendance?employeeId=employee-company2")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(403);
      await request(app)
        .get("/api/admin/attendance?companyId=company-2")
        .set("Authorization", `Bearer ${companyAdminToken}`)
        .expect(403);
    });
  });
});
