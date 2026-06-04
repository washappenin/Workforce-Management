import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  getFaceStatusController,
  updateFaceEnrollmentStatusController,
  upsertFaceEnrollmentController,
  verifyFaceController
} from "./face.controller";
import {
  employeeIdParamsSchema,
  faceScopeQuerySchema,
  updateFaceEnrollmentStatusSchema,
  upsertFaceEnrollmentSchema,
  verifyFaceSchema
} from "./face.validation";

export const faceAdminRouter = Router();
export const faceRouter = Router();

faceAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));

faceAdminRouter.post(
  "/:employeeId/face-enrollment",
  validateRequest({ params: employeeIdParamsSchema, body: upsertFaceEnrollmentSchema }, { statusCode: 400 }),
  asyncHandler(upsertFaceEnrollmentController)
);
faceAdminRouter.get(
  "/:employeeId/face-status",
  validateRequest({ params: employeeIdParamsSchema, query: faceScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getFaceStatusController)
);
faceAdminRouter.patch(
  "/:employeeId/face-enrollment/status",
  validateRequest(
    { params: employeeIdParamsSchema, query: faceScopeQuerySchema, body: updateFaceEnrollmentStatusSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updateFaceEnrollmentStatusController)
);

faceRouter.post(
  "/verify",
  requireAuthentication,
  validateRequest({ body: verifyFaceSchema }, { statusCode: 400 }),
  asyncHandler(verifyFaceController)
);
