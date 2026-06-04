import { LeaveRequestStatus, LeaveTypeStatus } from "@prisma/client";
import { z } from "zod";

const idSchema = z.string().trim().min(1);
const dayCountSchema = z.number().finite().nonnegative().max(3650);
const yearSchema = z.number().int().min(2000).max(2100);
const reasonSchema = z.string().trim().max(1000).optional().nullable();
const commentSchema = z.string().trim().max(500).optional().nullable();
const dateOnlySchema = z
  .string()
  .trim()
  .regex(/^\d{4}-\d{2}-\d{2}$/, "Date must use YYYY-MM-DD format")
  .transform((value) => new Date(`${value}T00:00:00.000Z`));

const validateDateRange = <T extends { startDate?: Date; endDate?: Date }>(value: T) =>
  !value.startDate || !value.endDate || value.endDate >= value.startDate;

const validateQueryDateRange = <T extends { from?: Date; to?: Date }>(value: T) => !value.from || !value.to || value.to >= value.from;

const validateEntitlementDays = <T extends { totalDays?: number; usedDays?: number }>(value: T) =>
  value.totalDays === undefined || value.usedDays === undefined || value.usedDays <= value.totalDays;

export const leaveTypeIdParamsSchema = z.object({
  leaveTypeId: idSchema
});

export const leaveEntitlementIdParamsSchema = z.object({
  entitlementId: idSchema
});

export const leaveRequestIdParamsSchema = z.object({
  leaveRequestId: idSchema
});

export const leaveScopeQuerySchema = z.object({
  companyId: idSchema.optional()
});

export const createLeaveTypeSchema = z
  .object({
    companyId: idSchema.optional(),
    name: z.string().trim().min(1),
    defaultAnnualAllowance: dayCountSchema.optional().nullable()
  })
  .strict();

export const updateLeaveTypeSchema = z
  .object({
    name: z.string().trim().min(1).optional(),
    defaultAnnualAllowance: dayCountSchema.optional().nullable()
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  });

export const updateLeaveTypeStatusSchema = z
  .object({
    status: z.nativeEnum(LeaveTypeStatus)
  })
  .strict();

export const createLeaveEntitlementSchema = z
  .object({
    companyId: idSchema.optional(),
    employeeId: idSchema,
    leaveTypeId: idSchema,
    year: yearSchema,
    totalDays: dayCountSchema,
    usedDays: dayCountSchema.optional().default(0)
  })
  .strict()
  .refine(validateEntitlementDays, {
    message: "usedDays cannot exceed totalDays",
    path: ["usedDays"]
  });

export const leaveEntitlementsQuerySchema = z
  .object({
    companyId: idSchema.optional(),
    employeeId: idSchema.optional(),
    leaveTypeId: idSchema.optional(),
    year: z.coerce.number().int().min(2000).max(2100).optional()
  })
  .strict();

export const updateLeaveEntitlementSchema = z
  .object({
    totalDays: dayCountSchema.optional(),
    usedDays: dayCountSchema.optional()
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  })
  .refine(validateEntitlementDays, {
    message: "usedDays cannot exceed totalDays",
    path: ["usedDays"]
  });

export const createLeaveRequestSchema = z
  .object({
    leaveTypeId: idSchema,
    startDate: dateOnlySchema,
    endDate: dateOnlySchema,
    reason: reasonSchema
  })
  .strict()
  .refine(validateDateRange, {
    message: "endDate must be on or after startDate",
    path: ["endDate"]
  });

export const myLeaveQuerySchema = z
  .object({
    status: z.nativeEnum(LeaveRequestStatus).optional(),
    year: z.coerce.number().int().min(2000).max(2100).optional()
  })
  .strict();

export const adminLeaveRequestsQuerySchema = z
  .object({
    companyId: idSchema.optional(),
    employeeId: idSchema.optional(),
    leaveTypeId: idSchema.optional(),
    status: z.nativeEnum(LeaveRequestStatus).optional(),
    from: z.coerce.date().optional(),
    to: z.coerce.date().optional()
  })
  .strict()
  .refine(validateQueryDateRange, {
    message: "to must be on or after from",
    path: ["to"]
  });

export const reviewLeaveRequestSchema = z
  .object({
    comment: commentSchema
  })
  .strict();

export type LeaveScopeQuery = z.infer<typeof leaveScopeQuerySchema>;
export type CreateLeaveTypeInput = z.infer<typeof createLeaveTypeSchema>;
export type UpdateLeaveTypeInput = z.infer<typeof updateLeaveTypeSchema>;
export type UpdateLeaveTypeStatusInput = z.infer<typeof updateLeaveTypeStatusSchema>;
export type CreateLeaveEntitlementInput = z.infer<typeof createLeaveEntitlementSchema>;
export type LeaveEntitlementsQuery = z.infer<typeof leaveEntitlementsQuerySchema>;
export type UpdateLeaveEntitlementInput = z.infer<typeof updateLeaveEntitlementSchema>;
export type CreateLeaveRequestInput = z.infer<typeof createLeaveRequestSchema>;
export type MyLeaveQuery = z.infer<typeof myLeaveQuerySchema>;
export type AdminLeaveRequestsQuery = z.infer<typeof adminLeaveRequestsQuerySchema>;
export type ReviewLeaveRequestInput = z.infer<typeof reviewLeaveRequestSchema>;
