import type { PerformanceReviewStatus } from "@prisma/client";

import { getRequiredScopedCompanyId, hasAnyRole, hasRole, isSuperAdmin } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import { AuthorizationError, ConflictError, NotFoundError, ValidationError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getPerformanceReviewsRepository,
  type PerformanceReviewRecord,
  type ReviewCycleRecord,
  type ReviewEmployeeProfileRecord,
  type UpdatePerformanceReviewRepositoryInput,
  type UpdateReviewCycleRepositoryInput
} from "./reviews.repository";
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

const getReviewScope = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

const serializeEmployee = (employee: ReviewEmployeeProfileRecord) => ({
  id: employee.id,
  companyId: employee.companyId,
  managerId: employee.managerId,
  status: employee.status
});

const serializeReviewCycle = (reviewCycle: ReviewCycleRecord) => ({
  id: reviewCycle.id,
  companyId: reviewCycle.companyId,
  name: reviewCycle.name,
  startDate: reviewCycle.startDate,
  endDate: reviewCycle.endDate,
  status: reviewCycle.status,
  createdAt: reviewCycle.createdAt,
  updatedAt: reviewCycle.updatedAt
});

const serializePerformanceReview = (review: PerformanceReviewRecord) => ({
  id: review.id,
  companyId: review.companyId,
  reviewCycleId: review.reviewCycleId,
  employeeId: review.employeeId,
  managerId: review.managerId,
  summary: review.summary,
  rating: review.rating,
  status: review.status,
  submittedAt: review.submittedAt,
  createdAt: review.createdAt,
  updatedAt: review.updatedAt,
  ...(review.reviewCycle ? { reviewCycle: serializeReviewCycle(review.reviewCycle) } : {}),
  ...(review.employee ? { employee: serializeEmployee(review.employee) } : {}),
  ...(review.manager ? { manager: serializeEmployee(review.manager) } : {})
});

const assertCompanyExists = async (companyId: string) => {
  const company = await getPerformanceReviewsRepository().findCompanyById(companyId);

  if (!company) {
    throw new NotFoundError("Company not found");
  }
};

const assertDateRange = (startDate: Date, endDate: Date) => {
  if (endDate < startDate) {
    throw new ValidationError("endDate must be on or after startDate", undefined, 400);
  }
};

const getActorEmployeeInCompany = async (actor: AuthenticatedUser, companyId: string) => {
  const employee = await getPerformanceReviewsRepository().findEmployeeByUserId(actor.id);

  return employee?.companyId === companyId ? employee : null;
};

const getRequiredActorEmployeeInCompany = async (actor: AuthenticatedUser, companyId: string) => {
  const employee = await getActorEmployeeInCompany(actor, companyId);

  if (!employee) {
    throw new AuthorizationError("Employee profile is required to submit reviews");
  }

  if (employee.status !== "ACTIVE") {
    throw new AuthorizationError("Employee profile is not active");
  }

  if (employee.companyStatus !== "ACTIVE") {
    throw new AuthorizationError("Company is not active");
  }

  return employee;
};

const getActiveSelfEmployee = async (actor: AuthenticatedUser) => {
  const employee = await getPerformanceReviewsRepository().findEmployeeByUserId(actor.id);

  if (!employee) {
    throw new AuthorizationError("Employee profile is required");
  }

  if (isSuperAdmin(actor) && !employee.companyId) {
    throw new AuthorizationError("Employee profile is required");
  }

  if (employee.status !== "ACTIVE") {
    throw new AuthorizationError("Employee profile is not active");
  }

  if (employee.companyStatus !== "ACTIVE") {
    throw new AuthorizationError("Company is not active");
  }

  return employee;
};

const isDirectReport = (employee: Pick<ReviewEmployeeProfileRecord, "managerId">, managerId: string) =>
  employee.managerId === managerId;

const canUseAdminScope = (actor: AuthenticatedUser) => hasAnyRole(actor, ["SUPER_ADMIN", "COMPANY_ADMIN", "HR_ADMIN"]);

const assertActiveEmployee = (employee: ReviewEmployeeProfileRecord) => {
  if (employee.status !== "ACTIVE") {
    throw new AuthorizationError("Employee profile is not active");
  }

  if (employee.companyStatus !== "ACTIVE") {
    throw new AuthorizationError("Company is not active");
  }
};

