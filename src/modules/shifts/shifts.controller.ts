import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  assignShift,
  createShift,
  deleteShiftAssignment,
  getShift,
  listMyShiftAssignments,
  listShiftAssignments,
  listShifts,
  updateShift,
  updateShiftAssignment,
  updateShiftStatus
} from "./shifts.service";
import type {
  AssignShiftInput,
  CreateShiftInput,
  ShiftScopeQuery,
  UpdateShiftAssignmentInput,
  UpdateShiftInput,
  UpdateShiftStatusInput
} from "./shifts.validation";

export const createShiftController = async (req: Request, res: Response) => {
  const shift = await createShift(req.user!, req.body as CreateShiftInput, getAuditRequestContext(req));

  res.status(201).json({ data: { shift } });
};

export const listShiftsController = async (req: Request, res: Response) => {
  const shifts = await listShifts(req.user!, req.query as ShiftScopeQuery);

  res.status(200).json({ data: { shifts } });
};

export const getShiftController = async (req: Request, res: Response) => {
  const shift = await getShift(req.user!, req.params.shiftId, req.query as ShiftScopeQuery);

  res.status(200).json({ data: { shift } });
};

export const updateShiftController = async (req: Request, res: Response) => {
  const shift = await updateShift(
    req.user!,
    req.params.shiftId,
    req.body as UpdateShiftInput,
    req.query as ShiftScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { shift } });
};

export const updateShiftStatusController = async (req: Request, res: Response) => {
  const shift = await updateShiftStatus(
    req.user!,
    req.params.shiftId,
    req.body as UpdateShiftStatusInput,
    req.query as ShiftScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { shift } });
};

export const assignShiftController = async (req: Request, res: Response) => {
  const assignment = await assignShift(
    req.user!,
    req.params.shiftId,
    req.body as AssignShiftInput,
    req.query as ShiftScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(201).json({ data: { assignment } });
};

export const listShiftAssignmentsController = async (req: Request, res: Response) => {
  const assignments = await listShiftAssignments(req.user!, req.params.shiftId, req.query as ShiftScopeQuery);

  res.status(200).json({ data: { assignments } });
};

export const updateShiftAssignmentController = async (req: Request, res: Response) => {
  const assignment = await updateShiftAssignment(
    req.user!,
    req.params.assignmentId,
    req.body as UpdateShiftAssignmentInput,
    req.query as ShiftScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { assignment } });
};

export const deleteShiftAssignmentController = async (req: Request, res: Response) => {
  const result = await deleteShiftAssignment(
    req.user!,
    req.params.assignmentId,
    req.query as ShiftScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: result });
};

export const listMyShiftAssignmentsController = async (req: Request, res: Response) => {
  const assignments = await listMyShiftAssignments(req.user!);

  res.status(200).json({ data: { assignments } });
};
