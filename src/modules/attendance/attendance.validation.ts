import { AttendanceStatus } from "@prisma/client";
import { z } from "zod";

const idSchema = z.string().trim().min(1);
const latitudeSchema = z.number().finite().min(-90).max(90);
const longitudeSchema = z.number().finite().min(-180).max(180);
const accuracyMetersSchema = z.number().finite().positive().optional();

const dateRangeFields = {
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional()
};

const validateDateRange = <T extends { from?: Date; to?: Date }>(value: T) => !value.from || !value.to || value.from <= value.to;

const dateRangeQuerySchema = z.object(dateRangeFields).refine(validateDateRange, {
    message: "from must be before or equal to to",
    path: ["to"]
  });

const attendanceLocationFields = {
  latitude: latitudeSchema,
  longitude: longitudeSchema,
  accuracyMeters: accuracyMetersSchema
};

export const clockInLocationSchema = z
  .object({
    ...attendanceLocationFields,
    faceVerificationReference: idSchema
  })
  .strict();

export const clockOutLocationSchema = z.object(attendanceLocationFields).strict();

export const myAttendanceQuerySchema = dateRangeQuerySchema;

export const adminAttendanceQuerySchema = z
  .object({
    ...dateRangeFields,
    companyId: idSchema.optional(),
    employeeId: idSchema.optional(),
    status: z.nativeEnum(AttendanceStatus).optional()
  })
  .refine(validateDateRange, {
    message: "from must be before or equal to to",
    path: ["to"]
  });

export type ClockInInput = z.infer<typeof clockInLocationSchema>;
export type ClockOutInput = z.infer<typeof clockOutLocationSchema>;
export type AttendanceLocationInput = ClockInInput | ClockOutInput;
export type MyAttendanceQuery = z.infer<typeof myAttendanceQuerySchema>;
export type AdminAttendanceQuery = z.infer<typeof adminAttendanceQuerySchema>;
