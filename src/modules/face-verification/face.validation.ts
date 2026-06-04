import { FaceEnrollmentStatus } from "@prisma/client";
import { z } from "zod";

const idSchema = z.string().trim().min(1);
const providerSchema = z.literal("mock");

export const employeeIdParamsSchema = z.object({
  employeeId: idSchema
});

export const faceScopeQuerySchema = z.object({
  companyId: idSchema.optional()
});

export const upsertFaceEnrollmentSchema = z
  .object({
    companyId: idSchema.optional(),
    provider: providerSchema,
    providerSubjectId: z.string().trim().min(1).optional().nullable(),
    templateReference: z.string().trim().min(1).optional().nullable()
  })
  .strict();

export const updateFaceEnrollmentStatusSchema = z
  .object({
    status: z.nativeEnum(FaceEnrollmentStatus)
  })
  .strict();

export const verifyFaceSchema = z
  .object({
    employeeId: idSchema.optional(),
    provider: providerSchema,
    verificationReference: z.string().trim().min(1)
  })
  .strict();

export type FaceScopeQuery = z.infer<typeof faceScopeQuerySchema>;
export type UpsertFaceEnrollmentInput = z.infer<typeof upsertFaceEnrollmentSchema>;
export type UpdateFaceEnrollmentStatusInput = z.infer<typeof updateFaceEnrollmentStatusSchema>;
export type VerifyFaceInput = z.infer<typeof verifyFaceSchema>;
