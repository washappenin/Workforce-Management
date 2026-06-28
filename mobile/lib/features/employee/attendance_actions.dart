import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as permissions;

import '../../core/errors/failures.dart';
import 'employee_models.dart';

const _qaLatitude = String.fromEnvironment('QA_DEVICE_LATITUDE');
const _qaLongitude = String.fromEnvironment('QA_DEVICE_LONGITUDE');
const _qaAccuracyMeters = String.fromEnvironment('QA_DEVICE_ACCURACY_METERS');
const _isStagingFe3Qa = bool.fromEnvironment('QA_RUN_STAGING_FE3');

final deviceAttendanceServiceProvider =
    Provider<DeviceAttendanceService>((ref) {
  return const DeviceAttendanceService();
});

class DeviceAttendanceService {
  const DeviceAttendanceService();

  Future<void> requestCameraPermission() async {
    if (_isStagingFe3Qa) return;

    final status = await permissions.Permission.camera.request();
    if (status.isGranted || status.isLimited) return;

    if (status.isPermanentlyDenied) {
      throw const ValidationFailure(
        'Camera permission is disabled. Enable it in system settings before face verification.',
      );
    }

    throw const ValidationFailure(
      'Camera permission is required before face verification.',
    );
  }

  Future<DeviceLocation> currentLocation() async {
    final qaLocation = _qaLocation();
    if (qaLocation != null) return qaLocation;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const ValidationFailure(
        'Location services are disabled. Enable GPS before clocking in or out.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const ValidationFailure(
        'Location permission is disabled. Enable it in system settings before clocking in or out.',
      );
    }

    if (permission == LocationPermission.denied) {
      throw const ValidationFailure(
        'Location permission is required before clocking in or out.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );
  }

  DeviceLocation? _qaLocation() {
    if (_qaLatitude.isEmpty || _qaLongitude.isEmpty) return null;
    final latitude = double.tryParse(_qaLatitude);
    final longitude = double.tryParse(_qaLongitude);
    if (latitude == null || longitude == null) return null;
    return DeviceLocation(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: double.tryParse(_qaAccuracyMeters),
    );
  }
}
