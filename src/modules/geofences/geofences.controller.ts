import type { Request, Response } from "express";

import { getAuditRequestContext } from "../../lib/audit";
import {
  createGeofence,
  getGeofence,
  listGeofences,
  updateGeofence,
  updateGeofenceStatus,
  validateLocation
} from "./geofences.service";
import type {
  CreateGeofenceInput,
  GeofenceScopeQuery,
  UpdateGeofenceInput,
  UpdateGeofenceStatusInput,
  ValidateLocationInput
} from "./geofences.validation";

export const createGeofenceController = async (req: Request, res: Response) => {
  const geofence = await createGeofence(req.user!, req.body as CreateGeofenceInput, getAuditRequestContext(req));

  res.status(201).json({ data: { geofence } });
};

export const listGeofencesController = async (req: Request, res: Response) => {
  const geofences = await listGeofences(req.user!, req.query as GeofenceScopeQuery);

  res.status(200).json({ data: { geofences } });
};

export const getGeofenceController = async (req: Request, res: Response) => {
  const geofence = await getGeofence(req.user!, req.params.geofenceId, req.query as GeofenceScopeQuery);

  res.status(200).json({ data: { geofence } });
};

export const updateGeofenceController = async (req: Request, res: Response) => {
  const geofence = await updateGeofence(
    req.user!,
    req.params.geofenceId,
    req.body as UpdateGeofenceInput,
    req.query as GeofenceScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { geofence } });
};

export const updateGeofenceStatusController = async (req: Request, res: Response) => {
  const geofence = await updateGeofenceStatus(
    req.user!,
    req.params.geofenceId,
    req.body as UpdateGeofenceStatusInput,
    req.query as GeofenceScopeQuery,
    getAuditRequestContext(req)
  );

  res.status(200).json({ data: { geofence } });
};

export const validateLocationController = async (req: Request, res: Response) => {
  const result = await validateLocation(req.user!, req.body as ValidateLocationInput);

  res.status(200).json({ data: result });
};
