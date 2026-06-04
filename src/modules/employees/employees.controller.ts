import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  createEmployee,
  getEmployee,
  getMyEmployeeProfile,
  listEmployees,
  updateEmployee,
  updateEmployeeManager,
  updateEmployeeStatus
} from "./employees.service";
import type {
  CreateEmployeeInput,
  EmployeeScopeQuery,
  UpdateEmployeeInput,
  UpdateEmployeeManagerInput,
  UpdateEmployeeStatusInput
} from "./employees.validation";

export const createEmployeeController = async (req: Request, res: Response) => {
  const employee = await createEmployee(req.user!, req.body as CreateEmployeeInput, getAuditRequestContext(req));

  res.status(201).json({ data: { employee } });
};

export const listEmployeesController = async (req: Request, res: Response) => {
  const employees = await listEmployees(req.user!, req.query as EmployeeScopeQuery);

  res.status(200).json({ data: { employees } });
};

export const getEmployeeController = async (req: Request, res: Response) => {
  const employee = await getEmployee(req.user!, req.params.employeeId, req.query as EmployeeScopeQuery);

  res.status(200).json({ data: { employee } });
};

export const getMyEmployeeProfileController = async (req: Request, res: Response) => {
  const employee = await getMyEmployeeProfile(req.user!);

  res.status(200).json({ data: { employee } });
};

export const updateEmployeeController = async (req: Request, res: Response) => {
  const employee = await updateEmployee(
    req.user!,
    req.params.employeeId,
    req.body as UpdateEmployeeInput,
    req.query as EmployeeScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { employee } });
};

export const updateEmployeeStatusController = async (req: Request, res: Response) => {
  const employee = await updateEmployeeStatus(
    req.user!,
    req.params.employeeId,
    req.body as UpdateEmployeeStatusInput,
    req.query as EmployeeScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { employee } });
};

export const updateEmployeeManagerController = async (req: Request, res: Response) => {
  const employee = await updateEmployeeManager(
    req.user!,
    req.params.employeeId,
    req.body as UpdateEmployeeManagerInput,
    req.query as EmployeeScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { employee } });
};
