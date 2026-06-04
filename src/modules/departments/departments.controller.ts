import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  createDepartment,
  getDepartment,
  listDepartments,
  updateDepartment,
  updateDepartmentStatus
} from "./departments.service";
import type {
  CreateDepartmentInput,
  DepartmentScopeQuery,
  UpdateDepartmentInput,
  UpdateDepartmentStatusInput
} from "./departments.validation";

export const createDepartmentController = async (req: Request, res: Response) => {
  const department = await createDepartment(req.user!, req.body as CreateDepartmentInput, getAuditRequestContext(req));

  res.status(201).json({ data: { department } });
};

export const listDepartmentsController = async (req: Request, res: Response) => {
  const departments = await listDepartments(req.user!, req.query as DepartmentScopeQuery);

  res.status(200).json({ data: { departments } });
};

export const getDepartmentController = async (req: Request, res: Response) => {
  const department = await getDepartment(req.user!, req.params.departmentId, req.query as DepartmentScopeQuery);

  res.status(200).json({ data: { department } });
};

export const updateDepartmentController = async (req: Request, res: Response) => {
  const department = await updateDepartment(
    req.user!,
    req.params.departmentId,
    req.body as UpdateDepartmentInput,
    req.query as DepartmentScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { department } });
};

export const updateDepartmentStatusController = async (req: Request, res: Response) => {
  const department = await updateDepartmentStatus(
    req.user!,
    req.params.departmentId,
    req.body as UpdateDepartmentStatusInput,
    req.query as DepartmentScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { department } });
};
