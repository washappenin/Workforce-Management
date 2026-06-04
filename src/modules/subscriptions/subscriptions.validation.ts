import { PaymentStatus, SubscriptionPlanType, SubscriptionStatus } from "@prisma/client";
import { z } from "zod";

const idSchema = z.string().trim().min(1);
const moneySchema = z.number().finite().nonnegative().max(999999999);
const currencySchema = z.string().trim().regex(/^[A-Z]{3}$/, "Currency must be a 3-letter uppercase code");
const optionalTextSchema = z.string().trim().min(1).max(255).optional().nullable();
const booleanQuerySchema = z
  .enum(["true", "false"])
  .transform((value) => value === "true")
  .or(z.boolean());

const dateSchema = z
  .string()
  .trim()
  .min(1)
  .refine((value) => !Number.isNaN(Date.parse(value)), "Date must be valid")
  .transform((value) => (value.match(/^\d{4}-\d{2}-\d{2}$/) ? new Date(`${value}T00:00:00.000Z`) : new Date(value)));

const nullableDateSchema = dateSchema.optional().nullable();

const validateSubscriptionDates = <T extends { startsAt?: Date; endsAt?: Date | null }>(value: T) =>
  !value.startsAt || !value.endsAt || value.endsAt >= value.startsAt;

const validateQueryDateRange = <T extends { from?: Date; to?: Date }>(value: T) => !value.from || !value.to || value.to >= value.from;

export const planIdParamsSchema = z.object({
  planId: idSchema
});

export const companyIdParamsSchema = z.object({
  companyId: idSchema
});

export const subscriptionIdParamsSchema = z.object({
  subscriptionId: idSchema
});

export const createSubscriptionPlanSchema = z
  .object({
    name: z.string().trim().min(1).max(120),
    type: z.nativeEnum(SubscriptionPlanType),
    pricePerEmployee: moneySchema,
    currency: currencySchema,
    isActive: z.boolean().optional().default(true)
  })
  .strict();

export const listSubscriptionPlansQuerySchema = z
  .object({
    isActive: booleanQuerySchema.optional(),
    type: z.nativeEnum(SubscriptionPlanType).optional()
  })
  .strict();

export const updateSubscriptionPlanSchema = z
  .object({
    name: z.string().trim().min(1).max(120).optional(),
    type: z.nativeEnum(SubscriptionPlanType).optional(),
    pricePerEmployee: moneySchema.optional(),
    currency: currencySchema.optional(),
    isActive: z.boolean().optional()
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  });

export const updateSubscriptionPlanStatusSchema = z
  .object({
    isActive: z.boolean()
  })
  .strict();

export const createCompanySubscriptionSchema = z
  .object({
    planId: idSchema,
    startsAt: dateSchema,
    endsAt: nullableDateSchema,
    status: z.nativeEnum(SubscriptionStatus)
  })
  .strict()
  .refine(validateSubscriptionDates, {
    message: "endsAt cannot be before startsAt",
    path: ["endsAt"]
  });

export const listSubscriptionsQuerySchema = z
  .object({
    companyId: idSchema.optional(),
    planId: idSchema.optional(),
    status: z.nativeEnum(SubscriptionStatus).optional()
  })
  .strict();

export const updateCompanySubscriptionStatusSchema = z
  .object({
    status: z.nativeEnum(SubscriptionStatus),
    endsAt: nullableDateSchema
  })
  .strict();

export const createPaymentRecordSchema = z
  .object({
    companyId: idSchema,
    subscriptionId: idSchema.optional().nullable(),
    amount: moneySchema,
    currency: currencySchema,
    status: z.nativeEnum(PaymentStatus),
    provider: optionalTextSchema,
    providerReference: optionalTextSchema,
    paidAt: nullableDateSchema
  })
  .strict();

export const listPaymentRecordsQuerySchema = z
  .object({
    companyId: idSchema.optional(),
    status: z.nativeEnum(PaymentStatus).optional(),
    provider: z.string().trim().min(1).max(255).optional(),
    from: dateSchema.optional(),
    to: dateSchema.optional()
  })
  .strict()
  .refine(validateQueryDateRange, {
    message: "to must be on or after from",
    path: ["to"]
  });

export const companyPaymentRecordsQuerySchema = z
  .object({
    status: z.nativeEnum(PaymentStatus).optional(),
    provider: z.string().trim().min(1).max(255).optional(),
    from: dateSchema.optional(),
    to: dateSchema.optional()
  })
  .strict()
  .refine(validateQueryDateRange, {
    message: "to must be on or after from",
    path: ["to"]
  });

export const adminBillingQuerySchema = z
  .object({
    companyId: idSchema.optional()
  })
  .strict();

export type CreateSubscriptionPlanInput = z.infer<typeof createSubscriptionPlanSchema>;
export type ListSubscriptionPlansQuery = z.infer<typeof listSubscriptionPlansQuerySchema>;
export type UpdateSubscriptionPlanInput = z.infer<typeof updateSubscriptionPlanSchema>;
export type UpdateSubscriptionPlanStatusInput = z.infer<typeof updateSubscriptionPlanStatusSchema>;
export type CreateCompanySubscriptionInput = z.infer<typeof createCompanySubscriptionSchema>;
export type ListSubscriptionsQuery = z.infer<typeof listSubscriptionsQuerySchema>;
export type UpdateCompanySubscriptionStatusInput = z.infer<typeof updateCompanySubscriptionStatusSchema>;
export type CreatePaymentRecordInput = z.infer<typeof createPaymentRecordSchema>;
export type ListPaymentRecordsQuery = z.infer<typeof listPaymentRecordsQuerySchema>;
export type CompanyPaymentRecordsQuery = z.infer<typeof companyPaymentRecordsQuerySchema>;
export type AdminBillingQuery = z.infer<typeof adminBillingQuerySchema>;
