export interface FaceEnrollmentProviderInput {
  employeeId: string;
  providerSubjectId?: string | null;
  templateReference?: string | null;
}

export interface FaceEnrollmentProviderResult {
  providerSubjectId: string;
  templateReference: string;
}

export interface FaceVerificationProviderInput {
  employeeId: string;
  providerSubjectId?: string | null;
  templateReference?: string | null;
  verificationReference: string;
}

export interface FaceVerificationProviderResult {
  verified: boolean;
  reason?: "FACE_NOT_MATCHED" | "PROVIDER_UNAVAILABLE";
}

export interface FaceProvider {
  name: string;
  enroll(input: FaceEnrollmentProviderInput): Promise<FaceEnrollmentProviderResult>;
  verify(input: FaceVerificationProviderInput): Promise<FaceVerificationProviderResult>;
}
