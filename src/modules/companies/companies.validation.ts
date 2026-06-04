import { CompanyStatus } from "@prisma/client";
import { z } from "zod";

const optionalTrimmedString = z.string().trim().min(1).optional().nullable();

export const companyIdParamsSchema = z.object({
  companyId: z.string().trim().min(1)
});

export const createCompanySchema = z.object({
  name: z.string().trim().min(1),
  contactEmail: z.string().trim().email().transform((value) => value.toLowerCase()).optional(),
  contactPhone: optionalTrimmedString,
  billingEmail: z.string().trim().email().transform((value) => value.toLowerCase()).optional(),
  address: optionalTrimmedString,
  country: optionalTrimmedString,
  timezone: optionalTrimmedString,
  status: z.nativeEnum(CompanyStatus).optional()
});

export const updateCompanySchema = createCompanySchema.partial().refine((value) => Object.keys(value).length > 0, {
  message: "At least one field is required"
});

export const updateCompanyStatusSchema = z.object({
  status: z.nativeEnum(CompanyStatus)
});

export type CreateCompanyInput = z.infer<typeof createCompanySchema>;
export type UpdateCompanyInput = z.infer<typeof updateCompanySchema>;
export type UpdateCompanyStatusInput = z.infer<typeof updateCompanyStatusSchema>;
