import { getRequiredScopedCompanyId } from "../../lib/authorization";
import { recordAuditLog, type AuditRequestContext } from "../../lib/audit";
import { calculateDistanceMeters } from "../../lib/geo";
import { AuthorizationError, ConflictError, NotFoundError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getGeofencesRepository,
  type GeofenceRecord,
  type UpdateGeofenceRepositoryInput
} from "./geofences.repository";
import type {
  CreateGeofenceInput,
  GeofenceScopeQuery,
  UpdateGeofenceInput,
  UpdateGeofenceStatusInput,
  ValidateLocationInput
} from "./geofences.validation";

const getGeofenceScope = (actor: AuthenticatedUser, requestedCompanyId?: string | null) =>
  getRequiredScopedCompanyId(actor, requestedCompanyId);

const roundDistance = (distanceMeters: number) => Math.round(distanceMeters * 100) / 100;

const assertCompanyExists = async (companyId: string) => {
  const company = await getGeofencesRepository().findCompanyById(companyId);

  if (!company) {
    throw new NotFoundError("Company not found");
  }
};

export const serializeGeofence = (geofence: GeofenceRecord) => ({
  id: geofence.id,
  companyId: geofence.companyId,
  name: geofence.name,
  latitude: geofence.latitude,
  longitude: geofence.longitude,
  radiusMeters: geofence.radiusMeters,
  status: geofence.status,
  createdAt: geofence.createdAt,
  updatedAt: geofence.updatedAt
});

export const createGeofence = async (
  actor: AuthenticatedUser,
  input: CreateGeofenceInput,
  auditContext: AuditRequestContext
) => {
  const repository = getGeofencesRepository();
  const companyId = getGeofenceScope(actor, input.companyId);

  await assertCompanyExists(companyId);

  const existing = await repository.findByNameInCompany(input.name, companyId);

  if (existing) {
    throw new ConflictError("Geofence name already exists in this company");
  }

  const geofence = await repository.create({
    companyId,
    name: input.name,
    latitude: input.latitude,
    longitude: input.longitude,
    radiusMeters: input.radiusMeters,
    status: input.status
  });

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "GEOFENCE",
    action: "GEOFENCE_CREATED",
    targetType: "Geofence",
    targetId: geofence.id,
    metadata: { name: geofence.name, radiusMeters: geofence.radiusMeters, status: geofence.status },
    ...auditContext
  });

  return serializeGeofence(geofence);
};

export const listGeofences = async (actor: AuthenticatedUser, query: GeofenceScopeQuery) => {
  const companyId = getGeofenceScope(actor, query.companyId);
  const geofences = await getGeofencesRepository().list(companyId);

  return geofences.map(serializeGeofence);
};

export const getGeofence = async (
  actor: AuthenticatedUser,
  geofenceId: string,
  query: GeofenceScopeQuery = {}
) => {
  const companyId = getGeofenceScope(actor, query.companyId);
  const geofence = await getGeofencesRepository().findByIdInCompany(geofenceId, companyId);

  if (!geofence) {
    throw new NotFoundError("Geofence not found");
  }

  return serializeGeofence(geofence);
};

export const updateGeofence = async (
  actor: AuthenticatedUser,
  geofenceId: string,
  input: UpdateGeofenceInput,
  query: GeofenceScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getGeofencesRepository();
  const companyId = getGeofenceScope(actor, query.companyId);
  const current = await repository.findByIdInCompany(geofenceId, companyId);

  if (!current) {
    throw new NotFoundError("Geofence not found");
  }

  if (input.name && input.name !== current.name) {
    const existing = await repository.findByNameInCompany(input.name, companyId);

    if (existing && existing.id !== geofenceId) {
      throw new ConflictError("Geofence name already exists in this company");
    }
  }

  const updateInput: UpdateGeofenceRepositoryInput = {
    name: input.name,
    latitude: input.latitude,
    longitude: input.longitude,
    radiusMeters: input.radiusMeters
  };
  const geofence = await repository.update(geofenceId, companyId, updateInput);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "GEOFENCE",
    action: "GEOFENCE_UPDATED",
    targetType: "Geofence",
    targetId: geofence.id,
    metadata: { updatedFields: Object.keys(input) },
    ...auditContext
  });

  return serializeGeofence(geofence);
};

export const updateGeofenceStatus = async (
  actor: AuthenticatedUser,
  geofenceId: string,
  input: UpdateGeofenceStatusInput,
  query: GeofenceScopeQuery,
  auditContext: AuditRequestContext
) => {
  const repository = getGeofencesRepository();
  const companyId = getGeofenceScope(actor, query.companyId);
  const current = await repository.findByIdInCompany(geofenceId, companyId);

  if (!current) {
    throw new NotFoundError("Geofence not found");
  }

  const geofence = await repository.updateStatus(geofenceId, companyId, input.status);

  await recordAuditLog({
    companyId,
    actorUserId: actor.id,
    category: "GEOFENCE",
    action: "GEOFENCE_STATUS_CHANGED",
    targetType: "Geofence",
    targetId: geofence.id,
    metadata: { previousStatus: current.status, status: geofence.status },
    ...auditContext
  });

  return serializeGeofence(geofence);
};

export const validateLocation = async (actor: AuthenticatedUser, input: ValidateLocationInput) => {
  const companyId = getGeofenceScope(actor, input.companyId);
  const activeGeofences = await getGeofencesRepository().listActive(companyId);

  if (activeGeofences.length === 0) {
    return {
      isWithinGeofence: false,
      reason: "NO_ACTIVE_GEOFENCE" as const
    };
  }

  const point = {
    latitude: input.latitude,
    longitude: input.longitude
  };
  const matches = activeGeofences
    .map((geofence) => {
      const distanceMeters = calculateDistanceMeters(point, {
        latitude: geofence.latitude,
        longitude: geofence.longitude
      });

      return {
        geofence,
        distanceMeters
      };
    })
    .sort((left, right) => left.distanceMeters - right.distanceMeters);

  const nearest = matches[0];

  if (!nearest) {
    throw new AuthorizationError("Company scope is required");
  }

  if (nearest.distanceMeters <= nearest.geofence.radiusMeters) {
    return {
      isWithinGeofence: true,
      geofenceId: nearest.geofence.id,
      distanceMeters: roundDistance(nearest.distanceMeters),
      radiusMeters: nearest.geofence.radiusMeters
    };
  }

  return {
    isWithinGeofence: false,
    nearestGeofenceId: nearest.geofence.id,
    distanceMeters: roundDistance(nearest.distanceMeters),
    radiusMeters: nearest.geofence.radiusMeters
  };
};
