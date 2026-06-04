import { redactSensitiveData } from "../../src/lib/logger";

describe("logger redaction", () => {
  it("redacts sensitive credential, token, biometric, GPS, and payment fields", () => {
    const result = redactSensitiveData({
      email: "employee@example.com",
      password: "secret",
      accessToken: "jwt",
      faceData: "face-bytes",
      latitude: 1.23,
      longitude: 4.56,
      nested: {
        refreshToken: "refresh",
        paymentInstrument: "card"
      }
    });

    expect(result).toEqual({
      email: "[REDACTED]",
      password: "[REDACTED]",
      accessToken: "[REDACTED]",
      faceData: "[REDACTED]",
      latitude: "[REDACTED]",
      longitude: "[REDACTED]",
      nested: {
        refreshToken: "[REDACTED]",
        paymentInstrument: "[REDACTED]"
      }
    });
  });
});
