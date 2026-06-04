import type { GeofenceStatus } from "@prisma/client";

import { getPrismaClient } from "../../lib/prisma";

export interface CompanyLookupRecord {
  id: string;
}

export interface GeofenceRecord {
  id: string;
  companyId: string;
  name: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  status: GeofenceStatus;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateGeofenceRepositoryInput {
  companyId: string;
  name: string;
  latitude: number;
  longitude: number;
  radiusMeters: number;
  status?: GeofenceStatus;
}

export interface UpdateGeofenceRepositoryInput {
  name?: string;
  latitude?: number;
  longitude?: number;
  radiusMeters?: number;
}

export interface GeofencesRepository {
  findCompanyById(companyId: string): Promise<CompanyLookupRecord | null>;
  create(input: CreateGeofenceRepositoryInput): Promise<GeofenceRecord>;
  list(companyId: string): Promise<GeofenceRecord[]>;
  listActive(companyId: string): Promise<GeofenceRecord[]>;
  findByIdInCompany(geofenceId: string, companyId: string): Promise<GeofenceRecord | null>;
  findByNameInCompany(name: string, companyId: string): Promise<GeofenceRecord | null>;
  update(geofenceId: string, companyId: string, input: UpdateGeofenceRepositoryInput): Promise<GeofenceRecord>;
  updateStatus(geofenceId: string, companyId: string, status: GeofenceStatus): Promise<GeofenceRecord>;
}

const decimalToNumber = (value: { toNumber(): number } | number) =>
  typeof value === "number" ? value : value.toNumber();

const mapGeofence = (geofence: {
  id: string;
  companyId: string;
  name: string;
  latitude: { toNumber(): number } | number;
  longitude: { toNumber(): number } | number;
  radiusMeters: number;
  status: GeofenceStatus;
  createdAt: Date;
  updatedAt: Date;
}): GeofenceRecord => ({
  id: geofence.id,
  companyId: geofence.companyId,
  name: geofence.name,
  latitude: decimalToNumber(geofence.latitude),
  longitude: decimalToNumber(geofence.longitude),
  radiusMeters: geofence.radiusMeters,
  status: geofence.status,
  createdAt: geofence.createdAt,
  updatedAt: geofence.updatedAt
});

const prismaGeofencesRepository: GeofencesRepository = {
  async findCompanyById(companyId) {
    const prisma = getPrismaClient();

    return prisma.company.findUnique({
      where: { id: companyId },
      select: { id: true }
    });
  },

  async create(input) {
    const prisma = getPrismaClient();
    const geofence = await prisma.geofence.create({
      data: {
        companyId: input.companyId,
        name: input.name,
        latitude: input.latitude,
        longitude: input.longitude,
        radiusMeters: input.radiusMeters,
        status: input.status
      }
    });

    return mapGeofence(geofence);
  },

  async list(companyId) {
    const prisma = getPrismaClient();
    const geofences = await prisma.geofence.findMany({
      where: { companyId },
      orderBy: { createdAt: "desc" }
    });

    return geofences.map(mapGeofence);
  },

  async listActive(companyId) {
    const prisma = getPrismaClient();
    const geofences = await prisma.geofence.findMany({
      where: {
        companyId,
        status: "ACTIVE"
      },
      orderBy: { createdAt: "desc" }
    });

    return geofences.map(mapGeofence);
  },

  async findByIdInCompany(geofenceId, companyId) {
    const prisma = getPrismaClient();
    const geofence = await prisma.geofence.findFirst({
      where: {
        id: geofenceId,
        companyId
      }
    });

    return geofence ? mapGeofence(geofence) : null;
  },

  async findByNameInCompany(name, companyId) {
    const prisma = getPrismaClient();
    const geofence = await prisma.geofence.findFirst({
      where: {
        name,
        companyId
      }
    });

    return geofence ? mapGeofence(geofence) : null;
  },

  async update(geofenceId, companyId, input) {
    const prisma = getPrismaClient();

    await prisma.geofence.updateMany({
      where: {
        id: geofenceId,
        companyId
      },
      data: input
    });

    const geofence = await this.findByIdInCompany(geofenceId, companyId);

    if (!geofence) {
      throw new Error("Geofence update failed");
    }

    return geofence;
  },

  async updateStatus(geofenceId, companyId, status) {
    const prisma = getPrismaClient();

    await prisma.geofence.updateMany({
      where: {
        id: geofenceId,
        companyId
      },
      data: { status }
    });

    const geofence = await this.findByIdInCompany(geofenceId, companyId);

    if (!geofence) {
      throw new Error("Geofence status update failed");
    }

    return geofence;
  }
};

let activeGeofencesRepository = prismaGeofencesRepository;

export const getGeofencesRepository = () => activeGeofencesRepository;

export const setGeofencesRepositoryForTests = (repository: GeofencesRepository) => {
  activeGeofencesRepository = repository;
};

export const resetGeofencesRepositoryForTests = () => {
  activeGeofencesRepository = prismaGeofencesRepository;
};
