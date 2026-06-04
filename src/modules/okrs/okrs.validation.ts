import { OKRStatus } from "@prisma/client";
import { z } from "zod";

const idSchema = z.string().trim().min(1);
const textSchema = z.string().trim().min(1);
const descriptionSchema = z.string().trim().max(2000).optional().nullable();
const noteSchema = z.string().trim().max(1000).optional().nullable();
const commentSchema = z.string().trim().max(1000).optional().nullable();

export const okrIdParamsSchema = z.object({
  okrId: idSchema
});

export const okrScopeQuerySchema = z.object({
  companyId: idSchema.optional()
});

export const createOkrSchema = z
  .object({
    companyId: idSchema.optional(),
    employeeId: idSchema,
    title: textSchema.max(200),
    description: descriptionSchema,
    dueDate: z.coerce.date().optional().nullable()
  })
  .strict();

export const myOkrsQuerySchema = z
  .object({
    status: z.nativeEnum(OKRStatus).optional()
  })
  .strict();

export const adminOkrsQuerySchema = z
  .object({
    companyId: idSchema.optional(),
    employeeId: idSchema.optional(),
    status: z.nativeEnum(OKRStatus).optional(),
    from: z.coerce.date().optional(),
    to: z.coerce.date().optional()
  })
  .strict()
  .refine((value) => !value.from || !value.to || value.to >= value.from, {
    message: "to must be on or after from",
    path: ["to"]
  });

export const updateOkrSchema = z
  .object({
    title: textSchema.max(200).optional(),
    description: descriptionSchema,
    dueDate: z.coerce.date().optional().nullable()
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  });

export const updateOkrStatusSchema = z
  .object({
    status: z.nativeEnum(OKRStatus)
  })
  .strict();

export const createOkrProgressSchema = z
  .object({
    progressPercent: z.number().int().min(0).max(100),
    note: noteSchema
  })
  .strict();

export const okrApprovalSchema = z
  .object({
    comment: commentSchema
  })
  .strict();

export type OkrScopeQuery = z.infer<typeof okrScopeQuerySchema>;
export type CreateOkrInput = z.infer<typeof createOkrSchema>;
export type MyOkrsQuery = z.infer<typeof myOkrsQuerySchema>;
export type AdminOkrsQuery = z.infer<typeof adminOkrsQuerySchema>;
export type UpdateOkrInput = z.infer<typeof updateOkrSchema>;
export type UpdateOkrStatusInput = z.infer<typeof updateOkrStatusSchema>;
export type CreateOkrProgressInput = z.infer<typeof createOkrProgressSchema>;
export type OkrApprovalInput = z.infer<typeof okrApprovalSchema>;
