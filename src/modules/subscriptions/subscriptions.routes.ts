import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole, requireSuperAdmin } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  createCompanySubscriptionController,
  createPaymentRecordController,
  createSubscriptionPlanController,
  getAdminCompanySubscriptionController,
  getCompanySubscriptionController,
  getSubscriptionPlanController,
  listAdminCompanyPaymentRecordsController,
  listCompanyPaymentRecordsController,
  listCompanySubscriptionsController,
  listPaymentRecordsController,
  listSubscriptionPlansController,
  updateCompanySubscriptionStatusController,
  updateSubscriptionPlanController,
  updateSubscriptionPlanStatusController
} from "./subscriptions.controller";
import {
  adminBillingQuerySchema,
  companyIdParamsSchema,
  companyPaymentRecordsQuerySchema,
  createCompanySubscriptionSchema,
  createPaymentRecordSchema,
  createSubscriptionPlanSchema,
  listPaymentRecordsQuerySchema,
  listSubscriptionPlansQuerySchema,
  listSubscriptionsQuerySchema,
  planIdParamsSchema,
  subscriptionIdParamsSchema,
  updateCompanySubscriptionStatusSchema,
  updateSubscriptionPlanSchema,
  updateSubscriptionPlanStatusSchema
} from "./subscriptions.validation";

export const subscriptionPlansSuperAdminRouter = Router();
export const companySubscriptionsSuperAdminRouter = Router();
export const subscriptionsSuperAdminRouter = Router();
export const paymentRecordsSuperAdminRouter = Router();
export const adminSubscriptionRouter = Router();
export const adminPaymentRecordsRouter = Router();

subscriptionPlansSuperAdminRouter.use(requireAuthentication, requireSuperAdmin);
companySubscriptionsSuperAdminRouter.use(requireAuthentication, requireSuperAdmin);
subscriptionsSuperAdminRouter.use(requireAuthentication, requireSuperAdmin);
paymentRecordsSuperAdminRouter.use(requireAuthentication, requireSuperAdmin);

subscriptionPlansSuperAdminRouter.post(
  "/",
  validateRequest({ body: createSubscriptionPlanSchema }, { statusCode: 400 }),
  asyncHandler(createSubscriptionPlanController)
);
subscriptionPlansSuperAdminRouter.get(
  "/",
  validateRequest({ query: listSubscriptionPlansQuerySchema }, { statusCode: 400 }),
  asyncHandler(listSubscriptionPlansController)
);
subscriptionPlansSuperAdminRouter.get(
  "/:planId",
  validateRequest({ params: planIdParamsSchema }, { statusCode: 400 }),
  asyncHandler(getSubscriptionPlanController)
);
subscriptionPlansSuperAdminRouter.patch(
  "/:planId",
  validateRequest({ params: planIdParamsSchema, body: updateSubscriptionPlanSchema }, { statusCode: 400 }),
  asyncHandler(updateSubscriptionPlanController)
);
subscriptionPlansSuperAdminRouter.patch(
  "/:planId/status",
  validateRequest({ params: planIdParamsSchema, body: updateSubscriptionPlanStatusSchema }, { statusCode: 400 }),
  asyncHandler(updateSubscriptionPlanStatusController)
);

companySubscriptionsSuperAdminRouter.post(
  "/:companyId/subscription",
  validateRequest({ params: companyIdParamsSchema, body: createCompanySubscriptionSchema }, { statusCode: 400 }),
  asyncHandler(createCompanySubscriptionController)
);
companySubscriptionsSuperAdminRouter.get(
  "/:companyId/subscription",
  validateRequest({ params: companyIdParamsSchema }, { statusCode: 400 }),
  asyncHandler(getCompanySubscriptionController)
);
companySubscriptionsSuperAdminRouter.get(
  "/:companyId/payment-records",
  validateRequest({ params: companyIdParamsSchema, query: companyPaymentRecordsQuerySchema }, { statusCode: 400 }),
  asyncHandler(listCompanyPaymentRecordsController)
);

subscriptionsSuperAdminRouter.get(
  "/",
  validateRequest({ query: listSubscriptionsQuerySchema }, { statusCode: 400 }),
  asyncHandler(listCompanySubscriptionsController)
);
subscriptionsSuperAdminRouter.patch(
  "/:subscriptionId/status",
  validateRequest(
    { params: subscriptionIdParamsSchema, body: updateCompanySubscriptionStatusSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updateCompanySubscriptionStatusController)
);

paymentRecordsSuperAdminRouter.post(
  "/",
  validateRequest({ body: createPaymentRecordSchema }, { statusCode: 400 }),
  asyncHandler(createPaymentRecordController)
);
paymentRecordsSuperAdminRouter.get(
  "/",
  validateRequest({ query: listPaymentRecordsQuerySchema }, { statusCode: 400 }),
  asyncHandler(listPaymentRecordsController)
);

adminSubscriptionRouter.use(requireAuthentication, requireAnyRole(["COMPANY_ADMIN", "HR_ADMIN"]));
adminSubscriptionRouter.get(
  "/",
  validateRequest({ query: adminBillingQuerySchema }, { statusCode: 400 }),
  asyncHandler(getAdminCompanySubscriptionController)
);

adminPaymentRecordsRouter.use(requireAuthentication, requireAnyRole(["COMPANY_ADMIN", "HR_ADMIN"]));
adminPaymentRecordsRouter.get(
  "/",
  validateRequest({ query: adminBillingQuerySchema }, { statusCode: 400 }),
  asyncHandler(listAdminCompanyPaymentRecordsController)
);
