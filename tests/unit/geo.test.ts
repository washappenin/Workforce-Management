import { calculateDistanceMeters, isWithinRadius, validateLatitude, validateLongitude } from "../../src/lib/geo";

describe("geo helpers", () => {
  it("returns near zero distance for identical points", () => {
    const distance = calculateDistanceMeters(
      { latitude: 9.0301, longitude: 38.74 },
      { latitude: 9.0301, longitude: 38.74 }
    );

    expect(distance).toBeLessThan(0.001);
  });

  it("calculates a reasonable distance for nearby coordinates", () => {
    const distance = calculateDistanceMeters(
      { latitude: 9.0301, longitude: 38.74 },
      { latitude: 9.031, longitude: 38.74 }
    );

    expect(distance).toBeGreaterThan(90);
    expect(distance).toBeLessThan(110);
  });

  it("detects a point inside a radius", () => {
    expect(
      isWithinRadius(
        { latitude: 9.0305, longitude: 38.74 },
        { latitude: 9.0301, longitude: 38.74 },
        100
      )
    ).toBe(true);
  });

  it("detects a point outside a radius", () => {
    expect(
      isWithinRadius(
        { latitude: 9.04, longitude: 38.74 },
        { latitude: 9.0301, longitude: 38.74 },
        100
      )
    ).toBe(false);
  });

  it("rejects invalid latitude values", () => {
    expect(() => validateLatitude(91)).toThrow(RangeError);
    expect(() => validateLatitude(Number.NaN)).toThrow(RangeError);
  });

  it("rejects invalid longitude values", () => {
    expect(() => validateLongitude(181)).toThrow(RangeError);
    expect(() => validateLongitude(Number.POSITIVE_INFINITY)).toThrow(RangeError);
  });
});
