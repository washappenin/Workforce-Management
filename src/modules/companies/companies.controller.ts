import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  createCompany,
  getCompany,
  listCompanies,
  updateCompany,
  updateCompanyStatus
} from "./companies.service";
import type { CreateCompanyInput, UpdateCompanyInput, UpdateCompanyStatusInput } from "./companies.validation";

export const createCompanyController = async (req: Request, res: Response) => {
  const company = await createCompany(req.user!, req.body as CreateCompanyInput, getAuditRequestContext(req));

  res.status(201).json({ data: { company } });
};

export const listCompaniesController = async (_req: Request, res: Response) => {
  const companies = await listCompanies();

  res.status(200).json({ data: { companies } });
};

export const getCompanyController = async (req: Request, res: Response) => {
  const company = await getCompany(req.params.companyId);

  res.status(200).json({ data: { company } });
};

export const updateCompanyController = async (req: Request, res: Response) => {
  const company = await updateCompany(
    req.user!,
    req.params.companyId,
    req.body as UpdateCompanyInput,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { company } });
};

export const updateCompanyStatusController = async (req: Request, res: Response) => {
  const company = await updateCompanyStatus(
    req.user!,
    req.params.companyId,
    req.body as UpdateCompanyStatusInput,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { company } });
};
