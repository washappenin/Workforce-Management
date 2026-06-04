import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  createOkr,
  createOkrProgress,
  employeeApproveOkr,
  getOkr,
  listAdminOkrs,
  listMyOkrs,
  listTeamOkrs,
  managerApproveOkr,
  updateOkr,
  updateOkrStatus
} from "./okrs.service";
import type {
  AdminOkrsQuery,
  CreateOkrInput,
  CreateOkrProgressInput,
  MyOkrsQuery,
  OkrApprovalInput,
  OkrScopeQuery,
  UpdateOkrInput,
  UpdateOkrStatusInput
} from "./okrs.validation";

export const createOkrController = async (req: Request, res: Response) => {
  const okr = await createOkr(req.user!, req.body as CreateOkrInput, getAuditRequestContext(req));

  res.status(201).json({ data: { okr } });
};

export const listMyOkrsController = async (req: Request, res: Response) => {
  const okrs = await listMyOkrs(req.user!, req.query as MyOkrsQuery);

  res.status(200).json({ data: { okrs } });
};

export const listTeamOkrsController = async (req: Request, res: Response) => {
  const okrs = await listTeamOkrs(req.user!);

  res.status(200).json({ data: { okrs } });
};

export const listAdminOkrsController = async (req: Request, res: Response) => {
  const okrs = await listAdminOkrs(req.user!, req.query as AdminOkrsQuery);

  res.status(200).json({ data: { okrs } });
};

export const getOkrController = async (req: Request, res: Response) => {
  const okr = await getOkr(req.user!, req.params.okrId, req.query as OkrScopeQuery);

  res.status(200).json({ data: { okr } });
};

export const updateOkrController = async (req: Request, res: Response) => {
  const okr = await updateOkr(
    req.user!,
    req.params.okrId,
    req.body as UpdateOkrInput,
    req.query as OkrScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { okr } });
};

export const updateOkrStatusController = async (req: Request, res: Response) => {
  const okr = await updateOkrStatus(
    req.user!,
    req.params.okrId,
    req.body as UpdateOkrStatusInput,
    req.query as OkrScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { okr } });
};

export const createOkrProgressController = async (req: Request, res: Response) => {
  const result = await createOkrProgress(
    req.user!,
    req.params.okrId,
    req.body as CreateOkrProgressInput,
    getAuditRequestContext(req)
  );

  res.status(201).json({ data: result });
};

export const employeeApproveOkrController = async (req: Request, res: Response) => {
  const result = await employeeApproveOkr(
    req.user!,
    req.params.okrId,
    req.body as OkrApprovalInput,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: result });
};

export const managerApproveOkrController = async (req: Request, res: Response) => {
  const result = await managerApproveOkr(
    req.user!,
    req.params.okrId,
    req.body as OkrApprovalInput,
    req.query as OkrScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: result });
};
