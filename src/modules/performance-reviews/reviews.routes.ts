import { Router } from "express";

import { asyncHandler } from "../../middleware/asyncHandler";
import { requireAuthentication } from "../../middleware/auth.middleware";
import { requireAnyRole } from "../../middleware/role.middleware";
import { validateRequest } from "../../middleware/validation.middleware";
import {
  createReviewCycleController,
  getPerformanceReviewController,
  getReviewCycleController,
  listAdminPerformanceReviewsController,
  listMyPerformanceReviewsController,
  listReviewCyclesController,
  listTeamPerformanceReviewsController,
  submitManagerReviewController,
  updatePerformanceReviewController,
  updatePerformanceReviewStatusController,
  updateReviewCycleController,
  updateReviewCycleStatusController
} from "./reviews.controller";
import {
  adminReviewsQuerySchema,
  createPerformanceReviewSchema,
  createReviewCycleSchema,
  reviewCycleIdParamsSchema,
  reviewEmployeeIdParamsSchema,
  reviewIdParamsSchema,
  reviewScopeQuerySchema,
  updatePerformanceReviewSchema,
  updatePerformanceReviewStatusSchema,
  updateReviewCycleSchema,
  updateReviewCycleStatusSchema
} from "./reviews.validation";

export const reviewCyclesAdminRouter = Router();
export const reviewsRouter = Router();
export const reviewsAdminRouter = Router();

reviewCyclesAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));
reviewCyclesAdminRouter.post(
  "/",
  validateRequest({ body: createReviewCycleSchema }, { statusCode: 400 }),
  asyncHandler(createReviewCycleController)
);
reviewCyclesAdminRouter.get(
  "/",
  validateRequest({ query: reviewScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(listReviewCyclesController)
);
reviewCyclesAdminRouter.get(
  "/:reviewCycleId",
  validateRequest({ params: reviewCycleIdParamsSchema, query: reviewScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getReviewCycleController)
);
reviewCyclesAdminRouter.patch(
  "/:reviewCycleId",
  validateRequest({ params: reviewCycleIdParamsSchema, query: reviewScopeQuerySchema, body: updateReviewCycleSchema }, { statusCode: 400 }),
  asyncHandler(updateReviewCycleController)
);
reviewCyclesAdminRouter.patch(
  "/:reviewCycleId/status",
  validateRequest(
    { params: reviewCycleIdParamsSchema, query: reviewScopeQuerySchema, body: updateReviewCycleStatusSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updateReviewCycleStatusController)
);

reviewsRouter.post(
  "/:employeeId/manager-review",
  requireAuthentication,
  requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER"]),
  validateRequest(
    { params: reviewEmployeeIdParamsSchema, query: reviewScopeQuerySchema, body: createPerformanceReviewSchema },
    { statusCode: 400 }
  ),
  asyncHandler(submitManagerReviewController)
);
reviewsRouter.get("/me", requireAuthentication, asyncHandler(listMyPerformanceReviewsController));
reviewsRouter.get(
  "/team",
  requireAuthentication,
  requireAnyRole(["MANAGER"]),
  asyncHandler(listTeamPerformanceReviewsController)
);
reviewsRouter.get(
  "/:reviewId",
  requireAuthentication,
  validateRequest({ params: reviewIdParamsSchema, query: reviewScopeQuerySchema }, { statusCode: 400 }),
  asyncHandler(getPerformanceReviewController)
);
reviewsRouter.patch(
  "/:reviewId",
  requireAuthentication,
  requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER"]),
  validateRequest(
    { params: reviewIdParamsSchema, query: reviewScopeQuerySchema, body: updatePerformanceReviewSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updatePerformanceReviewController)
);
reviewsRouter.patch(
  "/:reviewId/status",
  requireAuthentication,
  requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN", "MANAGER"]),
  validateRequest(
    { params: reviewIdParamsSchema, query: reviewScopeQuerySchema, body: updatePerformanceReviewStatusSchema },
    { statusCode: 400 }
  ),
  asyncHandler(updatePerformanceReviewStatusController)
);

reviewsAdminRouter.use(requireAuthentication, requireAnyRole(["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]));
reviewsAdminRouter.get(
  "/",
  validateRequest({ query: adminReviewsQuerySchema }, { statusCode: 400 }),
  asyncHandler(listAdminPerformanceReviewsController)
);
