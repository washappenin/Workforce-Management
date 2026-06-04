import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  createGeofenceController,
  getGeofenceController,
  listGeofencesController,
  updateGeofenceController,
  updateGeofenceStatusController,
  validateLocationController
} from "./geofences.controller";
import {
  createGeofenceSchema,
  geofenceIdParamsSchema,
  geofenceScopeQuerySchema,
  updateGeofenceSchema,
  updateGeofenceStatusSchema,
  validateLocationSchema
} from "./geofences.validation";

export const geofencesAdminRouter = Router();
export const geofencesValidationRouter = Router();

geofencesAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));

geofencesAdminRouter.post(
  "/",
  validateRequest({ body: createGeofenceSchema }, { statusCode: 400 }),
  asyncHandler(createGeofenceController)
);
geofencesAdminRouter.get(
  "/",
  validateRequest({ query: geofenceScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(listGeofencesController)
);
geofencesAdminRouter.get(
  "/:geofenceId",
  validateRequest({ params: geofenceIdParamsSchema, query: geofenceScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getGeofenceController)
);
geofencesAdminRouter.patch(
  "/:geofenceId",
  validateRequest({ params: geofenceIdParamsSchema, query: geofenceScopeQuerySchema, body: updateGeofenceSchema }, { statusCode: 400 }),
  asyncHandler(updateGeofenceController)
);
geofencesAdminRouter.patch(
  "/:geofenceId/status",
  validateRequest(
    { params: geofenceIdParamsSchema, query: geofenceScopeQuerySchema, body: updateGeofenceStatusSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updateGeofenceStatusController)
);

geofencesValidationRouter.post(
  "/validate-location",
  requireAuthentication,
  validateRequest({ body: validateLocationSchema }, { statusCode: 400 }),
  asyncHandler(validateLocationController)
);
