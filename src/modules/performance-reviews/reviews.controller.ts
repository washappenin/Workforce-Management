import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  createReviewCycle,
  getPerformanceReview,
  getReviewCycle,
  listAdminPerformanceReviews,
  listMyPerformanceReviews,
  listReviewCycles,
  listTeamPerformanceReviews,
  submitManagerReview,
  updatePerformanceReview,
  updatePerformanceReviewStatus,
  updateReviewCycle,
  updateReviewCycleStatus
} from "./reviews.service";
import type {
  AdminReviewsQuery,
  CreatePerformanceReviewInput,
  CreateReviewCycleInput,
  ReviewScopeQuery,
  UpdatePerformanceReviewInput,
  UpdatePerformanceReviewStatusInput,
  UpdateReviewCycleInput,
  UpdateReviewCycleStatusInput
} from "./reviews.validation";

export const createReviewCycleController = async (req: Request, res: Response) => {
  const reviewCycle = await createReviewCycle(req.user!, req.body as CreateReviewCycleInput, getAuditRequestContext(req));

  res.status(201).json({ data: { reviewCycle } });
};

export const listReviewCyclesController = async (req: Request, res: Response) => {
  const reviewCycles = await listReviewCycles(req.user!, req.query as ReviewScopeQuery);

  res.status(200).json({ data: { reviewCycles } });
};

export const getReviewCycleController = async (req: Request, res: Response) => {
  const reviewCycle = await getReviewCycle(req.user!, req.params.reviewCycleId, req.query as ReviewScopeQuery);

  res.status(200).json({ data: { reviewCycle } });
};

export const updateReviewCycleController = async (req: Request, res: Response) => {
  const reviewCycle = await updateReviewCycle(
    req.user!,
    req.params.reviewCycleId,
    req.body as UpdateReviewCycleInput,
    req.query as ReviewScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { reviewCycle } });
};

export const updateReviewCycleStatusController = async (req: Request, res: Response) => {
  const reviewCycle = await updateReviewCycleStatus(
    req.user!,
    req.params.reviewCycleId,
    req.body as UpdateReviewCycleStatusInput,
    req.query as ReviewScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { reviewCycle } });
};

export const submitManagerReviewController = async (req: Request, res: Response) => {
  const review = await submitManagerReview(
    req.user!,
    req.params.employeeId,
    req.body as CreatePerformanceReviewInput,
    req.query as ReviewScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(201).json({ data: { review } });
};

export const listMyPerformanceReviewsController = async (req: Request, res: Response) => {
  const reviews = await listMyPerformanceReviews(req.user!);

  res.status(200).json({ data: { reviews } });
};

export const listTeamPerformanceReviewsController = async (req: Request, res: Response) => {
  const reviews = await listTeamPerformanceReviews(req.user!);

  res.status(200).json({ data: { reviews } });
};

export const listAdminPerformanceReviewsController = async (req: Request, res: Response) => {
  const reviews = await listAdminPerformanceReviews(req.user!, req.query as AdminReviewsQuery);

  res.status(200).json({ data: { reviews } });
};

export const getPerformanceReviewController = async (req: Request, res: Response) => {
  const review = await getPerformanceReview(req.user!, req.params.reviewId, req.query as ReviewScopeQuery);

  res.status(200).json({ data: { review } });
};

export const updatePerformanceReviewController = async (req: Request, res: Response) => {
  const review = await updatePerformanceReview(
    req.user!,
    req.params.reviewId,
    req.body as UpdatePerformanceReviewInput,
    req.query as ReviewScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { review } });
};

export const updatePerformanceReviewStatusController = async (req: Request, res: Response) => {
  const review = await updatePerformanceReviewStatus(
    req.user!,
    req.params.reviewId,
    req.body as UpdatePerformanceReviewStatusInput,
    req.query as ReviewScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { review } });
};
