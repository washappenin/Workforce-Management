import { ShiftStatus } from "@prisma/client";
import { z } from "zod";

const idSchema = z.string().trim().min(1);
const timeSchema = z.string().trim().regex(/^([01]\d|2[0-3]):[0-5]\d$/, "Time must use HH:mm format");
const dateOnlySchema = z
  .string()
  .trim()
  .regex(/^\d{4}-\d{2}-\d{2}$/, "Date must use YYYY-MM-DD format")
  .transform((value) => new Date(`${value}T00:00:00.000Z`));

const validateAssignmentDateRange = <T extends { startsOn?: Date; endsOn?: Date | null }>(value: T) =>
  !value.startsOn || !value.endsOn || value.endsOn >= value.startsOn;

export const shiftIdParamsSchema = z.object({
  shiftId: idSchema
});

export const shiftAssignmentIdParamsSchema = z.object({
  assignmentId: idSchema
});

export const shiftScopeQuerySchema = z.object({
  companyId: idSchema.optional()
});

export const createShiftSchema = z
  .object({
    companyId: idSchema.optional(),
    name: z.string().trim().min(1),
    startTime: timeSchema,
    endTime: timeSchema
  })
  .strict();

export const updateShiftSchema = z
  .object({
    name: z.string().trim().min(1).optional(),
    startTime: timeSchema.optional(),
    endTime: timeSchema.optional()
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  });

export const updateShiftStatusSchema = z
  .object({
    status: z.nativeEnum(ShiftStatus)
  })
  .strict();

export const assignShiftSchema = z
  .object({
    employeeId: idSchema,
    startsOn: dateOnlySchema,
    endsOn: dateOnlySchema.optional().nullable()
  })
  .strict()
  .refine(validateAssignmentDateRange, {
    message: "endsOn must be on or after startsOn",
    path: ["endsOn"]
  });

export const updateShiftAssignmentSchema = z
  .object({
    startsOn: dateOnlySchema.optional(),
    endsOn: dateOnlySchema.optional().nullable()
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  })
  .refine(validateAssignmentDateRange, {
    message: "endsOn must be on or after startsOn",
    path: ["endsOn"]
  });

export type ShiftScopeQuery = z.infer<typeof shiftScopeQuerySchema>;
export type CreateShiftInput = z.infer<typeof createShiftSchema>;
export type UpdateShiftInput = z.infer<typeof updateShiftSchema>;
export type UpdateShiftStatusInput = z.infer<typeof updateShiftStatusSchema>;
export type AssignShiftInput = z.infer<typeof assignShiftSchema>;
export type UpdateShiftAssignmentInput = z.infer<typeof updateShiftAssignmentSchema>;