const assertEditableReview = (review: PerformanceReviewRecord) => {
  if (review.status === "ACKNOWLEDGED" || review.status === "ARCHIVED") {
    throw new ValidationError("Performance review is no longer editable", undefined, 400);
  }
};

const shouldSetSubmittedAt = (status: PerformanceReviewStatus) =>
  status === "SUBMITTED" || status === "ACKNOWLEDGED" || status === "ARCHIVED";

const findReviewForAnyAllowedRead = async (actor: AuthenticatedUser, reviewId: string, query: ReviewScopeQuery) => {
  if (canUseAdminScope(actor)) {
    const companyId = getReviewScope(actor, query.companyId);
    const review = await getPerformanceReviewsRepository().findPerformanceReviewByIdInCompany(reviewId, companyId);

    if (!review) {
      throw new NotFoundError("Performance review not found");
    }

    return review;
  }

  const employee = await getActiveSelfEmployee(actor);
  const review = await getPerformanceReviewsRepository().findPerformanceReviewByIdInCompany(reviewId, employee.companyId);

  if (!review) {
    throw new NotFoundError("Performance review not found");
  }

  if (
    review.employeeId === employee.id ||
    (hasRole(actor, "MANAGER") && review.employee && isDirectReport(review.employee, employee.id))
  ) {
    return review;
  }

  throw new AuthorizationError("Performance review is outside your allowed scope");
};

const findReviewForManagerOrAdminWrite = async (actor: AuthenticatedUser, reviewId: string, query: ReviewScopeQuery) => {
  if (canUseAdminScope(actor)) {
    const companyId = getReviewScope(actor, query.companyId);
    const review = await getPerformanceReviewsRepository().findPerformanceReviewByIdInCompany(reviewId, companyId);

    if (!review) {
      throw new NotFoundError("Performance review not found");
    }

    return review;
  }

  if (!hasRole(actor, "MANAGER")) {
    throw new AuthorizationError();
  }

  const manager = await getActiveSelfEmployee(actor);
  const review = await getPerformanceReviewsRepository().findPerformanceReviewByIdInCompany(reviewId, manager.companyId);

  if (!review) {
    throw new NotFoundError("Performance review not found");
  }

  if (!review.employee || !isDirectReport(review.employee, manager.id)) {
    throw new AuthorizationError("Performance review is outside your direct reports");
  }

  return review;
};

export const createReviewCycle = async (
  actor: AuthenticatedUser,
  input: CreateReviewCycleInput,
  auditContext: AuditRequestContext
) => {
  const repository = getPerformanceReviewsRepository();
  const companyId = getReviewScope(actor, input.companyId);

  await assertCompanyExists(companyId);

  const existing = await repository.findReviewCycleByNameInCompany(input.name, companyId);

  if (existing) {
    throw new ConflictError("Review cycle name already exists in this company");
  }

  const reviewCycle = await repository.createReviewCycle({
    companyId,
    name: input.name,
    startDate: input.startDate,
    endDate: input.endDate
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "PERFORMANCE",
    action: "REVIEW_CYCLE_CREATED",
    targetType: "ReviewCycle",
    targetId: reviewCycle.id,
    metadata: { status: reviewCycle.status, startDate: reviewCycle.startDate, endDate: reviewCycle.endDate },
    ...auditContext
  });

  return serializeReviewCycle(reviewCycle);
};

export const listReviewCycles = async (actor: AuthenticatedUser, query: ReviewScopeQuery) => {
  const companyId = getReviewScope(actor, query.companyId);
  const reviewCycles = await getPerformanceReviewsRepository().listReviewCyclesForCompany(companyId);

  return reviewCycles.map(serializeReviewCycle);
};

export const getReviewCycle = async (actor: AuthenticatedUser, reviewCycleId: string, query: ReviewScopeQuery) => {
  const companyId = getReviewScope(actor, query.companyId);
  const reviewCycle = await getPerformanceReviewsRepository().findReviewCycleByIdInCompany(reviewCycleId, companyId);

  if (!reviewCycle) {
    throw new NotFoundError("Review cycle not found");
  }

  return serializeReviewCycle(reviewCycle);
};

