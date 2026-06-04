import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  createDepartmentController,
  getDepartmentController,
  listDepartmentsController,
  updateDepartmentController,
  updateDepartmentStatusController
} from "./departments.controller";
import {
  createDepartmentSchema,
  departmentIdParamsSchema,
  departmentScopeQuerySchema,
  updateDepartmentSchema,
  updateDepartmentStatusSchema
} from "./departments.validation";

export const departmentsRouter = Router();

departmentsRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));

departmentsRouter.post(
  "/",
  validateRequest({ body: createDepartmentSchema }, { statusCode: 400 }),
  asyncHandler(createDepartmentController)
);
departmentsRouter.get(
  "/",
  validateRequest({ query: departmentScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(listDepartmentsController)
);
departmentsRouter.get(
  "/:departmentId",
  validateRequest({ params: departmentIdParamsSchema, query: departmentScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getDepartmentController)
);
departmentsRouter.patch(
  "/:departmentId",
  validateRequest({ params: departmentIdParamsSchema, query: departmentScopeQuerySchema, body: updateDepartmentSchema }, { statusCode: 400 }),
  asyncHandler(updateDepartmentController)
);
departmentsRouter.patch(
  "/:departmentId/status",
  validateRequest(
    { params: departmentIdParamsSchema, query: departmentScopeQuerySchema, body: updateDepartmentStatusSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updateDepartmentStatusController)
);
