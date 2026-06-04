import type { AuthenticatedUser, CompanyScope } from "./auth";

declare global {
  namespace Express {
    interface Request {
      id?: string;
      user?: AuthenticatedUser;
      companyId?: string;
      companyScope?: CompanyScope;
    }
  }
}

export {};
