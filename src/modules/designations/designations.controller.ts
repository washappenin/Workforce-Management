import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  createDesignation,
  getDesignation,
  listDesignations,
  updateDesignation,
  updateDesignationStatus
} from "./designations.service";
import type {
  CreateDesignationInput,
  DesignationScopeQuery,
  UpdateDesignationInput,
  UpdateDesignationStatusInput
} from "./designations.validation";

export const createDesignationController = async (req: Request, res: Response) => {
  const designation = await createDesignation(req.user!, req.body as CreateDesignationInput, getAuditRequestContext(req));

  res.status(201).json({ data: { designation } });
};

export const listDesignationsController = async (req: Request, res: Response) => {
  const designations = await listDesignations(req.user!, req.query as DesignationScopeQuery);

  res.status(200).json({ data: { designations } });
};

export const getDesignationController = async (req: Request, res: Response) => {
  const designation = await getDesignation(req.user!, req.params.designationId, req.query as DesignationScopeQuery);

  res.status(200).json({ data: { designation } });
};

export const updateDesignationController = async (req: Request, res: Response) => {
  const designation = await updateDesignation(
    req.user!,
    req.params.designationId,
    req.body as UpdateDesignationInput,
    req.query as DesignationScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { designation } });
};

export const updateDesignationStatusController = async (req: Request, res: Response) => {
  const designation = await updateDesignationStatus(
    req.user!,
    req.params.designationId,
    req.body as UpdateDesignationStatusInput,
    req.query as DesignationScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { designation } });
};
