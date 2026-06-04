import type { Request, Response } from "express";

import {
  getAdminAttendanceReport,
  getAdminDashboardReport,
  getAdminLeaveReport,
  getAdminOkrReport,
  getAdminPerformanceReport,
  getMyDashboardReport,
  getSuperAdminCompanyReports,
  getSuperAdminDashboardReport,
  getTeamAttendanceReport,
  getTeamDashboardReport,
  getTeamLeaveReport,
  getTeamOkrReport,
  getTeamPerformanceReport
} from "./reports.service";
import type {
  AttendanceReportQuery,
  CompanyScopeReportQuery,
  LeaveReportQuery,
  OkrReportQuery,
  PerformanceReportQuery
} from "./reports.validation";

export const getAdminDashboardReportController = async (req: Request, res: Response) => {
  const dashboard = await getAdminDashboardReport(req.user!, req.query as CompanyScopeReportQuery);

  res.status(200).json({ data: { dashboard } });
};

export const getAdminAttendanceReportController = async (req: Request, res: Response) => {
  const report = await getAdminAttendanceReport(req.user!, req.query as AttendanceReportQuery);

  res.status(200).json({ data: { report } });
};

export const getAdminLeaveReportController = async (req: Request, res: Response) => {
  const report = await getAdminLeaveReport(req.user!, req.query as LeaveReportQuery);

  res.status(200).json({ data: { report } });
};

export const getAdminOkrReportController = async (req: Request, res: Response) => {
  const report = await getAdminOkrReport(req.user!, req.query as OkrReportQuery);

  res.status(200).json({ data: { report } });
};

export const getAdminPerformanceReportController = async (req: Request, res: Response) => {
  const report = await getAdminPerformanceReport(req.user!, req.query as PerformanceReportQuery);

  res.status(200).json({ data: { report } });
};

export const getTeamDashboardReportController = async (req: Request, res: Response) => {
  const dashboard = await getTeamDashboardReport(req.user!, req.query as CompanyScopeReportQuery);

  res.status(200).json({ data: { dashboard } });
};

export const getTeamAttendanceReportController = async (req: Request, res: Response) => {
  const report = await getTeamAttendanceReport(req.user!, req.query as AttendanceReportQuery);

  res.status(200).json({ data: { report } });
};

export const getTeamLeaveReportController = async (req: Request, res: Response) => {
  const report = await getTeamLeaveReport(req.user!, req.query as LeaveReportQuery);

  res.status(200).json({ data: { report } });
};

export const getTeamOkrReportController = async (req: Request, res: Response) => {
  const report = await getTeamOkrReport(req.user!, req.query as OkrReportQuery);

  res.status(200).json({ data: { report } });
};

export const getTeamPerformanceReportController = async (req: Request, res: Response) => {
  const report = await getTeamPerformanceReport(req.user!, req.query as PerformanceReportQuery);

  res.status(200).json({ data: { report } });
};

export const getMyDashboardReportController = async (req: Request, res: Response) => {
  const dashboard = await getMyDashboardReport(req.user!);

  res.status(200).json({ data: { dashboard } });
};

export const getSuperAdminDashboardReportController = async (req: Request, res: Response) => {
  const dashboard = await getSuperAdminDashboardReport(req.user!);

  res.status(200).json({ data: { dashboard } });
};

export const getSuperAdminCompanyReportsController = async (req: Request, res: Response) => {
  const companies = await getSuperAdminCompanyReports(req.user!);

  res.status(200).json({ data: { companies } });
};
