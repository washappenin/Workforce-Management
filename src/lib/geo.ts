export interface GeoPoint {
  latitude: number;
  longitude: number;
}

const earthRadiusMeters = 6_371_000;

const toRadians = (degrees: number) => (degrees * Math.PI) / 180;

const assertFiniteNumber = (value: number, label: string) => {
  if (!Number.isFinite(value)) {
    throw new RangeError(`${label} must be a finite number`);
  }
};

export const validateLatitude = (latitude: number) => {
  assertFiniteNumber(latitude, "Latitude");

  if (latitude < -90 || latitude > 90) {
    throw new RangeError("Latitude must be between -90 and 90");
  }

  return latitude;
};

export const validateLongitude = (longitude: number) => {
  assertFiniteNumber(longitude, "Longitude");

  if (longitude < -180 || longitude > 180) {
    throw new RangeError("Longitude must be between -180 and 180");
  }

  return longitude;
};

export const calculateDistanceMeters = (pointA: GeoPoint, pointB: GeoPoint) => {
  validateLatitude(pointA.latitude);
  validateLongitude(pointA.longitude);
  validateLatitude(pointB.latitude);
  validateLongitude(pointB.longitude);

  const deltaLatitude = toRadians(pointB.latitude - pointA.latitude);
  const deltaLongitude = toRadians(pointB.longitude - pointA.longitude);
  const latitudeA = toRadians(pointA.latitude);
  const latitudeB = toRadians(pointB.latitude);

  const haversine =
    Math.sin(deltaLatitude / 2) ** 2 +
    Math.cos(latitudeA) * Math.cos(latitudeB) * Math.sin(deltaLongitude / 2) ** 2;

  return 2 * earthRadiusMeters * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));
};

export const isWithinRadius = (point: GeoPoint, center: GeoPoint, radiusMeters: number) => {
  assertFiniteNumber(radiusMeters, "Radius");

  if (radiusMeters <= 0) {
    throw new RangeError("Radius must be greater than 0");
  }

  return calculateDistanceMeters(point, center) <= radiusMeters;
};
