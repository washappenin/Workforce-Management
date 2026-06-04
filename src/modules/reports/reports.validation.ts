import { LeaveRequestStatus, OKRStatus, PerformanceReviewStatus } from "@prisma/client";
import { z } from "zod";

const idSchema = z.string().trim().min(1);

const dateRangeRefinement = {
  message: "to must be on or after from",
  path: ["to"]
};

export const companyScopeReportQuerySchema = z
  .object({
    companyId: idSchema.optional()
  })
  .strict();

export const attendanceReportQuerySchema = z
  .object({
    companyId: idSchema.optional(),
    from: z.coerce.date().optional(),
    to: z.coerce.date().optional(),
    employeeId: idSchema.optional(),
    departmentId: idSchema.optional()
  })
  .strict()
  .refine((value) => !value.from || !value.to || value.to >= value.from, dateRangeRefinement);

export const leaveReportQuerySchema = z
  .object({
    companyId: idSchema.optional(),
    year: z.coerce.number().int().min(2000).max(2100).optional(),
    employeeId: idSchema.optional(),
    departmentId: idSchema.optional(),
    status: z.nativeEnum(LeaveRequestStatus).optional()
  })
  .strict();

export const okrReportQuerySchema = z
  .object({
    companyId: idSchema.optional(),
    employeeId: idSchema.optional(),
    departmentId: idSchema.optional(),
    status: z.nativeEnum(OKRStatus).optional()
  })
  .strict();

export const performanceReportQuerySchema = z
  .object({
    companyId: idSchema.optional(),
    reviewCycleId: idSchema.optional(),
    employeeId: idSchema.optional(),
    departmentId: idSchema.optional(),
    status: z.nativeEnum(PerformanceReviewStatus).optional()
  })
  .strict();

export type CompanyScopeReportQuery = z.infer<typeof companyScopeReportQuerySchema>;
export type AttendanceReportQuery = z.infer<typeof attendanceReportQuerySchema>;
export type LeaveReportQuery = z.infer<typeof leaveReportQuerySchema>;
export type OkrReportQuery = z.infer<typeof okrReportQuerySchema>;
export type PerformanceReportQuery = z.infer<typeof performanceReportQuerySchema>;
