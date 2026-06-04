import { AppError, AuthorizationError, ConflictError, NotFoundError, ValidationError } from "../../lib/errors";
import { getRequiredScopedCompanyId, hasAnyRole, isSuperAdmin } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getSubscriptionsRepository,
  type CompanySubscriptionRecord,
  type PaymentRecordRecord,
  type SubscriptionPlanRecord
} from "./subscriptions.repository";
import type {
  AdminBillingQuery,
  CompanyPaymentRecordsQuery,
  CreateCompanySubscriptionInput,
  CreatePaymentRecordInput,
  CreateSubscriptionPlanInput,
  ListPaymentRecordsQuery,
  ListSubscriptionPlansQuery,
  ListSubscriptionsQuery,
  UpdateCompanySubscriptionStatusInput,
  UpdateSubscriptionPlanInput,
  UpdateSubscriptionPlanStatusInput
} from "./subscriptions.validation";

const activeSubscriptionExistsError = () =>
  new AppError({
    code: "ACTIVE_SUBSCRIPTION_EXISTS",
    message: "Company already has an active subscription",
    statusCode: 400
  });

const assertSuperAdmin = (actor: AuthenticatedUser) => {
  if (!isSuperAdmin(actor)) {
    throw new AuthorizationError();
  }
};

const assertCompanyBillingViewer = (actor: AuthenticatedUser) => {
  if (!hasAnyRole(actor, ["COMPANY_ADMIN", "HR_ADMIN"])) {
    throw new AuthorizationError();
  }
};

const assertCompanyExists = async (companyId: string) => {
  const company = await getSubscriptionsRepository().findCompanyById(companyId);

  if (!company) {
    throw new NotFoundError("Company not found");
  }

  return company;
};

const assertPlanExists = async (planId: string) => {
  const plan = await getSubscriptionsRepository().findPlanById(planId);

  if (!plan) {
    throw new NotFoundError("Subscription plan not found");
  }

  return plan;
};

const assertSubscriptionExists = async (subscriptionId: string) => {
  const subscription = await getSubscriptionsRepository().findSubscriptionById(subscriptionId);

  if (!subscription) {
    throw new NotFoundError("Company subscription not found");
  }

  return subscription;
};

const serializePlan = (plan: SubscriptionPlanRecord) => ({
  id: plan.id,
  name: plan.name,
  type: plan.type,
  pricePerEmployee: plan.pricePerEmployee,
  currency: plan.currency,
  isActive: plan.isActive,
  createdAt: plan.createdAt,
  updatedAt: plan.updatedAt
});

const serializeSubscription = (subscription: CompanySubscriptionRecord | null) =>
  subscription
    ? {
        id: subscription.id,
        companyId: subscription.companyId,
        planId: subscription.planId,
        status: subscription.status,
        startsAt: subscription.startsAt,
        endsAt: subscription.endsAt,
        createdAt: subscription.createdAt,
        updatedAt: subscription.updatedAt,
        ...(subscription.plan ? { plan: serializePlan(subscription.plan) } : {}),
        ...(subscription.company ? { company: subscription.company } : {})
      }
    : null;

const serializePaymentRecord = (payment: PaymentRecordRecord, options: { includeProviderReference: boolean }) => ({
  id: payment.id,
  companyId: payment.companyId,
  subscriptionId: payment.subscriptionId,
  amount: payment.amount,
  currency: payment.currency,
  status: payment.status,
  provider: payment.provider,
  ...(options.includeProviderReference ? { providerReference: payment.providerReference } : {}),
  paidAt: payment.paidAt,
  createdAt: payment.createdAt,
  updatedAt: payment.updatedAt,
  ...(payment.company ? { company: payment.company } : {}),
  ...(payment.subscription !== undefined ? { subscription: serializeSubscription(payment.subscription) } : {})
});

const validateUniquePlanName = async (name: string, currentPlanId?: string) => {
  const existing = await getSubscriptionsRepository().findPlanByName(name);

  if (existing && existing.id !== currentPlanId) {
    throw new ConflictError("Subscription plan name already exists");
  }
};

const validatePlanFilter = async (planId?: string) => {
  if (planId) {
    await assertPlanExists(planId);
  }
};

const validateSubscriptionEndDate = (subscription: CompanySubscriptionRecord, endsAt?: Date | null) => {
  if (endsAt && endsAt < subscription.startsAt) {
    throw new ValidationError("endsAt cannot be before startsAt", undefined, 400);
  }
};

const validateNoOtherActiveSubscription = async (companyId: string, currentSubscriptionId?: string) => {
  const activeSubscription = await getSubscriptionsRepository().findActiveSubscriptionForCompany(companyId);

  if (activeSubscription && activeSubscription.id !== currentSubscriptionId) {
    throw activeSubscriptionExistsError();
  }
};

