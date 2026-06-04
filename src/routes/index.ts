import { Router } from "express";

import { attendanceAdminRouter, attendanceRouter } from "../modules/attendance/attendance.routes";
import { authRouter } from "../modules/auth/auth.routes";
import { companiesRouter } from "../modules/companies/companies.routes";
import { departmentsRouter } from "../modules/departments/departments.routes";
import { designationsRouter } from "../modules/designations/designations.routes";
import { employeesAdminRouter, employeesSelfRouter } from "../modules/employees/employees.routes";
import { faceAdminRouter, faceRouter } from "../modules/face-verification/face.routes";
import { geofencesAdminRouter, geofencesValidationRouter } from "../modules/geofences/geofences.routes";
import {
  leaveEntitlementsAdminRouter,
  leaveRequestsAdminRouter,
  leaveRouter,
  leaveTypesAdminRouter
} from "../modules/leave/leave.routes";
import { notificationsAdminRouter, notificationsRouter } from "../modules/notifications/notifications.routes";
import { okrsAdminRouter, okrsRouter } from "../modules/okrs/okrs.routes";
import {
  reviewCyclesAdminRouter,
  reviewsAdminRouter,
  reviewsRouter
} from "../modules/performance-reviews/reviews.routes";
import {
  adminReportsRouter,
  selfReportsRouter,
  superAdminReportsRouter,
  teamReportsRouter
} from "../modules/reports/reports.routes";
import { shiftAssignmentsAdminRouter, shiftsAdminRouter, shiftsSelfRouter } from "../modules/shifts/shifts.routes";
import {
  adminPaymentRecordsRouter,
  adminSubscriptionRouter,
  companySubscriptionsSuperAdminRouter,
  paymentRecordsSuperAdminRouter,
  subscriptionPlansSuperAdminRouter,
  subscriptionsSuperAdminRouter
} from "../modules/subscriptions/subscriptions.routes";
import { systemRouter } from "../modules/system/system.routes";

export const router = Router();

router.use(systemRouter);
router.use("/api/auth", authRouter);
router.use("/api/super-admin/companies", companiesRouter);
router.use("/api/super-admin/plans", subscriptionPlansSuperAdminRouter);
router.use("/api/super-admin/companies", companySubscriptionsSuperAdminRouter);
router.use("/api/super-admin/subscriptions", subscriptionsSuperAdminRouter);
router.use("/api/super-admin/payment-records", paymentRecordsSuperAdminRouter);
router.use("/api/admin/subscription", adminSubscriptionRouter);
router.use("/api/admin/payment-records", adminPaymentRecordsRouter);
router.use("/api/admin/departments", departmentsRouter);
router.use("/api/admin/designations", designationsRouter);
router.use("/api/admin/employees", employeesAdminRouter);
router.use("/api/employees", employeesSelfRouter);
router.use("/api/admin/employees", faceAdminRouter);
router.use("/api/face", faceRouter);
router.use("/api/admin/geofences", geofencesAdminRouter);
router.use("/api/geofences", geofencesValidationRouter);
router.use("/api/attendance", attendanceRouter);
router.use("/api/admin/attendance", attendanceAdminRouter);
router.use("/api/admin/shifts", shiftsAdminRouter);
router.use("/api/admin/shift-assignments", shiftAssignmentsAdminRouter);
router.use("/api/shifts", shiftsSelfRouter);
router.use("/api/admin/leave-types", leaveTypesAdminRouter);
router.use("/api/admin/leave-entitlements", leaveEntitlementsAdminRouter);
router.use("/api/admin/leave-requests", leaveRequestsAdminRouter);
router.use("/api/leave", leaveRouter);
router.use("/api/okrs", okrsRouter);
router.use("/api/admin/okrs", okrsAdminRouter);
router.use("/api/admin/review-cycles", reviewCyclesAdminRouter);
router.use("/api/reviews", reviewsRouter);
router.use("/api/admin/reviews", reviewsAdminRouter);
router.use("/api/notifications", notificationsRouter);
router.use("/api/admin/notifications", notificationsAdminRouter);
router.use("/api/admin/reports", adminReportsRouter);
router.use("/api/reports/team", teamReportsRouter);
router.use("/api/reports/me", selfReportsRouter);
router.use("/api/super-admin/reports", superAdminReportsRouter);
