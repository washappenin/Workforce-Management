import { PerformanceReviewStatus, ReviewCycleStatus } from "@prisma/client";
import { z } from "zod";

const idSchema = z.string().trim().min(1);
const textSchema = z.string().trim().min(1);
const summarySchema = z.string().trim().min(1).max(4000);
const ratingSchema = z.number().min(1).max(5);

const dateRangeSchema = z
  .object({
    startDate: z.coerce.date(),
    endDate: z.coerce.date()
  })
  .refine((value) => value.endDate >= value.startDate, {
    message: "endDate must be on or after startDate",
    path: ["endDate"]
  });

export const reviewCycleIdParamsSchema = z.object({
  reviewCycleId: idSchema
});

export const reviewIdParamsSchema = z.object({
  reviewId: idSchema
});

export const reviewEmployeeIdParamsSchema = z.object({
  employeeId: idSchema
});

export const reviewScopeQuerySchema = z.object({
  companyId: idSchema.optional()
});

export const createReviewCycleSchema = z
  .object({
    companyId: idSchema.optional(),
    name: textSchema.max(200),
    startDate: z.coerce.date(),
    endDate: z.coerce.date()
  })
  .strict()
  .refine((value) => value.endDate >= value.startDate, {
    message: "endDate must be on or after startDate",
    path: ["endDate"]
  });

export const updateReviewCycleSchema = z
  .object({
    name: textSchema.max(200).optional(),
    startDate: z.coerce.date().optional(),
    endDate: z.coerce.date().optional()
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  });

export const updateReviewCycleStatusSchema = z
  .object({
    status: z.nativeEnum(ReviewCycleStatus)
  })
  .strict();

export const createPerformanceReviewSchema = z
  .object({
    reviewCycleId: idSchema,
    summary: summarySchema,
    rating: ratingSchema.optional().nullable()
  })
  .strict();

export const updatePerformanceReviewSchema = z
  .object({
    summary: summarySchema.optional(),
    rating: ratingSchema.optional().nullable()
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  });

export const updatePerformanceReviewStatusSchema = z
  .object({
    status: z.nativeEnum(PerformanceReviewStatus)
  })
  .strict();

export const adminReviewsQuerySchema = z
  .object({
    companyId: idSchema.optional(),
    employeeId: idSchema.optional(),
    reviewCycleId: idSchema.optional(),
    status: z.nativeEnum(PerformanceReviewStatus).optional(),
    from: z.coerce.date().optional(),
    to: z.coerce.date().optional()
  })
  .strict()
  .refine((value) => !value.from || !value.to || value.to >= value.from, {
    message: "to must be on or after from",
    path: ["to"]
  });

export const assertCompleteReviewCycleDateRange = (input: {
  startDate?: Date;
  endDate?: Date;
  currentStartDate: Date;
  currentEndDate: Date;
}) => {
  dateRangeSchema.parse({
    startDate: input.startDate ?? input.currentStartDate,
    endDate: input.endDate ?? input.currentEndDate
  });
};

export type ReviewScopeQuery = z.infer<typeof reviewScopeQuerySchema>;
export type CreateReviewCycleInput = z.infer<typeof createReviewCycleSchema>;
export type UpdateReviewCycleInput = z.infer<typeof updateReviewCycleSchema>;
export type UpdateReviewCycleStatusInput = z.infer<typeof updateReviewCycleStatusSchema>;
export type CreatePerformanceReviewInput = z.infer<typeof createPerformanceReviewSchema>;
export type UpdatePerformanceReviewInput = z.infer<typeof updatePerformanceReviewSchema>;
export type UpdatePerformanceReviewStatusInput = z.infer<typeof updatePerformanceReviewStatusSchema>;
export type AdminReviewsQuery = z.infer<typeof adminReviewsQuerySchema>;