const getAdminBillingCompanyId = (actor: AuthenticatedUser, query: AdminBillingQuery) => {
  assertCompanyBillingViewer(actor);

  return getRequiredScopedCompanyId(actor, query.companyId);
};

export const createSubscriptionPlan = async (
  actor: AuthenticatedUser,
  input: CreateSubscriptionPlanInput,
  auditContext: AuditRequestContext
) => {
  assertSuperAdmin(actor);
  await validateUniquePlanName(input.name);

  const plan = await getSubscriptionsRepository().createPlan(input);

  await recordAuditLog({
    companyId: null,
    actorUserId: actor.id,
    category: "SUBSCRIPTION",
    action: "SUBSCRIPTION_PLAN_CREATED",
    targetType: "SubscriptionPlan",
    targetId: plan.id,
    metadata: {
      name: plan.name,
      type: plan.type,
      pricePerEmployee: plan.pricePerEmployee,
      currency: plan.currency,
      isActive: plan.isActive
    },
    ...auditContext
  });

  return serializePlan(plan);
};

export const listSubscriptionPlans = async (actor: AuthenticatedUser, query: ListSubscriptionPlansQuery) => {
  assertSuperAdmin(actor);

  const plans = await getSubscriptionsRepository().listPlans(query);
  return plans.map(serializePlan);
};

export const getSubscriptionPlan = async (actor: AuthenticatedUser, planId: string) => {
  assertSuperAdmin(actor);

  return serializePlan(await assertPlanExists(planId));
};

export const updateSubscriptionPlan = async (
  actor: AuthenticatedUser,
  planId: string,
  input: UpdateSubscriptionPlanInput,
  auditContext: AuditRequestContext
) => {
  assertSuperAdmin(actor);
  const current = await assertPlanExists(planId);

  if (input.name && input.name !== current.name) {
    await validateUniquePlanName(input.name, planId);
  }

  const plan = await getSubscriptionsRepository().updatePlan(planId, input);

  await recordAuditLog({
    companyId: null,
    actorUserId: actor.id,
    category: "SUBSCRIPTION",
    action: "SUBSCRIPTION_PLAN_UPDATED",
    targetType: "SubscriptionPlan",
    targetId: plan.id,
    metadata: {
      updatedFields: Object.keys(input),
      previousType: current.type,
      type: plan.type
    },
    ...auditContext
  });

  return serializePlan(plan);
};

export const updateSubscriptionPlanStatus = async (
  actor: AuthenticatedUser,
  planId: string,
  input: UpdateSubscriptionPlanStatusInput,
  auditContext: AuditRequestContext
) => {
  assertSuperAdmin(actor);
  const current = await assertPlanExists(planId);
  const plan = await getSubscriptionsRepository().updatePlanStatus(planId, input.isActive);

  await recordAuditLog({
    companyId: null,
    actorUserId: actor.id,
    category: "SUBSCRIPTION",
    action: "SUBSCRIPTION_PLAN_STATUS_CHANGED",
    targetType: "SubscriptionPlan",
    targetId: plan.id,
    metadata: {
      previousIsActive: current.isActive,
      isActive: plan.isActive
    },
    ...auditContext
  });

  return serializePlan(plan);
};

export const createCompanySubscription = async (
  actor: AuthenticatedUser,
  companyId: string,
  input: CreateCompanySubscriptionInput,
  auditContext: AuditRequestContext
) => {
  assertSuperAdmin(actor);
  await assertCompanyExists(companyId);
  const plan = await assertPlanExists(input.planId);

  if (!plan.isActive) {
    throw new ValidationError("Subscription plan is inactive", undefined, 400);
  }

  if (input.status === "ACTIVE") {
    await validateNoOtherActiveSubscription(companyId);
  }

  const subscription = await getSubscriptionsRepository().createCompanySubscription({
    companyId,
    planId: input.planId,
    status: input.status,
    startsAt: input.startsAt,
    endsAt: input.endsAt ?? null
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "SUBSCRIPTION",
    action: "COMPANY_SUBSCRIPTION_CREATED",
    targetType: "CompanySubscription",
    targetId: subscription.id,
    metadata: {
      planId: subscription.planId,
      status: subscription.status,
      startsAt: subscription.startsAt,
      endsAt: subscription.endsAt
    },
    ...auditContext
  });

  return serializeSubscription(subscription);
};

export const listCompanySubscriptions = async (actor: AuthenticatedUser, query: ListSubscriptionsQuery) => {
  assertSuperAdmin(actor);

  if (query.companyId) {
    await assertCompanyExists(query.companyId);
  }

  await validatePlanFilter(query.planId);

  const subscriptions = await getSubscriptionsRepository().listSubscriptions(query);
  return subscriptions.map(serializeSubscription);
};

