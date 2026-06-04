import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireSuperAdmin } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  createCompanyController,
  getCompanyController,
  listCompaniesController,
  updateCompanyController,
  updateCompanyStatusController
} from "./companies.controller";
import {
  companyIdParamsSchema,
  createCompanySchema,
  updateCompanySchema,
  updateCompanyStatusSchema
} from "./companies.validation";

export const companiesRouter = Router();

companiesRouter.use(requireAuthentication, requireSuperAdmin);

companiesRouter.post("/", validateRequest({ body: createCompanySchema }, { statusCode: 400 }), asyncHandler(createCompanyController));
companiesRouter.get("/", asyncHandler(listCompaniesController));
companiesRouter.get(
  "/:companyId",
  validateRequest({ params: companyIdParamsSchema }, { statusCode: 400 }),
  asyncHandler(getCompanyController)
);
companiesRouter.patch(
  "/:companyId",
  validateRequest({ params: companyIdParamsSchema, body: updateCompanySchema }, { statusCode: 400 }),
  asyncHandler(updateCompanyController)
);
companiesRouter.patch(
  "/:companyId/status",
  validateRequest({ params: companyIdParamsSchema, body: updateCompanyStatusSchema }, { statusCode: 400 }),
  asyncHandler(updateCompanyStatusController)
);
