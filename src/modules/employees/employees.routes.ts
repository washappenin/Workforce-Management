import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  createEmployeeController,
  getEmployeeController,
  getMyEmployeeProfileController,
  listEmployeesController,
  updateEmployeeController,
  updateEmployeeManagerController,
  updateEmployeeStatusController
} from "./employees.controller";
import {
  createEmployeeSchema,
  employeeIdParamsSchema,
  employeeScopeQuerySchema,
  updateEmployeeManagerSchema,
  updateEmployeeSchema,
  updateEmployeeStatusSchema
} from "./employees.validation";

export const employeesAdminRouter = Router();
export const employeesSelfRouter = Router();

employeesAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));

employeesAdminRouter.post(
  "/",
  validateRequest({ body: createEmployeeSchema }, { statusCode: 400 }),
  asyncHandler(createEmployeeController)
);
employeesAdminRouter.get(
  "/",
  validateRequest({ query: employeeScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(listEmployeesController)
);
employeesAdminRouter.get(
  "/:employeeId",
  validateRequest({ params: employeeIdParamsSchema, query: employeeScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getEmployeeController)
);
employeesAdminRouter.patch(
  "/:employeeId",
  validateRequest({ params: employeeIdParamsSchema, query: employeeScopeQuerySchema, body: updateEmployeeSchema }, { statusCode: 400 }),
  asyncHandler(updateEmployeeController)
);
employeesAdminRouter.patch(
  "/:employeeId/status",
  validateRequest({ params: employeeIdParamsSchema, query: employeeScopeQuerySchema, body: updateEmployeeStatusSchema }, { statusCode: 400 }),
  asyncHandler(updateEmployeeStatusController)
);
employeesAdminRouter.patch(
  "/:employeeId/manager",
  validateRequest({ params: employeeIdParamsSchema, query: employeeScopeQuerySchema, body: updateEmployeeManagerSchema }, { statusCode: 400 }),
  asyncHandler(updateEmployeeManagerController)
);

employeesSelfRouter.get("/me", requireAuthentication, asyncHandler(getMyEmployeeProfileController));
