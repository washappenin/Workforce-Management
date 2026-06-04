import type { Request, Response } from "express";

import { clockIn, clockOut, listCompanyAttendance, listMyAttendance } from "./attendance.service";
import type { AdminAttendanceQuery, ClockInInput, ClockOutInput, MyAttendanceQuery } from "./attendance.validation";

export const clockInController = async (req: Request, res: Response) => {
  const result = await clockIn(req.user!, req.body as ClockInInput);

  res.status(201).json({ data: result });
};

export const clockOutController = async (req: Request, res: Response) => {
  const result = await clockOut(req.user!, req.body as ClockOutInput);

  res.status(200).json({ data: result });
};

export const listMyAttendanceController = async (req: Request, res: Response) => {
  const attendanceSessions = await listMyAttendance(req.user!, req.query as MyAttendanceQuery);

  res.status(200).json({ data: { attendanceSessions } });
};

export const listCompanyAttendanceController = async (req: Request, res: Response) => {
  const attendanceSessions = await listCompanyAttendance(req.user!, req.query as AdminAttendanceQuery);

  res.status(200).json({ data: { attendanceSessions } });
};
