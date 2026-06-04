import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  approveLeaveRequest,
  createLeaveType,
  getLeaveEntitlement,
  getLeaveType,
  listAdminLeaveRequests,
  listLeaveEntitlements,
  listLeaveTypes,
  listMyLeave,
  listTeamLeaveRequests,
  rejectLeaveRequest,
  submitLeaveRequest,
  updateLeaveEntitlement,
  updateLeaveType,
  updateLeaveTypeStatus,
  upsertLeaveEntitlement
} from "./leave.service";
import type {
  AdminLeaveRequestsQuery,
  CreateLeaveEntitlementInput,
  CreateLeaveRequestInput,
  CreateLeaveTypeInput,
  LeaveEntitlementsQuery,
  LeaveScopeQuery,
  MyLeaveQuery,
  ReviewLeaveRequestInput,
  UpdateLeaveEntitlementInput,
  UpdateLeaveTypeInput,
  UpdateLeaveTypeStatusInput
} from "./leave.validation";

export const createLeaveTypeController = async (req: Request, res: Response) => {
  const leaveType = await createLeaveType(req.user!, req.body as CreateLeaveTypeInput, getAuditRequestContext(req));

  res.status(201).json({ data: { leaveType } });
};

export const listLeaveTypesController = async (req: Request, res: Response) => {
  const leaveTypes = await listLeaveTypes(req.user!, req.query as LeaveScopeQuery);

  res.status(200).json({ data: { leaveTypes } });
};

export const getLeaveTypeController = async (req: Request, res: Response) => {
  const leaveType = await getLeaveType(req.user!, req.params.leaveTypeId, req.query as LeaveScopeQuery);

  res.status(200).json({ data: { leaveType } });
};

export const updateLeaveTypeController = async (req: Request, res: Response) => {
  const leaveType = await updateLeaveType(
    req.user!,
    req.params.leaveTypeId,
    req.body as UpdateLeaveTypeInput,
    req.query as LeaveScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { leaveType } });
};

export const updateLeaveTypeStatusController = async (req: Request, res: Response) => {
  const leaveType = await updateLeaveTypeStatus(
    req.user!,
    req.params.leaveTypeId,
    req.body as UpdateLeaveTypeStatusInput,
    req.query as LeaveScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { leaveType } });
};

export const upsertLeaveEntitlementController = async (req: Request, res: Response) => {
  const entitlement = await upsertLeaveEntitlement(
    req.user!,
    req.body as CreateLeaveEntitlementInput,
    getAuditRequestContext(req)
  );

  res.status(201).json({ data: { entitlement } });
};

export const listLeaveEntitlementsController = async (req: Request, res: Response) => {
  const entitlements = await listLeaveEntitlements(req.user!, req.query as LeaveEntitlementsQuery);

  res.status(200).json({ data: { entitlements } });
};

export const getLeaveEntitlementController = async (req: Request, res: Response) => {
  const entitlement = await getLeaveEntitlement(req.user!, req.params.entitlementId, req.query as LeaveScopeQuery);

  res.status(200).json({ data: { entitlement } });
};

export const updateLeaveEntitlementController = async (req: Request, res: Response) => {
  const entitlement = await updateLeaveEntitlement(
    req.user!,
    req.params.entitlementId,
    req.body as UpdateLeaveEntitlementInput,
    req.query as LeaveScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { entitlement } });
};

export const submitLeaveRequestController = async (req: Request, res: Response) => {
  const leaveRequest = await submitLeaveRequest(
    req.user!,
    req.body as CreateLeaveRequestInput,
    getAuditRequestContext(req)
  );

  res.status(201).json({ data: { leaveRequest } });
};

export const listMyLeaveController = async (req: Request, res: Response) => {
  const result = await listMyLeave(req.user!, req.query as MyLeaveQuery);

  res.status(200).json({ data: result });
};

export const listTeamLeaveRequestsController = async (req: Request, res: Response) => {
  const leaveRequests = await listTeamLeaveRequests(req.user!);

  res.status(200).json({ data: { leaveRequests } });
};

export const listAdminLeaveRequestsController = async (req: Request, res: Response) => {
  const leaveRequests = await listAdminLeaveRequests(req.user!, req.query as AdminLeaveRequestsQuery);

  res.status(200).json({ data: { leaveRequests } });
};

export const approveLeaveRequestController = async (req: Request, res: Response) => {
  const leaveRequest = await approveLeaveRequest(
    req.user!,
    req.params.leaveRequestId,
    req.body as ReviewLeaveRequestInput,
    req.query as LeaveScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { leaveRequest } });
};

export const rejectLeaveRequestController = async (req: Request, res: Response) => {
  const leaveRequest = await rejectLeaveRequest(
    req.user!,
    req.params.leaveRequestId,
    req.body as ReviewLeaveRequestInput,
    req.query as LeaveScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { leaveRequest } });
};
