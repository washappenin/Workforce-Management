import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  getFaceStatus,
  updateFaceEnrollmentStatus,
  upsertFaceEnrollment,
  verifyFace
} from "./face.service";
import type {
  FaceScopeQuery,
  UpdateFaceEnrollmentStatusInput,
  UpsertFaceEnrollmentInput,
  VerifyFaceInput
} from "./face.validation";

export const upsertFaceEnrollmentController = async (req: Request, res: Response) => {
  const faceEnrollment = await upsertFaceEnrollment(
    req.user!,
    req.params.employeeId,
    req.body as UpsertFaceEnrollmentInput,
    getAuditRequestContext(req)
  );

  res.status(201).json({ data: { faceEnrollment } });
};

export const getFaceStatusController = async (req: Request, res: Response) => {
  const faceEnrollment = await getFaceStatus(req.user!, req.params.employeeId, req.query as FaceScopeQuery);

  res.status(200).json({ data: { faceEnrollment } });
};

export const updateFaceEnrollmentStatusController = async (req: Request, res: Response) => {
  const faceEnrollment = await updateFaceEnrollmentStatus(
    req.user!,
    req.params.employeeId,
    req.body as UpdateFaceEnrollmentStatusInput,
    req.query as FaceScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { faceEnrollment } });
};

export const verifyFaceController = async (req: Request, res: Response) => {
  const result = await verifyFace(req.user!, req.body as VerifyFaceInput);

  res.status(200).json({ data: result });
};