export const updateReviewCycle = async (
  actor: AuthenticatedUser,
  reviewCycleId: string,
  input: UpdateReviewCycleInput,
  query: ReviewScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getPerformanceReviewsRepository();
  const companyId = getReviewScope(actor, query.companyId);
  const current = await repository.findReviewCycleByIdInCompany(reviewCycleId, companyId);

  if (!current) {
    throw new NotFoundError("Review cycle not found");
  }

  assertDateRange(input.startDate ?? current.startDate, input.endDate ?? current.endDate);

  if (input.name && input.name !== current.name) {
    const existing = await repository.findReviewCycleByNameInCompany(input.name, companyId);

    if (existing && existing.id !== reviewCycleId) {
      throw new ConflictError("Review cycle name already exists in this company");
    }
  }

  const updateInput: UpdateReviewCycleRepositoryInput = {
    name: input.name,
    startDate: input.startDate,
    endDate: input.endDate
  };
  const updated = await repository.updateReviewCycle(reviewCycleId, companyId, updateInput);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "PERFORMANCE",
    action: "REVIEW_CYCLE_UPDATED",
    targetType: "ReviewCycle",
    targetId: reviewCycleId,
    metadata: { updatedFields: Object.keys(input) },
    ...auditContext
  });

  return serializeReviewCycle(updated);
};

export const updateReviewCycleStatus = async (
  actor: AuthenticatedUser,
  reviewCycleId: string,
  input: UpdateReviewCycleStatusInput,
  query: ReviewScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getPerformanceReviewsRepository();
  const companyId = getReviewScope(actor, query.companyId);
  const current = await repository.findReviewCycleByIdInCompany(reviewCycleId, companyId);

  if (!current) {
    throw new NotFoundError("Review cycle not found");
  }

  const updated = await repository.updateReviewCycleStatus(reviewCycleId, companyId, input.status);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "PERFORMANCE",
    action: "REVIEW_CYCLE_STATUS_CHANGED",
    targetType: "ReviewCycle",
    targetId: reviewCycleId,
    metadata: { previousStatus: current.status, status: updated.status },
    ...auditContext
  });

  return serializeReviewCycle(updated);
};

export const submitManagerReview = async (
  actor: AuthenticatedUser,
  employeeId: string,
  input: CreatePerformanceReviewInput,
  query: ReviewScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getPerformanceReviewsRepository();
  let companyId: string;
  let reviewer: ReviewEmployeeProfileRecord;

  if (hasRole(actor, "MANAGER") && !canUseAdminScope(actor)) {
    reviewer = await getActiveSelfEmployee(actor);
    companyId = getReviewScope(actor, query.companyId);
  } else if (canUseAdminScope(actor)) {
    companyId = getReviewScope(actor, query.companyId);
    await assertCompanyExists(companyId);
    reviewer = await getRequiredActorEmployeeInCompany(actor, companyId);
  } else {
    throw new AuthorizationError();
  }

  const employee = await repository.findEmployeeByIdInCompany(employeeId, companyId);

  if (!employee) {
    throw new NotFoundError("Employee not found");
  }

  assertActiveEmployee(employee);

  if (hasRole(actor, "MANAGER") && !canUseAdminScope(actor) && !isDirectReport(employee, reviewer.id)) {
    throw new AuthorizationError("Employee is outside your direct reports");
  }

  const reviewCycle = await repository.findReviewCycleByIdInCompany(input.reviewCycleId, companyId);

  if (!reviewCycle) {
    throw new NotFoundError("Review cycle not found");
  }

  if (reviewCycle.status !== "ACTIVE") {
    throw new ValidationError("Review cycle must be ACTIVE", undefined, 400);
  }

  const existing = await repository.findPerformanceReviewByEmployeeCycle(employee.id, reviewCycle.id, companyId);

  if (existing) {
    throw new ConflictError("Performance review already exists for this employee and review cycle");
  }

  const review = await repository.createPerformanceReview({
    companyId,
    reviewCycleId: reviewCycle.id,
    employeeId: employee.id,
    managerId: reviewer.id,
    summary: input.summary,
    rating: input.rating,
    status: "SUBMITTED",
    submittedAt: new Date()
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "PERFORMANCE",
    action: "PERFORMANCE_REVIEW_SUBMITTED",
    targetType: "PerformanceReview",
    targetId: review.id,
    metadata: { employeeId: employee.id, managerId: reviewer.id, reviewCycleId: reviewCycle.id, rating: review.rating },
    ...auditContext
  });

  return serializePerformanceReview(review);
};

