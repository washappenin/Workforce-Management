import type {
  AuditActionCategory,
  CompanyStatus,
  DeviceSessionStatus,
  PaymentStatus,
  SubscriptionPlanType,
  SubscriptionStatus,
  UserStatus
} from "@prisma/client";
import request from "supertest";

import { app } from "../../src/app";
import type { AuditLogInput, AuditRepository } from "../../src/lib/audit";
import { resetAuditRepositoryForTests, setAuditRepositoryForTests } from "../../src/lib/audit";
import { hashPassword } from "../../src/lib/password";
import type { AuthDeviceSessionRecord, AuthRepository, AuthUserRecord } from "../../src/modules/auth/auth.repository";
import { resetAuthRepositoryForTests, setAuthRepositoryForTests } from "../../src/modules/auth/auth.repository";
import type {
  BillingCompanyRecord,
  CompanySubscriptionRecord,
  CreateCompanySubscriptionRepositoryInput,
  CreatePaymentRecordRepositoryInput,
  CreatePlanRepositoryInput,
  ListPaymentRecordsRepositoryFilters,
  ListPlansRepositoryFilters,
  ListSubscriptionsRepositoryFilters,
  PaymentRecordRecord,
  SubscriptionPlanRecord,
  SubscriptionsRepository,
  UpdateCompanySubscriptionRepositoryInput,
  UpdatePlanRepositoryInput
} from "../../src/modules/subscriptions/subscriptions.repository";
import {
  resetSubscriptionsRepositoryForTests,
  setSubscriptionsRepositoryForTests
} from "../../src/modules/subscriptions/subscriptions.repository";
import type { Role } from "../../src/types/auth";

interface MemoryState {
  companies: Map<string, BillingCompanyRecord>;
  users: Map<string, AuthUserRecord>;
  sessions: Map<string, AuthDeviceSessionRecord>;
  plans: Map<string, SubscriptionPlanRecord>;
  subscriptions: Map<string, CompanySubscriptionRecord>;
  payments: Map<string, PaymentRecordRecord>;
  audits: AuditLogInput[];
  counters: Record<string, number>;
}

const timestamp = () => new Date("2026-06-03T08:00:00.000Z");
const dateOnly = (value: string) => new Date(`${value}T00:00:00.000Z`);

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

const createState = (passwordHash: string): MemoryState => ({
  companies: new Map([
    ["company-1", { id: "company-1", name: "Demo Company", status: "ACTIVE" as CompanyStatus }],
    ["company-2", { id: "company-2", name: "Other Company", status: "ACTIVE" as CompanyStatus }]
  ]),
  users: new Map(
    [
      makeUser("user-super-admin", "superadmin@example.test", null, ["SUPER_ADMIN"], passwordHash),
      makeUser("user-company-admin", "companyadmin@example.test", "company-1", ["COMPANY_ADMIN"], passwordHash),
      makeUser("user-hr-admin", "hradmin@example.test", "company-1", ["HR_ADMIN"], passwordHash),
      makeUser("user-manager", "manager@example.test", "company-1", ["MANAGER"], passwordHash),
      makeUser("user-employee", "employee@example.test", "company-1", ["EMPLOYEE"], passwordHash)
    ].map((user) => [user.id, user])
  ),
  sessions: new Map(),
  plans: new Map(),
  subscriptions: new Map(),
  payments: new Map(),
  audits: [],
  counters: { session: 0, plan: 0, subscription: 0, payment: 0 }
});

