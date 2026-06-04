import type { FaceProvider } from "./faceProvider";

export const mockFaceProvider: FaceProvider = {
  name: "mock",

  async enroll(input) {
    return {
      providerSubjectId: input.providerSubjectId ?? `mock-subject-${input.employeeId}`,
      templateReference: input.templateReference ?? `mock-template-${input.employeeId}`
    };
  },

  async verify(input) {
    if (input.verificationReference === "mock-pass") {
      return { verified: true };
    }

    if (input.verificationReference === "mock-fail") {
      return {
        verified: false,
        reason: "FACE_NOT_MATCHED"
      };
    }

    return {
      verified: false,
      reason: "FACE_NOT_MATCHED"
    };
  }
};
