import { GeofenceStatus } from "@prisma/client";
import { z } from "zod";

export const maxGeofenceRadiusMeters = 50_000;

const idSchema = z.string().trim().min(1);
const latitudeSchema = z.number().finite().min(-90).max(90);
const longitudeSchema = z.number().finite().min(-180).max(180);
const radiusMetersSchema = z.number().int().positive().max(maxGeofenceRadiusMeters);

export const geofenceIdParamsSchema = z.object({
  geofenceId: idSchema
});

export const geofenceScopeQuerySchema = z.object({
  companyId: idSchema.optional()
});

export const createGeofenceSchema = z
  .object({
    companyId: idSchema.optional(),
    name: z.string().trim().min(1),
    latitude: latitudeSchema,
    longitude: longitudeSchema,
    radiusMeters: radiusMetersSchema,
    status: z.nativeEnum(GeofenceStatus).optional()
  })
  .strict();

export const updateGeofenceSchema = z
  .object({
    name: z.string().trim().min(1).optional(),
    latitude: latitudeSchema.optional(),
    longitude: longitudeSchema.optional(),
    radiusMeters: radiusMetersSchema.optional()
  })
  .strict()
  .refine((value) => Object.keys(value).length > 0, {
    message: "At least one field is required"
  });

export const updateGeofenceStatusSchema = z
  .object({
    status: z.nativeEnum(GeofenceStatus)
  })
  .strict();

export const validateLocationSchema = z
  .object({
    companyId: idSchema.optional(),
    latitude: latitudeSchema,
    longitude: longitudeSchema
  })
  .strict();

export type GeofenceScopeQuery = z.infer<typeof geofenceScopeQuerySchema>;
export type CreateGeofenceInput = z.infer<typeof createGeofenceSchema>;
export type UpdateGeofenceInput = z.infer<typeof updateGeofenceSchema>;
export type UpdateGeofenceStatusInput = z.infer<typeof updateGeofenceStatusSchema>;
export type ValidateLocationInput = z.infer<typeof validateLocationSchema>;