const createRepositories = (state: MemoryState) => {
  const hydrateSubscription = (subscription: CompanySubscriptionRecord): CompanySubscriptionRecord => ({
    ...subscription,
    plan: state.plans.get(subscription.planId),
    company: state.companies.get(subscription.companyId)
  });

  const hydratePayment = (payment: PaymentRecordRecord): PaymentRecordRecord => ({
    ...payment,
    company: state.companies.get(payment.companyId),
    subscription: payment.subscriptionId ? hydrateSubscription(state.subscriptions.get(payment.subscriptionId)!) : null
  });

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

  const subscriptionsRepository: SubscriptionsRepository = {
    async findCompanyById(companyId) {
      return state.companies.get(companyId) ?? null;
    },

    async createPlan(input: CreatePlanRepositoryInput) {
      state.counters.plan += 1;
      const plan: SubscriptionPlanRecord = {
        id: `plan-${state.counters.plan}`,
        name: input.name,
        type: input.type,
        pricePerEmployee: input.pricePerEmployee,
        currency: input.currency,
        isActive: input.isActive ?? true,
        createdAt: timestamp(),
        updatedAt: timestamp()
      };

      state.plans.set(plan.id, plan);
      return plan;
    },

    async listPlans(filters: ListPlansRepositoryFilters) {
      return Array.from(state.plans.values()).filter(
        (plan) =>
          (filters.type === undefined || plan.type === filters.type) &&
          (filters.isActive === undefined || plan.isActive === filters.isActive)
      );
    },

    async findPlanById(planId) {
      return state.plans.get(planId) ?? null;
    },

    async findPlanByName(name) {
      return Array.from(state.plans.values()).find((plan) => plan.name === name) ?? null;
    },

    async updatePlan(planId, input: UpdatePlanRepositoryInput) {
      const current = state.plans.get(planId)!;
      const updated = { ...current, ...input, updatedAt: timestamp() };
      state.plans.set(planId, updated);
      return updated;
    },

    async updatePlanStatus(planId, isActive) {
      const current = state.plans.get(planId)!;
      const updated = { ...current, isActive, updatedAt: timestamp() };
      state.plans.set(planId, updated);
      return updated;
    },

    async createCompanySubscription(input: CreateCompanySubscriptionRepositoryInput) {
      state.counters.subscription += 1;
      const subscription: CompanySubscriptionRecord = {
        id: `subscription-${state.counters.subscription}`,
        companyId: input.companyId,
        planId: input.planId,
        status: input.status,
        startsAt: input.startsAt,
        endsAt: input.endsAt ?? null,
        createdAt: timestamp(),
        updatedAt: timestamp()
      };

      state.subscriptions.set(subscription.id, subscription);
      return hydrateSubscription(subscription);
    },

    async listSubscriptions(filters: ListSubscriptionsRepositoryFilters) {
      return Array.from(state.subscriptions.values())
        .filter(
          (subscription) =>
            (filters.companyId === undefined || subscription.companyId === filters.companyId) &&
            (filters.planId === undefined || subscription.planId === filters.planId) &&
            (filters.status === undefined || subscription.status === filters.status)
        )
        .map(hydrateSubscription);
    },

    async findSubscriptionById(subscriptionId) {
      const subscription = state.subscriptions.get(subscriptionId);
      return subscription ? hydrateSubscription(subscription) : null;
    },

    async findActiveSubscriptionForCompany(companyId) {
      const subscription = Array.from(state.subscriptions.values()).find(
        (record) => record.companyId === companyId && record.status === "ACTIVE"
      );
      return subscription ? hydrateSubscription(subscription) : null;
    },

    async findCurrentOrLatestSubscriptionForCompany(companyId) {
      const subscriptions = Array.from(state.subscriptions.values()).filter((subscription) => subscription.companyId === companyId);
      const active = subscriptions.find((subscription) => subscription.status === "ACTIVE");

      if (active) {
        return hydrateSubscription(active);
      }

      const latest = subscriptions.sort((left, right) => right.startsAt.getTime() - left.startsAt.getTime())[0];
      return latest ? hydrateSubscription(latest) : null;
    },

    async updateSubscriptionStatus(subscriptionId, input: UpdateCompanySubscriptionRepositoryInput) {
      const current = state.subscriptions.get(subscriptionId)!;
      const updated = {
        ...current,
        status: input.status,
        endsAt: input.endsAt === undefined ? current.endsAt : input.endsAt,
        updatedAt: timestamp()
      };
      state.subscriptions.set(subscriptionId, updated);
      return hydrateSubscription(updated);
    },

    async createPaymentRecord(input: CreatePaymentRecordRepositoryInput) {
      state.counters.payment += 1;
      const paymentRecord: PaymentRecordRecord = {
        id: `payment-${state.counters.payment}`,
        companyId: input.companyId,
        subscriptionId: input.subscriptionId ?? null,
        amount: input.amount,
        currency: input.currency,
        status: input.status,
        provider: input.provider ?? null,
        providerReference: input.providerReference ?? null,
        paidAt: input.paidAt ?? null,
        createdAt: timestamp(),
        updatedAt: timestamp()
      };

      state.payments.set(paymentRecord.id, paymentRecord);
      return hydratePayment(paymentRecord);
    },

    async listPaymentRecords(filters: ListPaymentRecordsRepositoryFilters) {
      return Array.from(state.payments.values())
        .filter(
          (payment) =>
            (filters.companyId === undefined || payment.companyId === filters.companyId) &&
            (filters.status === undefined || payment.status === filters.status) &&
            (filters.provider === undefined || payment.provider === filters.provider) &&
            (!filters.from || Boolean(payment.paidAt && payment.paidAt >= filters.from)) &&
            (!filters.to || Boolean(payment.paidAt && payment.paidAt <= filters.to))
        )
        .map(hydratePayment);
    }
  };

  const auditRepository: AuditRepository = {
    async create(input) {
      state.audits.push(input);
    }
  };

  return { authRepository, subscriptionsRepository, auditRepository };
};

