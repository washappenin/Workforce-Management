import { z } from "zod";

const idSchema = z.string().trim().min(1);

export const designationIdParamsSchema = z.object({
  designationId: idSchema
});

export const designationScopeQuerySchema = z.object({
  companyId: idSchema.optional()
});

export const createDesignationSchema = z.object({
  title: z.string().trim().min(1),
  companyId: idSchema.optional(),
  departmentId: idSchema.optional().nullable(),
  isActive: z.boolean().optional()
});

export const updateDesignationSchema = z
  .object({
    title: z.string().trim().min(1).optional(),
    departmentId: idSchema.optional().nullable()
  })
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  });

export const updateDesignationStatusSchema = z.object({
  isActive: z.boolean()
});

export type DesignationScopeQuery = z.infer<typeof designationScopeQuerySchema>;
export type CreateDesignationInput = z.infer<typeof createDesignationSchema>;
export type UpdateDesignationInput = z.infer<typeof updateDesignationSchema>;
export type UpdateDesignationStatusInput = z.infer<typeof updateDesignationStatusSchema>;
