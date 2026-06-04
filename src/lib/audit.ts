import type { AuditActionCategory, Prisma } from "@prisma/client";
import type { Request } from "express";

import { getPrismaClient } from "./prisma";

export interface AuditLogInput {
  companyId?: string | null;
  actorUserId?: string | null;
  category: AuditActionCategory;
  action: string;
  targetType?: string | null;
  targetId?: string | null;
  metadata?: Record<string, unknown> | null;
  ipAddress?: string | null;
  userAgent?: string | null;
}

export interface AuditRequestContext {
  ipAddress?: string | null;
  userAgent?: string | null;
}

export interface AuditRepository {
  create(input: AuditLogInput): Promise<void>;
}

const sensitiveAuditMetadataKeys = new Set(
  [
    "authorization",
    "accessToken",
    "refreshToken",
    "token",
    "jwt",
    "password",
    "passwordHash",
    "temporaryPassword",
    "email",
    "phone",
    "faceData",
    "faceImage",
    "rawFaceImage",
    "biometricData",
    "rawBiometricData",
    "faceVerificationPayload",
    "verificationReference",
    "providerSubjectId",
    "templateReference",
    "latitude",
    "longitude",
    "providerReference",
    "paymentInstrument",
    "cardNumber",
    "bankAccountNumber",
    "reason",
    "reviewComment",
    "summary",
    "description",
    "note",
    "comment",
    "message"
  ].map((key) => key.toLowerCase())
);

const sanitizeAuditMetadataValue = (value: unknown): unknown => {
  if (value instanceof Date) {
    return value.toISOString();
  }

  if (Array.isArray(value)) {
    return value.map((item) => sanitizeAuditMetadataValue(item));
  }

  if (value && typeof value === "object") {
    return Object.entries(value as Record<string, unknown>).reduce<Record<string, unknown>>((metadata, [key, entry]) => {
      if (sensitiveAuditMetadataKeys.has(key.toLowerCase())) {
        return metadata;
      }

      metadata[key] = sanitizeAuditMetadataValue(entry);
      return metadata;
    }, {});
  }

  return value;
};

export const sanitizeAuditMetadata = (metadata?: Record<string, unknown> | null): Record<string, unknown> | null => {
  if (!metadata) {
    return null;
  }

  return sanitizeAuditMetadataValue(metadata) as Record<string, unknown>;
};

const prismaAuditRepository: AuditRepository = {
  async create(input) {
    const prisma = getPrismaClient();

    await prisma.auditLog.create({
      data: {
        companyId: input.companyId ?? null,
        actorUserId: input.actorUserId ?? null,
        category: input.category,
        action: input.action,
        targetType: input.targetType ?? null,
        targetId: input.targetId ?? null,
        metadata: (input.metadata ?? undefined) as Prisma.InputJsonValue | undefined,
        ipAddress: input.ipAddress ?? null,
        userAgent: input.userAgent ?? null
      }
    });
  }
};

let activeAuditRepository = prismaAuditRepository;

export const getAuditRepository = () => activeAuditRepository;

export const setAuditRepositoryForTests = (repository: AuditRepository) => {
  activeAuditRepository = repository;
};

export const resetAuditRepositoryForTests = () => {
  activeAuditRepository = prismaAuditRepository;
};

export const getAuditRequestContext = (req: Request): AuditRequestContext => ({
  ipAddress: req.ip,
  userAgent: req.header("user-agent") ?? null
});

export const recordAuditLog = async (input: AuditLogInput) => {
  await getAuditRepository().create({
    ...input,
    metadata: sanitizeAuditMetadata(input.metadata)
  });
};
