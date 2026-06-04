import { getRequiredScopedCompanyId, isSuperAdmin } from "../../lib/authorization";
import { consumeFaceVerificationReference } from "../../lib/faceMatch";
import { calculateDistanceMeters } from "../../lib/geo";
import { AuthorizationError, ValidationError } from "../../lib/errors";
import type { AuthenticatedUser } from "../../types/auth";
import {
  getAttendanceRepository,
  type AttendanceEmployeeProfile,
  type AttendanceGeofenceRecord,
  type AttendanceListFilters,
  type AttendanceSessionRecord
} from "./attendance.repository";
import type { AdminAttendanceQuery, AttendanceLocationInput, ClockInInput, ClockOutInput, MyAttendanceQuery } from "./attendance.validation";

const roundDistance = (distanceMeters: number) => Math.round(distanceMeters * 100) / 100;

const serializeAttendanceSession = (session: AttendanceSessionRecord) => ({
  id: session.id,
  companyId: session.companyId,
  employeeId: session.employeeId,
  status: session.status,
  clockInAt: session.clockInAt,
  clockOutAt: session.clockOutAt,
  clockInGeofenceId: session.clockInGeofenceId,
  clockOutGeofenceId: session.clockOutGeofenceId,
  clockInFaceVerified: session.clockInFaceVerified,
  createdAt: session.createdAt,
  updatedAt: session.updatedAt
});

const toListFilters = (query: MyAttendanceQuery | AdminAttendanceQuery): AttendanceListFilters => ({
  from: query.from,
  to: query.to,
  status: "status" in query ? query.status : undefined,
  employeeId: "employeeId" in query ? query.employeeId : undefined
});

const getClockingEmployeeProfile = async (actor: AuthenticatedUser): Promise<AttendanceEmployeeProfile> => {
  if (isSuperAdmin(actor)) {
    throw new AuthorizationError("Super admins cannot clock in or out in CP7");
  }

  const employee = await getAttendanceRepository().findEmployeeProfileByUserId(actor.id);

  if (!employee) {
    throw new AuthorizationError("Employee profile is required");
  }

  if (employee.status !== "ACTIVE") {
    throw new AuthorizationError("Employee profile is not active");
  }

  if (employee.companyStatus !== "ACTIVE") {
    throw new AuthorizationError("Company is not active");
  }

  return employee;
};

const getSelfAttendanceEmployeeProfile = async (actor: AuthenticatedUser): Promise<AttendanceEmployeeProfile> => {
  if (isSuperAdmin(actor)) {
    throw new AuthorizationError("Employee profile is required");
  }

  const employee = await getAttendanceRepository().findEmployeeProfileByUserId(actor.id);

  if (!employee) {
    throw new AuthorizationError("Employee profile is required");
  }

  return employee;
};

const findMatchingGeofence = async (companyId: string, input: AttendanceLocationInput) => {
  const activeGeofences = await getAttendanceRepository().findActiveGeofencesForCompany(companyId);

  if (activeGeofences.length === 0) {
    throw new ValidationError("No active geofence configured for this company", undefined, 400);
  }

  const point = {
    latitude: input.latitude,
    longitude: input.longitude
  };

  const nearest = activeGeofences
    .map((geofence: AttendanceGeofenceRecord) => {
      const distanceMeters = calculateDistanceMeters(point, {
        latitude: geofence.latitude,
        longitude: geofence.longitude
      });

      return { geofence, distanceMeters };
    })
    .sort((left, right) => left.distanceMeters - right.distanceMeters)[0];

  if (!nearest || nearest.distanceMeters > nearest.geofence.radiusMeters) {
    throw new ValidationError("Location is outside active company geofences", undefined, 400);
  }

  return {
    id: nearest.geofence.id,
    distanceMeters: roundDistance(nearest.distanceMeters),
    radiusMeters: nearest.geofence.radiusMeters
  };
};

export const clockIn = async (actor: AuthenticatedUser, input: ClockInInput) => {
  const repository = getAttendanceRepository();
  const employee = await getClockingEmployeeProfile(actor);
  const existingOpenSession = await repository.findOpenSessionByEmployeeId(employee.id);

  if (existingOpenSession) {
    throw new ValidationError("An open attendance session already exists", undefined, 400);
  }

  const faceVerified = consumeFaceVerificationReference({
    reference: input.faceVerificationReference,
    employeeId: employee.id
  });

  if (!faceVerified) {
    throw new ValidationError("Valid face verification is required for clock-in", undefined, 400);
  }

  const geofence = await findMatchingGeofence(employee.companyId, input);
  const clockInAt = new Date();
  const session = await repository.createClockInSession({
    companyId: employee.companyId,
    employeeId: employee.id,
    clockInAt,
    latitude: input.latitude,
    longitude: input.longitude,
    geofenceId: geofence.id,
    clockInFaceVerified: true
  });

  await repository.createAttendanceEvent({
    companyId: employee.companyId,
    employeeId: employee.id,
    attendanceSessionId: session.id,
    type: "CLOCK_IN",
    latitude: input.latitude,
    longitude: input.longitude,
    metadata: {
      accuracyMeters: input.accuracyMeters,
      geofenceId: geofence.id,
      distanceMeters: geofence.distanceMeters,
      radiusMeters: geofence.radiusMeters,
      faceVerification: "VERIFIED_CP8"
    }
  });

  return {
    attendanceSession: serializeAttendanceSession(session),
    geofence
  };
};

export const clockOut = async (actor: AuthenticatedUser, input: ClockOutInput) => {
  const repository = getAttendanceRepository();
  const employee = await getClockingEmployeeProfile(actor);
  const openSession = await repository.findOpenSessionByEmployeeId(employee.id);

  if (!openSession) {
    throw new ValidationError("No open attendance session exists", undefined, 400);
  }

  const geofence = await findMatchingGeofence(employee.companyId, input);
  const session = await repository.closeAttendanceSession({
    sessionId: openSession.id,
    companyId: employee.companyId,
    employeeId: employee.id,
    clockOutAt: new Date(),
    latitude: input.latitude,
    longitude: input.longitude,
    geofenceId: geofence.id
  });

  await repository.createAttendanceEvent({
    companyId: employee.companyId,
    employeeId: employee.id,
    attendanceSessionId: session.id,
    type: "CLOCK_OUT",
    latitude: input.latitude,
    longitude: input.longitude,
    metadata: {
      accuracyMeters: input.accuracyMeters,
      geofenceId: geofence.id,
      distanceMeters: geofence.distanceMeters,
      radiusMeters: geofence.radiusMeters
    }
  });

  return {
    attendanceSession: serializeAttendanceSession(session),
    geofence
  };
};

export const listMyAttendance = async (actor: AuthenticatedUser, query: MyAttendanceQuery) => {
  const employee = await getSelfAttendanceEmployeeProfile(actor);
  const sessions = await getAttendanceRepository().listMyAttendance(employee.id, toListFilters(query));

  return sessions.map(serializeAttendanceSession);
};

export const listCompanyAttendance = async (actor: AuthenticatedUser, query: AdminAttendanceQuery) => {
  const repository = getAttendanceRepository();
  const companyId = getRequiredScopedCompanyId(actor, query.companyId);

  if (query.employeeId) {
    const employeeBelongsToCompany = await repository.verifyEmployeeBelongsToCompany(query.employeeId, companyId);

    if (!employeeBelongsToCompany) {
      throw new AuthorizationError("Employee is outside the resolved company scope");
    }
  }

  const sessions = await repository.listCompanyAttendance(companyId, toListFilters(query));

  return sessions.map(serializeAttendanceSession);
};
