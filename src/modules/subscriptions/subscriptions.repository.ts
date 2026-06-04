import type {
  CompanyStatus,
  PaymentStatus,
  Prisma,
  SubscriptionPlanType,
  SubscriptionStatus
} from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface BillingCompanyRecord {
  id: string;
  name: string;
  status: CompanyStatus;
}

export interface SubscriptionPlanRecord {
  id: string;
  name: string;
  type: SubscriptionPlanType;
  pricePerEmployee: number;
  currency: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface CompanySubscriptionRecord {
  id: string;
  companyId: string;
  planId: string;
  status: SubscriptionStatus;
  startsAt: Date;
  endsAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  plan?: SubscriptionPlanRecord;
  company?: BillingCompanyRecord;
}

export interface PaymentRecordRecord {
  id: string;
  companyId: string;
  subscriptionId: string | null;
  amount: number;
  currency: string;
  status: PaymentStatus;
  provider: string | null;
  providerReference: string | null;
  paidAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  company?: BillingCompanyRecord;
  subscription?: CompanySubscriptionRecord | null;
}

export interface CreatePlanRepositoryInput {
  name: string;
  type: SubscriptionPlanType;
  pricePerEmployee: number;
  currency: string;
  isActive?: boolean;
}

export type UpdatePlanRepositoryInput = Partial<CreatePlanRepositoryInput>;

export interface ListPlansRepositoryFilters {
  type?: SubscriptionPlanType;
  isActive?: boolean;
}

export interface CreateCompanySubscriptionRepositoryInput {
  companyId: string;
  planId: string;
  status: SubscriptionStatus;
  startsAt: Date;
  endsAt?: Date | null;
}

export interface ListSubscriptionsRepositoryFilters {
  companyId?: string;
  planId?: string;
  status?: SubscriptionStatus;
}

export interface UpdateCompanySubscriptionRepositoryInput {
  status: SubscriptionStatus;
  endsAt?: Date | null;
}

export interface CreatePaymentRecordRepositoryInput {
  companyId: string;
  subscriptionId?: string | null;
  amount: number;
  currency: string;
  status: PaymentStatus;
  provider?: string | null;
  providerReference?: string | null;
  paidAt?: Date | null;
}

export interface ListPaymentRecordsRepositoryFilters {
  companyId?: string;
  status?: PaymentStatus;
  provider?: string;
  from?: Date;
  to?: Date;
}

export interface SubscriptionsRepository {
  findCompanyById(companyId: string): Promise<BillingCompanyRecord | null>;
  createPlan(input: CreatePlanRepositoryInput): Promise<SubscriptionPlanRecord>;
  listPlans(filters: ListPlansRepositoryFilters): Promise<SubscriptionPlanRecord[]>;
  findPlanById(planId: string): Promise<SubscriptionPlanRecord | null>;
  findPlanByName(name: string): Promise<SubscriptionPlanRecord | null>;
  updatePlan(planId: string, input: UpdatePlanRepositoryInput): Promise<SubscriptionPlanRecord>;
  updatePlanStatus(planId: string, isActive: boolean): Promise<SubscriptionPlanRecord>;
  createCompanySubscription(input: CreateCompanySubscriptionRepositoryInput): Promise<CompanySubscriptionRecord>;
  listSubscriptions(filters: ListSubscriptionsRepositoryFilters): Promise<CompanySubscriptionRecord[]>;
  findSubscriptionById(subscriptionId: string): Promise<CompanySubscriptionRecord | null>;
  findActiveSubscriptionForCompany(companyId: string): Promise<CompanySubscriptionRecord | null>;
  findCurrentOrLatestSubscriptionForCompany(companyId: string): Promise<CompanySubscriptionRecord | null>;
  updateSubscriptionStatus(
    subscriptionId: string,
    input: UpdateCompanySubscriptionRepositoryInput
  ): Promise<CompanySubscriptionRecord>;
  createPaymentRecord(input: CreatePaymentRecordRepositoryInput): Promise<PaymentRecordRecord>;
  listPaymentRecords(filters: ListPaymentRecordsRepositoryFilters): Promise<PaymentRecordRecord[]>;
}

const decimalToNumber = (value: Prisma.Decimal | number): number => Number(value);

const mapCompany = (company: BillingCompanyRecord): BillingCompanyRecord => ({
  id: company.id,
  name: company.name,
  status: company.status
});

const mapPlan = (plan: {
  id: string;
  name: string;
  type: SubscriptionPlanType;
  pricePerEmployee: Prisma.Decimal | number;
  currency: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}): SubscriptionPlanRecord => ({
  id: plan.id,
  name: plan.name,
  type: plan.type,
  pricePerEmployee: decimalToNumber(plan.pricePerEmployee),
  currency: plan.currency,
  isActive: plan.isActive,
  createdAt: plan.createdAt,
  updatedAt: plan.updatedAt
});

const mapSubscription = (subscription: {
  id: string;
  companyId: string;
  planId: string;
  status: SubscriptionStatus;
  startsAt: Date;
  endsAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  plan?: Parameters<typeof mapPlan>[0];
  company?: BillingCompanyRecord;
}): CompanySubscriptionRecord => ({
  id: subscription.id,
  companyId: subscription.companyId,
  planId: subscription.planId,
  status: subscription.status,
  startsAt: subscription.startsAt,
  endsAt: subscription.endsAt,
  createdAt: subscription.createdAt,
  updatedAt: subscription.updatedAt,
  ...(subscription.plan ? { plan: mapPlan(subscription.plan) } : {}),
  ...(subscription.company ? { company: mapCompany(subscription.company) } : {})
});

const mapPaymentRecord = (payment: {
  id: string;
  companyId: string;
  subscriptionId: string | null;
  amount: Prisma.Decimal | number;
  currency: string;
  status: PaymentStatus;
  provider: string | null;
  providerReference: string | null;
  paidAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  company?: BillingCompanyRecord;
  subscription?: Parameters<typeof mapSubscription>[0] | null;
}): PaymentRecordRecord => ({
  id: payment.id,
  companyId: payment.companyId,
  subscriptionId: payment.subscriptionId,
  amount: decimalToNumber(payment.amount),
  currency: payment.currency,
  status: payment.status,
  provider: payment.provider,
  providerReference: payment.providerReference,
  paidAt: payment.paidAt,
  createdAt: payment.createdAt,
  updatedAt: payment.updatedAt,
  ...(payment.company ? { company: mapCompany(payment.company) } : {}),
  ...(payment.subscription !== undefined
    ? { subscription: payment.subscription ? mapSubscription(payment.subscription) : null }
    : {})
});

const subscriptionInclude = {
  plan: true,
  company: {
    select: {
      id: true,
      name: true,
      status: true
    }
  }
} satisfies Prisma.CompanySubscriptionInclude;

const paymentInclude = {
  company: {
    select: {
      id: true,
      name: true,
      status: true
    }
  },
  subscription: {
    include: subscriptionInclude
  }
} satisfies Prisma.PaymentRecordInclude;

const prismaSubscriptionsRepository: SubscriptionsRepository = {
  async findCompanyById(companyId) {
    const prisma = getPrismaClient();

    return prisma.company.findUnique({
      where: { id: companyId },
      select: {
        id: true,
        name: true,
        status: true
      }
    });
  },

  async createPlan(input) {
    const prisma = getPrismaClient();
    const plan = await prisma.subscriptionPlan.create({
      data: {
        name: input.name,
        type: input.type,
        pricePerEmployee: input.pricePerEmployee,
        currency: input.currency,
        isActive: input.isActive ?? true
      }
    });

    return mapPlan(plan);
  },

  async listPlans(filters) {
    const prisma = getPrismaClient();
    const plans = await prisma.subscriptionPlan.findMany({
      where: {
        type: filters.type,
        isActive: filters.isActive
      },
      orderBy: [{ isActive: "desc" }, { createdAt: "desc" }]
    });

    return plans.map(mapPlan);
  },

  async findPlanById(planId) {
    const prisma = getPrismaClient();
    const plan = await prisma.subscriptionPlan.findUnique({
      where: { id: planId }
    });

    return plan ? mapPlan(plan) : null;
  },

  async findPlanByName(name) {
    const prisma = getPrismaClient();
    const plan = await prisma.subscriptionPlan.findUnique({
      where: { name }
    });

    return plan ? mapPlan(plan) : null;
  },

  async updatePlan(planId, input) {
    const prisma = getPrismaClient();
    const plan = await prisma.subscriptionPlan.update({
      where: { id: planId },
      data: input
    });

    return mapPlan(plan);
  },

  async updatePlanStatus(planId, isActive) {
    const prisma = getPrismaClient();
    const plan = await prisma.subscriptionPlan.update({
      where: { id: planId },
      data: { isActive }
    });

    return mapPlan(plan);
  },

  async createCompanySubscription(input) {
    const prisma = getPrismaClient();
    const subscription = await prisma.companySubscription.create({
      data: {
        companyId: input.companyId,
        planId: input.planId,
        status: input.status,
        startsAt: input.startsAt,
        endsAt: input.endsAt ?? null
      },
      include: subscriptionInclude
    });

    return mapSubscription(subscription);
  },

  async listSubscriptions(filters) {
    const prisma = getPrismaClient();
    const subscriptions = await prisma.companySubscription.findMany({
      where: {
        companyId: filters.companyId,
        planId: filters.planId,
        status: filters.status
      },
      include: subscriptionInclude,
      orderBy: [{ startsAt: "desc" }, { createdAt: "desc" }]
    });

    return subscriptions.map(mapSubscription);
  },

  async findSubscriptionById(subscriptionId) {
    const prisma = getPrismaClient();
    const subscription = await prisma.companySubscription.findUnique({
      where: { id: subscriptionId },
      include: subscriptionInclude
    });

    return subscription ? mapSubscription(subscription) : null;
  },

  async findActiveSubscriptionForCompany(companyId) {
    const prisma = getPrismaClient();
    const subscription = await prisma.companySubscription.findFirst({
      where: {
        companyId,
        status: "ACTIVE"
      },
      include: subscriptionInclude,
      orderBy: [{ startsAt: "desc" }, { createdAt: "desc" }]
    });

    return subscription ? mapSubscription(subscription) : null;
  },

  async findCurrentOrLatestSubscriptionForCompany(companyId) {
    const prisma = getPrismaClient();
    const activeSubscription = await prisma.companySubscription.findFirst({
      where: {
        companyId,
        status: "ACTIVE"
      },
      include: subscriptionInclude,
      orderBy: [{ startsAt: "desc" }, { createdAt: "desc" }]
    });

    if (activeSubscription) {
      return mapSubscription(activeSubscription);
    }

    const latestSubscription = await prisma.companySubscription.findFirst({
      where: { companyId },
      include: subscriptionInclude,
      orderBy: [{ startsAt: "desc" }, { createdAt: "desc" }]
    });

    return latestSubscription ? mapSubscription(latestSubscription) : null;
  },

  async updateSubscriptionStatus(subscriptionId, input) {
    const prisma = getPrismaClient();
    const subscription = await prisma.companySubscription.update({
      where: { id: subscriptionId },
      data: {
        status: input.status,
        endsAt: input.endsAt
      },
      include: subscriptionInclude
    });

    return mapSubscription(subscription);
  },

  async createPaymentRecord(input) {
    const prisma = getPrismaClient();
    const payment = await prisma.paymentRecord.create({
      data: {
        companyId: input.companyId,
        subscriptionId: input.subscriptionId ?? null,
        amount: input.amount,
        currency: input.currency,
        status: input.status,
        provider: input.provider ?? null,
        providerReference: input.providerReference ?? null,
        paidAt: input.paidAt ?? null
      },
      include: paymentInclude
    });

    return mapPaymentRecord(payment);
  },

  async listPaymentRecords(filters) {
    const prisma = getPrismaClient();
    const paidAt =
      filters.from || filters.to
        ? {
            gte: filters.from,
            lte: filters.to
          }
        : undefined;
    const payments = await prisma.paymentRecord.findMany({
      where: {
        companyId: filters.companyId,
        status: filters.status,
        provider: filters.provider,
        paidAt
      },
      include: paymentInclude,
      orderBy: [{ paidAt: "desc" }, { createdAt: "desc" }]
    });

    return payments.map(mapPaymentRecord);
  }
};

let activeSubscriptionsRepository = prismaSubscriptionsRepository;

export const getSubscriptionsRepository = () => activeSubscriptionsRepository;

export const setSubscriptionsRepositoryForTests = (repository: SubscriptionsRepository) => {
  activeSubscriptionsRepository = repository;
};

export const resetSubscriptionsRepositoryForTests = () => {
  activeSubscriptionsRepository = prismaSubscriptionsRepository;
};