export const getCompanySubscription = async (actor: AuthenticatedUser, companyId: string) => {
  assertSuperAdmin(actor);
  await assertCompanyExists(companyId);

  return serializeSubscription(await getSubscriptionsRepository().findCurrentOrLatestSubscriptionForCompany(companyId));
};

export const updateCompanySubscriptionStatus = async (
  actor: AuthenticatedUser,
  subscriptionId: string,
  input: UpdateCompanySubscriptionStatusInput,
  auditContext: AuditRequestContext
) => {
  assertSuperAdmin(actor);
  const current = await assertSubscriptionExists(subscriptionId);

  validateSubscriptionEndDate(current, input.endsAt);

  if (input.status === "ACTIVE") {
    await validateNoOtherActiveSubscription(current.companyId, subscriptionId);
  }

  const subscription = await getSubscriptionsRepository().updateSubscriptionStatus(subscriptionId, {
    status: input.status,
    endsAt: input.endsAt
  });

  await recordAuditLog({
    companyId: subscription.companyId,
    actorUserId: actor.id,
    category: "SUBSCRIPTION",
    action: "COMPANY_SUBSCRIPTION_STATUS_CHANGED",
    targetType: "CompanySubscription",
    targetId: subscription.id,
    metadata: {
      previousStatus: current.status,
      status: subscription.status,
      endsAt: subscription.endsAt
    },
    ...auditContext
  });

  return serializeSubscription(subscription);
};

export const createPaymentRecord = async (
  actor: AuthenticatedUser,
  input: CreatePaymentRecordInput,
  auditContext: AuditRequestContext
) => {
  assertSuperAdmin(actor);
  await assertCompanyExists(input.companyId);

  if (input.subscriptionId) {
    const subscription = await assertSubscriptionExists(input.subscriptionId);

    if (subscription.companyId !== input.companyId) {
      throw new ValidationError("Subscription does not belong to company", undefined, 400);
    }
  }

  const paymentRecord = await getSubscriptionsRepository().createPaymentRecord({
    companyId: input.companyId,
    subscriptionId: input.subscriptionId ?? null,
    amount: input.amount,
    currency: input.currency,
    status: input.status,
    provider: input.provider ?? null,
    providerReference: input.providerReference ?? null,
    paidAt: input.paidAt ?? null
  });

  await recordAuditLog({
    companyId: paymentRecord.companyId,
    actorUserId: actor.id,
    category: "PAYMENT",
    action: "PAYMENT_RECORD_CREATED",
    targetType: "PaymentRecord",
    targetId: paymentRecord.id,
    metadata: {
      subscriptionId: paymentRecord.subscriptionId,
      amount: paymentRecord.amount,
      currency: paymentRecord.currency,
      status: paymentRecord.status,
      provider: paymentRecord.provider
    },
    ...auditContext
  });

  return serializePaymentRecord(paymentRecord, { includeProviderReference: true });
};

export const listPaymentRecords = async (actor: AuthenticatedUser, query: ListPaymentRecordsQuery) => {
  assertSuperAdmin(actor);

  if (query.companyId) {
    await assertCompanyExists(query.companyId);
  }

  const paymentRecords = await getSubscriptionsRepository().listPaymentRecords(query);
  return paymentRecords.map((paymentRecord) => serializePaymentRecord(paymentRecord, { includeProviderReference: true }));
};

export const listCompanyPaymentRecords = async (
  actor: AuthenticatedUser,
  companyId: string,
  query: CompanyPaymentRecordsQuery
) => {
  assertSuperAdmin(actor);
  await assertCompanyExists(companyId);

  const paymentRecords = await getSubscriptionsRepository().listPaymentRecords({ ...query, companyId });
  return paymentRecords.map((paymentRecord) => serializePaymentRecord(paymentRecord, { includeProviderReference: true }));
};

export const getAdminCompanySubscription = async (actor: AuthenticatedUser, query: AdminBillingQuery) => {
  const companyId = getAdminBillingCompanyId(actor, query);

  await assertCompanyExists(companyId);

  return serializeSubscription(await getSubscriptionsRepository().findCurrentOrLatestSubscriptionForCompany(companyId));
};

export const listAdminCompanyPaymentRecords = async (actor: AuthenticatedUser, query: AdminBillingQuery) => {
  const companyId = getAdminBillingCompanyId(actor, query);

  await assertCompanyExists(companyId);

  const paymentRecords = await getSubscriptionsRepository().listPaymentRecords({ companyId });
  return paymentRecords.map((paymentRecord) => serializePaymentRecord(paymentRecord, { includeProviderReference: false }));
};