describe("CP15 subscriptions and billing", () => {
  let passwordHash: string;
  let state: MemoryState;

  beforeAll(async () => {
    passwordHash = await hashPassword("Password123!");
  });

  beforeEach(() => {
    state = createState(passwordHash);
    const repositories = createRepositories(state);

    setAuthRepositoryForTests(repositories.authRepository);
    setSubscriptionsRepositoryForTests(repositories.subscriptionsRepository);
    setAuditRepositoryForTests(repositories.auditRepository);
  });

  afterEach(() => {
    resetAuthRepositoryForTests();
    resetSubscriptionsRepositoryForTests();
    resetAuditRepositoryForTests();
  });

  const login = async (email: string) => {
    const response = await request(app).post("/api/auth/login").send({ email, password: "Password123!" }).expect(200);

    return response.body.data.accessToken as string;
  };

  const createPlan = async (token: string, name = "Basic", type: SubscriptionPlanType = "BASIC") => {
    const response = await request(app)
      .post("/api/super-admin/plans")
      .set("Authorization", `Bearer ${token}`)
      .send({ name, type, pricePerEmployee: type === "BASIC" ? 120 : 250, currency: "ETB" })
      .expect(201);

    return response.body.data.plan as SubscriptionPlanRecord;
  };

  const createSubscription = async (token: string, companyId: string, planId: string, status: SubscriptionStatus = "ACTIVE") => {
    const response = await request(app)
      .post(`/api/super-admin/companies/${companyId}/subscription`)
      .set("Authorization", `Bearer ${token}`)
      .send({ planId, startsAt: "2026-06-01", endsAt: null, status })
      .expect(201);

    return response.body.data.subscription as CompanySubscriptionRecord;
  };

  const auditActions = (category?: AuditActionCategory) =>
    state.audits.filter((audit) => !category || audit.category === category).map((audit) => audit.action);

  it("allows only SUPER_ADMIN to manage Basic and Premium plans", async () => {
    const superAdminToken = await login("superadmin@example.test");
    const companyAdminToken = await login("companyadmin@example.test");
    const hrAdminToken = await login("hradmin@example.test");
    const employeeToken = await login("employee@example.test");

    const basicPlan = await createPlan(superAdminToken, "Basic", "BASIC");
    const premiumPlan = await createPlan(superAdminToken, "Premium", "PREMIUM");

    await request(app)
      .post("/api/super-admin/plans")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .send({ name: "Blocked Company", type: "BASIC", pricePerEmployee: 120, currency: "ETB" })
      .expect(403);
    await request(app)
      .post("/api/super-admin/plans")
      .set("Authorization", `Bearer ${hrAdminToken}`)
      .send({ name: "Blocked HR", type: "BASIC", pricePerEmployee: 120, currency: "ETB" })
      .expect(403);
    await request(app)
      .post("/api/super-admin/plans")
      .set("Authorization", `Bearer ${employeeToken}`)
      .send({ name: "Blocked Employee", type: "BASIC", pricePerEmployee: 120, currency: "ETB" })
      .expect(403);

    await request(app)
      .post("/api/super-admin/plans")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ name: "Bad Price", type: "BASIC", pricePerEmployee: -1, currency: "ETB" })
      .expect(400);
    await request(app)
      .post("/api/super-admin/plans")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ name: "Bad Currency", type: "BASIC", pricePerEmployee: 120, currency: "etb" })
      .expect(400);
    await request(app)
      .post("/api/super-admin/plans")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ name: "Bad Type", type: "ENTERPRISE", pricePerEmployee: 120, currency: "ETB" })
      .expect(400);

    const listResponse = await request(app)
      .get("/api/super-admin/plans?isActive=true&type=BASIC")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .expect(200);
    const getResponse = await request(app)
      .get(`/api/super-admin/plans/${basicPlan.id}`)
      .set("Authorization", `Bearer ${superAdminToken}`)
      .expect(200);
    const updateResponse = await request(app)
      .patch(`/api/super-admin/plans/${premiumPlan.id}`)
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ pricePerEmployee: 275, currency: "ETB" })
      .expect(200);
    const statusResponse = await request(app)
      .patch(`/api/super-admin/plans/${premiumPlan.id}/status`)
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ isActive: false })
      .expect(200);

    expect(listResponse.body.data.plans).toHaveLength(1);
    expect(getResponse.body.data.plan).toMatchObject({ id: basicPlan.id, name: "Basic", type: "BASIC" });
    expect(updateResponse.body.data.plan.pricePerEmployee).toBe(275);
    expect(statusResponse.body.data.plan.isActive).toBe(false);
    expect(auditActions("SUBSCRIPTION")).toEqual([
      "SUBSCRIPTION_PLAN_CREATED",
      "SUBSCRIPTION_PLAN_CREATED",
      "SUBSCRIPTION_PLAN_UPDATED",
      "SUBSCRIPTION_PLAN_STATUS_CHANGED"
    ]);
  });

  it("manages company subscriptions and rejects inactive plans, missing companies, active overlaps, and wrong roles", async () => {
    const superAdminToken = await login("superadmin@example.test");
    const companyAdminToken = await login("companyadmin@example.test");
    const basicPlan = await createPlan(superAdminToken);
    const premiumPlan = await createPlan(superAdminToken, "Premium", "PREMIUM");

    await request(app)
      .patch(`/api/super-admin/plans/${premiumPlan.id}/status`)
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ isActive: false })
      .expect(200);

    const subscription = await createSubscription(superAdminToken, "company-1", basicPlan.id);

    await request(app)
      .post("/api/super-admin/companies/company-2/subscription")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ planId: premiumPlan.id, startsAt: "2026-06-01", status: "ACTIVE" })
      .expect(400);
    await request(app)
      .post("/api/super-admin/companies/missing-company/subscription")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ planId: basicPlan.id, startsAt: "2026-06-01", status: "ACTIVE" })
      .expect(404);
    await request(app)
      .post("/api/super-admin/companies/company-1/subscription")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ planId: basicPlan.id, startsAt: "2026-07-01", status: "ACTIVE" })
      .expect(400)
      .expect((response) => expect(response.body.error.code).toBe("ACTIVE_SUBSCRIPTION_EXISTS"));

    const listResponse = await request(app)
      .get("/api/super-admin/subscriptions?companyId=company-1&status=ACTIVE")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .expect(200);
    const detailResponse = await request(app)
      .get("/api/super-admin/companies/company-1/subscription")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .expect(200);
    const updateResponse = await request(app)
      .patch(`/api/super-admin/subscriptions/${subscription.id}/status`)
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ status: "CANCELLED", endsAt: "2026-12-31" })
      .expect(200);

    await request(app)
      .get("/api/super-admin/subscriptions")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(403);

    expect(listResponse.body.data.subscriptions).toHaveLength(1);
    expect(detailResponse.body.data.subscription).toMatchObject({ id: subscription.id, companyId: "company-1", planId: basicPlan.id });
    expect(updateResponse.body.data.subscription).toMatchObject({ id: subscription.id, status: "CANCELLED" });
    expect(auditActions("SUBSCRIPTION")).toEqual([
      "SUBSCRIPTION_PLAN_CREATED",
      "SUBSCRIPTION_PLAN_CREATED",
      "SUBSCRIPTION_PLAN_STATUS_CHANGED",
      "COMPANY_SUBSCRIPTION_CREATED",
      "COMPANY_SUBSCRIPTION_STATUS_CHANGED"
    ]);
  });

  it("creates and lists manual payment records without audit logging provider references", async () => {
    const superAdminToken = await login("superadmin@example.test");
    const companyAdminToken = await login("companyadmin@example.test");
    const plan = await createPlan(superAdminToken);
    const subscription = await createSubscription(superAdminToken, "company-1", plan.id);

    const paymentResponse = await request(app)
      .post("/api/super-admin/payment-records")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({
        companyId: "company-1",
        subscriptionId: subscription.id,
        amount: 5000,
        currency: "ETB",
        status: "PAID",
        provider: "manual",
        providerReference: "receipt-001",
        paidAt: "2026-06-01T12:00:00.000Z"
      })
      .expect(201);

    await request(app)
      .post("/api/super-admin/payment-records")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ companyId: "company-2", subscriptionId: subscription.id, amount: 100, currency: "ETB", status: "PAID" })
      .expect(400);
    await request(app)
      .post("/api/super-admin/payment-records")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ companyId: "company-1", amount: -1, currency: "ETB", status: "PAID" })
      .expect(400);
    await request(app)
      .post("/api/super-admin/payment-records")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ companyId: "company-1", amount: 100, currency: "ETB", status: "SETTLED" })
      .expect(400);
    await request(app)
      .post("/api/super-admin/payment-records")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({ companyId: "company-1", amount: 100, currency: "usd", status: "PAID" })
      .expect(400);

    const allPaymentsResponse = await request(app)
      .get("/api/super-admin/payment-records?companyId=company-1&status=PAID&provider=manual&from=2026-06-01&to=2026-06-30")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .expect(200);
    const companyPaymentsResponse = await request(app)
      .get("/api/super-admin/companies/company-1/payment-records")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .expect(200);

    await request(app)
      .get("/api/super-admin/payment-records")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(403);

    expect(paymentResponse.body.data.paymentRecord).toMatchObject({
      companyId: "company-1",
      subscriptionId: subscription.id,
      amount: 5000,
      providerReference: "receipt-001"
    });
    expect(allPaymentsResponse.body.data.paymentRecords).toHaveLength(1);
    expect(companyPaymentsResponse.body.data.paymentRecords).toHaveLength(1);
    expect(auditActions("PAYMENT")).toEqual(["PAYMENT_RECORD_CREATED"]);
    expect(JSON.stringify(state.audits)).not.toContain("receipt-001");
  });

  it("allows company admins and HR admins to view only their own subscription and sanitized payment records", async () => {
    const superAdminToken = await login("superadmin@example.test");
    const companyAdminToken = await login("companyadmin@example.test");
    const hrAdminToken = await login("hradmin@example.test");
    const managerToken = await login("manager@example.test");
    const employeeToken = await login("employee@example.test");
    const plan = await createPlan(superAdminToken);
    const subscription = await createSubscription(superAdminToken, "company-1", plan.id);

    await request(app)
      .post("/api/super-admin/payment-records")
      .set("Authorization", `Bearer ${superAdminToken}`)
      .send({
        companyId: "company-1",
        subscriptionId: subscription.id,
        amount: 5000,
        currency: "ETB",
        status: "PAID" as PaymentStatus,
        provider: "manual",
        providerReference: "receipt-secret",
        paidAt: "2026-06-01T12:00:00.000Z"
      })
      .expect(201);

    const companyAdminSubscriptionResponse = await request(app)
      .get("/api/admin/subscription")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(200);
    const hrSubscriptionResponse = await request(app)
      .get("/api/admin/subscription")
      .set("Authorization", `Bearer ${hrAdminToken}`)
      .expect(200);
    const companyAdminPaymentsResponse = await request(app)
      .get("/api/admin/payment-records")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(200);
    const hrPaymentsResponse = await request(app)
      .get("/api/admin/payment-records")
      .set("Authorization", `Bearer ${hrAdminToken}`)
      .expect(200);

    await request(app).get("/api/admin/subscription").set("Authorization", `Bearer ${managerToken}`).expect(403);
    await request(app).get("/api/admin/payment-records").set("Authorization", `Bearer ${employeeToken}`).expect(403);
    await request(app)
      .get("/api/admin/subscription?companyId=company-2")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(403);
    await request(app)
      .get("/api/admin/payment-records?companyId=company-2")
      .set("Authorization", `Bearer ${companyAdminToken}`)
      .expect(403);

    expect(companyAdminSubscriptionResponse.body.data.subscription).toMatchObject({ id: subscription.id, companyId: "company-1" });
    expect(hrSubscriptionResponse.body.data.subscription).toMatchObject({ id: subscription.id, companyId: "company-1" });
    expect(companyAdminPaymentsResponse.body.data.paymentRecords).toHaveLength(1);
    expect(hrPaymentsResponse.body.data.paymentRecords).toHaveLength(1);
    expect(companyAdminPaymentsResponse.body.data.paymentRecords[0]).not.toHaveProperty("providerReference");
    expect(hrPaymentsResponse.body.data.paymentRecords[0]).not.toHaveProperty("providerReference");
  });
});