export const listMyPerformanceReviews = async (actor: AuthenticatedUser) => {
  const employee = await getActiveSelfEmployee(actor);
  const reviews = await getPerformanceReviewsRepository().listReviewsForEmployee(employee.id);

  return reviews.map(serializePerformanceReview);
};

export const listTeamPerformanceReviews = async (actor: AuthenticatedUser) => {
  if (!hasRole(actor, "MANAGER")) {
    throw new AuthorizationError();
  }

  const manager = await getActiveSelfEmployee(actor);
  const reviews = await getPerformanceReviewsRepository().listReviewsForDirectReports(manager.id, manager.companyId);

  return reviews.map(serializePerformanceReview);
};

export const listAdminPerformanceReviews = async (actor: AuthenticatedUser, query: AdminReviewsQuery) => {
  const repository = getPerformanceReviewsRepository();
  const companyId = getReviewScope(actor, query.companyId);

  if (query.employeeId) {
    const employee = await repository.findEmployeeByIdInCompany(query.employeeId, companyId);

    if (!employee) {
      throw new NotFoundError("Employee not found");
    }
  }

  if (query.reviewCycleId) {
    const reviewCycle = await repository.findReviewCycleByIdInCompany(query.reviewCycleId, companyId);

    if (!reviewCycle) {
      throw new NotFoundError("Review cycle not found");
    }
  }

  const reviews = await repository.listReviewsForCompany(companyId, {
    employeeId: query.employeeId,
    reviewCycleId: query.reviewCycleId,
    status: query.status,
    from: query.from,
    to: query.to
  });

  return reviews.map(serializePerformanceReview);
};

export const getPerformanceReview = async (actor: AuthenticatedUser, reviewId: string, query: ReviewScopeQuery) => {
  const review = await findReviewForAnyAllowedRead(actor, reviewId, query);

  return serializePerformanceReview(review);
};

export const updatePerformanceReview = async (
  actor: AuthenticatedUser,
  reviewId: string,
  input: UpdatePerformanceReviewInput,
  query: ReviewScopeQuery,
  auditContext: AuditRequestContext
) => {
  const review = await findReviewForManagerOrAdminWrite(actor, reviewId, query);

  assertEditableReview(review);

  const updateInput: UpdatePerformanceReviewRepositoryInput = {
    summary: input.summary,
    rating: input.rating
  };
  const updated = await getPerformanceReviewsRepository().updatePerformanceReview(review.id, review.companyId, updateInput);

  await recordAuditLog({
    companyId: review.companyId,
    actorUserId: actor.id,
    category: "PERFORMANCE",
    action: "PERFORMANCE_REVIEW_UPDATED",
    targetType: "PerformanceReview",
    targetId: review.id,
    metadata: { updatedFields: Object.keys(input), employeeId: review.employeeId, reviewCycleId: review.reviewCycleId },
    ...auditContext
  });

  return serializePerformanceReview(updated);
};

export const updatePerformanceReviewStatus = async (
  actor: AuthenticatedUser,
  reviewId: string,
  input: UpdatePerformanceReviewStatusInput,
  query: ReviewScopeQuery,
  auditContext: AuditRequestContext
) => {
  const review = await findReviewForManagerOrAdminWrite(actor, reviewId, query);
  const submittedAt = shouldSetSubmittedAt(input.status) && !review.submittedAt ? new Date() : undefined;
  const updated = await getPerformanceReviewsRepository().updatePerformanceReviewStatus(review.id, review.companyId, {
    status: input.status,
    submittedAt
  });

  await recordAuditLog({
    companyId: review.companyId,
    actorUserId: actor.id,
    category: "PERFORMANCE",
    action: "PERFORMANCE_REVIEW_STATUS_CHANGED",
    targetType: "PerformanceReview",
    targetId: review.id,
    metadata: { previousStatus: review.status, status: updated.status, employeeId: review.employeeId, reviewCycleId: review.reviewCycleId },
    ...auditContext
  });

  return serializePerformanceReview(updated);
};
