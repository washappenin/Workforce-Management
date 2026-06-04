import { z } from "zod";

const idSchema = z.string().trim().min(1);

export const departmentIdParamsSchema = z.object({
  departmentId: idSchema
});

export const departmentScopeQuerySchema = z.object({
  companyId: idSchema.optional()
});

export const createDepartmentSchema = z.object({
  name: z.string().trim().min(1),
  companyId: idSchema.optional(),
  isActive: z.boolean().optional()
});

export const updateDepartmentSchema = z
  .object({
    name: z.string().trim().min(1).optional()
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  });

export const updateDepartmentStatusSchema = z.object({
  isActive: z.boolean()
});

export type DepartmentScopeQuery = z.infer<typeof departmentScopeQuerySchema>;
export type CreateDepartmentInput = z.infer<typeof createDepartmentSchema>;
export type UpdateDepartmentInput = z.infer<typeof updateDepartmentSchema>;
export type UpdateDepartmentStatusInput = z.infer<typeof updateDepartmentStatusSchema>;
