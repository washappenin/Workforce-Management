import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  createCompanySubscription,
  createPaymentRecord,
  createSubscriptionPlan,
  getAdminCompanySubscription,
  getCompanySubscription,
  getSubscriptionPlan,
  listAdminCompanyPaymentRecords,
  listCompanyPaymentRecords,
  listCompanySubscriptions,
  listPaymentRecords,
  listSubscriptionPlans,
  updateCompanySubscriptionStatus,
  updateSubscriptionPlan,
  updateSubscriptionPlanStatus
} from "./subscriptions.service";
import type {
  AdminBillingQuery,
  CompanyPaymentRecordsQuery,
  CreateCompanySubscriptionInput,
  CreatePaymentRecordInput,
  CreateSubscriptionPlanInput,
  ListPaymentRecordsQuery,
  ListSubscriptionPlansQuery,
  ListSubscriptionsQuery,
  UpdateCompanySubscriptionStatusInput,
  UpdateSubscriptionPlanInput,
  UpdateSubscriptionPlanStatusInput
} from "./subscriptions.validation";

export const createSubscriptionPlanController = async (req: Request, res: Response) => {
  const plan = await createSubscriptionPlan(req.user!, req.body as CreateSubscriptionPlanInput, getAuditRequestContext(req));

  res.status(201).json({ data: { plan } });
};

export const listSubscriptionPlansController = async (req: Request, res: Response) => {
  const plans = await listSubscriptionPlans(req.user!, req.query as ListSubscriptionPlansQuery);

  res.status(200).json({ data: { plans } });
};

export const getSubscriptionPlanController = async (req: Request, res: Response) => {
  const plan = await getSubscriptionPlan(req.user!, req.params.planId);

  res.status(200).json({ data: { plan } });
};

export const updateSubscriptionPlanController = async (req: Request, res: Response) => {
  const plan = await updateSubscriptionPlan(
    req.user!,
    req.params.planId,
    req.body as UpdateSubscriptionPlanInput,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { plan } });
};

export const updateSubscriptionPlanStatusController = async (req: Request, res: Response) => {
  const plan = await updateSubscriptionPlanStatus(
    req.user!,
    req.params.planId,
    req.body as UpdateSubscriptionPlanStatusInput,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { plan } });
};

export const createCompanySubscriptionController = async (req: Request, res: Response) => {
  const subscription = await createCompanySubscription(
    req.user!,
    req.params.companyId,
    req.body as CreateCompanySubscriptionInput,
    getAuditRequestContext(req)
  );

  res.status(201).json({ data: { subscription } });
};

export const listCompanySubscriptionsController = async (req: Request, res: Response) => {
  const subscriptions = await listCompanySubscriptions(req.user!, req.query as ListSubscriptionsQuery);

  res.status(200).json({ data: { subscriptions } });
};

export const getCompanySubscriptionController = async (req: Request, res: Response) => {
  const subscription = await getCompanySubscription(req.user!, req.params.companyId);

  res.status(200).json({ data: { subscription } });
};

export const updateCompanySubscriptionStatusController = async (req: Request, res: Response) => {
  const subscription = await updateCompanySubscriptionStatus(
    req.user!,
    req.params.subscriptionId,
    req.body as UpdateCompanySubscriptionStatusInput,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { subscription } });
};

export const createPaymentRecordController = async (req: Request, res: Response) => {
  const paymentRecord = await createPaymentRecord(req.user!, req.body as CreatePaymentRecordInput, getAuditRequestContext(req));

  res.status(201).json({ data: { paymentRecord } });
};

export const listPaymentRecordsController = async (req: Request, res: Response) => {
  const paymentRecords = await listPaymentRecords(req.user!, req.query as ListPaymentRecordsQuery);

  res.status(200).json({ data: { paymentRecords } });
};

export const listCompanyPaymentRecordsController = async (req: Request, res: Response) => {
  const paymentRecords = await listCompanyPaymentRecords(
    req.user!,
    req.params.companyId,
    req.query as CompanyPaymentRecordsQuery
  );

  res.status(200).json({ data: { paymentRecords } });
};

export const getAdminCompanySubscriptionController = async (req: Request, res: Response) => {
  const subscription = await getAdminCompanySubscription(req.user!, req.query as AdminBillingQuery);

  res.status(200).json({ data: { subscription } });
};

export const listAdminCompanyPaymentRecordsController = async (req: Request, res: Response) => {
  const paymentRecords = await listAdminCompanyPaymentRecords(req.user!, req.query as AdminBillingQuery);

  res.status(200).json({ data: { paymentRecords } });
};
