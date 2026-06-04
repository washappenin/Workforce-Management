import { randomUUID } from "crypto";

import { ValidationError } from "./errors";
import { mockFaceProvider } from "./face/mockFaceProvider";
import type { FaceProvider } from "./face/faceProvider";

export interface FaceVerificationReference {
  reference: string;
  employeeId: string;
  provider: string;
  expiresAt: Date;
}

const providers = new Map<string, FaceProvider>([[mockFaceProvider.name, mockFaceProvider]]);
const verificationReferences = new Map<string, FaceVerificationReference>();
const verificationTtlMs = 5 * 60 * 1000;

export const getFaceProvider = (providerName: string) => {
  const provider = providers.get(providerName);

  if (!provider) {
    throw new ValidationError("Unsupported face provider", undefined, 400);
  }

  return provider;
};

export const createFaceVerificationReference = (input: { employeeId: string; provider: string }) => {
  const reference = `face-verification-${randomUUID()}`;
  const expiresAt = new Date(Date.now() + verificationTtlMs);
  const record = {
    reference,
    employeeId: input.employeeId,
    provider: input.provider,
    expiresAt
  };

  verificationReferences.set(reference, record);

  return record;
};

export const consumeFaceVerificationReference = (input: { reference: string; employeeId: string }) => {
  const record = verificationReferences.get(input.reference);

  if (!record) {
    return false;
  }

  verificationReferences.delete(input.reference);

  if (record.employeeId !== input.employeeId) {
    return false;
  }

  if (record.expiresAt.getTime() <= Date.now()) {
    return false;
  }

  return true;
};

export const resetFaceVerificationReferencesForTests = () => {
  verificationReferences.clear();
};

export const setFaceVerificationReferenceForTests = (record: FaceVerificationReference) => {
  verificationReferences.set(record.reference, record);
};
