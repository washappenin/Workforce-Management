import { ConflictError, NotFoundError } from "../../lib/errors";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import type { AuthenticatedUser } from "../../types/auth";
import { getCompaniesRepository, type CompanyRecord } from "./companies.repository";
import type { CreateCompanyInput, UpdateCompanyInput, UpdateCompanyStatusInput } from "./companies.validation";

export const serializeCompany = (company: CompanyRecord) => ({
  id: company.id,
  name: company.name,
  status: company.status,
  contactEmail: company.contactEmail,
  contactPhone: company.contactPhone,
  billingEmail: company.billingEmail,
  address: company.address,
  country: company.country,
  timezone: company.timezone,
  createdAt: company.createdAt,
  updatedAt: company.updatedAt
});

export const createCompany = async (
  actor: AuthenticatedUser,
  input: CreateCompanyInput,
  auditContext: AuditRequestContext
) => {
  const repository = getCompaniesRepository();
  const existing = await repository.findByName(input.name);

  if (existing) {
    throw new ConflictError("Company name already exists");
  }

  const company = await repository.create(input);

  await recordAuditLog({
    companyId: company.id,
    actorUserId: actor.id,
    category: "COMPANY",
    action: "COMPANY_CREATED",
    targetType: "Company",
    targetId: company.id,
    metadata: { name: company.name, status: company.status },
    ...auditContext
  });

  return serializeCompany(company);
};

export const listCompanies = async () => {
  const companies = await getCompaniesRepository().list();

  return companies.map(serializeCompany);
};

export const getCompany = async (companyId: string) => {
  const company = await getCompaniesRepository().findById(companyId);

  if (!company) {
    throw new NotFoundError("Company not found");
  }

  return serializeCompany(company);
};

export const updateCompany = async (
  actor: AuthenticatedUser,
  companyId: string,
  input: UpdateCompanyInput,
  auditContext: AuditRequestContext
) => {
  const repository = getCompaniesRepository();
  const current = await repository.findById(companyId);

  if (!current) {
    throw new NotFoundError("Company not found");
  }

  if (input.name && input.name !== current.name) {
    const existing = await repository.findByName(input.name);

    if (existing && existing.id !== companyId) {
      throw new ConflictError("Company name already exists");
    }
  }

  const company = await repository.update(companyId, input);

  await recordAuditLog({
    companyId: company.id,
    actorUserId: actor.id,
    category: "COMPANY",
    action: "COMPANY_UPDATED",
    targetType: "Company",
    targetId: company.id,
    metadata: { updatedFields: Object.keys(input) },
    ...auditContext
  });

  return serializeCompany(company);
};

export const updateCompanyStatus = async (
  actor: AuthenticatedUser,
  companyId: string,
  input: UpdateCompanyStatusInput,
  auditContext: AuditRequestContext
) => {
  const repository = getCompaniesRepository();
  const current = await repository.findById(companyId);

  if (!current) {
    throw new NotFoundError("Company not found");
  }

  const company = await repository.updateStatus(companyId, input.status);

  await recordAuditLog({
    companyId: company.id,
    actorUserId: actor.id,
    category: "COMPANY",
    action: "COMPANY_STATUS_CHANGED",
    targetType: "Company",
    targetId: company.id,
    metadata: { previousStatus: current.status, status: company.status },
    ...auditContext
  });

  return serializeCompany(company);
};
