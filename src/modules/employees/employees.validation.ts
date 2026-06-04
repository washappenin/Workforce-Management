import { EmployeeStatus, RoleName } from "@prisma/client";
import { z } from "zod";

const idSchema = z.string().trim().min(1);
const optionalIdSchema = idSchema.optional().nullable();

export const employeeIdParamsSchema = z.object({
  employeeId: idSchema
});

export const employeeScopeQuerySchema = z.object({
  companyId: idSchema.optional()
});

export const createEmployeeSchema = z
  .object({
    companyId: idSchema.optional(),
    email: z.string().trim().email().transform((value) => value.toLowerCase()),
    temporaryPassword: z.string().min(8),
    firstName: z.string().trim().min(1),
    lastName: z.string().trim().min(1),
    employeeCode: z.string().trim().min(1),
    phone: z.string().trim().min(1).optional().nullable(),
    role: z.nativeEnum(RoleName).optional(),
    roles: z.array(z.nativeEnum(RoleName)).min(1).optional(),
    departmentId: optionalIdSchema,
    designationId: optionalIdSchema,
    managerId: optionalIdSchema,
    hireDate: z.coerce.date().optional().nullable()
  })
  .strict()
  .refine((value) => Boolean(value.role) || Boolean(value.roles), {
    message: "At least one role is required",
    path: ["role"]
  })
  .refine((value) => !(value.role && value.roles), {
    message: "Use either role or roles, not both",
    path: ["roles"]
  });

export const updateEmployeeSchema = z
  .object({
    firstName: z.string().trim().min(1).optional(),
    lastName: z.string().trim().min(1).optional(),
    employeeCode: z.string().trim().min(1).optional(),
    phone: z.string().trim().min(1).optional().nullable(),
    departmentId: optionalIdSchema,
    designationId: optionalIdSchema,
    hireDate: z.coerce.date().optional().nullable()
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  });

export const updateEmployeeStatusSchema = z
  .object({
    status: z.nativeEnum(EmployeeStatus)
  })
  .strict();

export const updateEmployeeManagerSchema = z
  .object({
    managerId: optionalIdSchema
  })
  .strict();

export type EmployeeScopeQuery = z.infer<typeof employeeScopeQuerySchema>;
export type CreateEmployeeInput = z.infer<typeof createEmployeeSchema>;
export type UpdateEmployeeInput = z.infer<typeof updateEmployeeSchema>;
export type UpdateEmployeeStatusInput = z.infer<typeof updateEmployeeStatusSchema>;
export type UpdateEmployeeManagerInput = z.infer<typeof updateEmployeeManagerSchema>;
