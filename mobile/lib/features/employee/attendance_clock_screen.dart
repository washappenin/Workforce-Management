import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failures.dart';
import '../../shared/widgets/states.dart';
import 'attendance_actions.dart';
import 'employee_models.dart';
import 'employee_repository.dart';
import 'widgets/employee_widgets.dart';

enum _ClockStage {
  idle,
  camera,
  face,
  location,
  geofence,
  attendance,
  success,
}

class FaceVerificationScreen extends ConsumerStatefulWidget {
  const FaceVerificationScreen({super.key});

  @override
  ConsumerState<FaceVerificationScreen> createState() =>
      _FaceVerificationScreenState();
}

class _FaceVerificationScreenState
    extends ConsumerState<FaceVerificationScreen> {
  bool _busy = false;
  Object? _error;
  FaceVerificationResult? _result;

  @override
  Widget build(BuildContext context) {
    return EmployeePage(
      title: 'Face verification',
      subtitle: 'Camera-gated staging verification',
      child: ListView(
        children: [
          const _PrivacyNotice(),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Verification',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Staging uses the backend mock provider. The app requests camera permission, sends the safe mock verification reference, and receives a short-lived backend reference. Raw face images are not stored on device.',
                ),
                if (_result != null) ...[
                  const Divider(height: 28),
                  StatusChip(label: _result!.verified ? 'VERIFIED' : 'FAILED'),
                  if (_result!.expiresAt != null)
                    InfoLine(
                        label: 'Expires',
                        value: shortDateTime(_result!.expiresAt)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  _InlineFailure(error: _error!),
                ],
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  key: const ValueKey('employee.face.verify'),
                  onPressed: _busy ? null : _verify,
                  icon: const Icon(Icons.face_retouching_natural_outlined),
                  label: Text(_busy ? 'Verifying...' : 'Verify face'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    try {
      await ref.read(deviceAttendanceServiceProvider).requestCameraPermission();
      final result = await ref.read(employeeRepositoryProvider).verifyFace();
      if (!result.verified) {
        throw ValidationFailure(result.reason ?? 'Face verification failed.');
      }
      if (!mounted) return;
      setState(() => _result = result);
      showEmployeeSuccessSnack(context, 'Face verified.');
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class ClockInScreen extends ConsumerStatefulWidget {
  const ClockInScreen({super.key});

  @override
  ConsumerState<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends ConsumerState<ClockInScreen> {
  _ClockStage _stage = _ClockStage.idle;
  Object? _error;
  AttendanceActionResult? _result;
  GeofenceValidationResult? _precheck;

  bool get _busy => _stage != _ClockStage.idle && _stage != _ClockStage.success;

  @override
  Widget build(BuildContext context) {
    return EmployeePage(
      title: 'Clock in',
      subtitle: 'Face verification and GPS required',
      child: ListView(
        children: [
          const _PrivacyNotice(),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            key: const ValueKey('employee.clockIn.submit'),
            onPressed: _busy ? null : _clockIn,
            icon: const Icon(Icons.login),
            label: Text(_busy ? 'Clocking in...' : 'Verify and clock in'),
          ),
          const SizedBox(height: 14),
          if (_error != null) ...[
            _InlineFailure(error: _error!),
            const SizedBox(height: 14),
          ],
          if (_result != null) ...[
            _AttendanceResultCard(result: _result!),
            const SizedBox(height: 14),
          ],
          if (_precheck != null) ...[
            _GeofenceCard(result: _precheck!),
            const SizedBox(height: 14),
          ],
          _StepCard(
            stage: _stage,
            steps: const [
              _StepSpec(_ClockStage.camera, 'Camera permission'),
              _StepSpec(_ClockStage.face, 'Face verification'),
              _StepSpec(_ClockStage.location, 'GPS location'),
              _StepSpec(_ClockStage.geofence, 'Geofence precheck'),
              _StepSpec(_ClockStage.attendance, 'Clock-in write'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clockIn() async {
    setState(() {
      _stage = _ClockStage.camera;
      _error = null;
      _result = null;
      _precheck = null;
    });

    try {
      final device = ref.read(deviceAttendanceServiceProvider);
      final repo = ref.read(employeeRepositoryProvider);

      await device.requestCameraPermission();
      setState(() => _stage = _ClockStage.face);
      final face = await repo.verifyFace();
      if (!face.verified) {
        throw ValidationFailure(face.reason ?? 'Face verification failed.');
      }
      final faceReference = face.verificationReference;
      if (faceReference == null || faceReference.isEmpty) {
        throw const ValidationFailure('Face verification reference missing.');
      }

      setState(() => _stage = _ClockStage.location);
      final location = await device.currentLocation();

      setState(() => _stage = _ClockStage.geofence);
      final precheck = await repo.validateLocation(location);
      if (!mounted) return;
      setState(() => _precheck = precheck);
      if (!precheck.isWithinGeofence) {
        throw ValidationFailure(
          precheck.reason ?? 'Location is outside active company geofences.',
        );
      }

      setState(() => _stage = _ClockStage.attendance);
      final result = await repo.clockIn(
        location: location,
        faceVerificationReference: faceReference,
      );

      ref.invalidate(employeeDashboardProvider);
      ref.invalidate(attendanceSessionsProvider);
      if (!mounted) return;
      setState(() {
        _stage = _ClockStage.success;
        _result = result;
      });
      showEmployeeSuccessSnack(context, 'Clocked in.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _ClockStage.idle;
        _error = error;
      });
    }
  }
}

class ClockOutScreen extends ConsumerStatefulWidget {
  const ClockOutScreen({super.key});

  @override
  ConsumerState<ClockOutScreen> createState() => _ClockOutScreenState();
}

class _ClockOutScreenState extends ConsumerState<ClockOutScreen> {
  _ClockStage _stage = _ClockStage.idle;
  Object? _error;
  AttendanceActionResult? _result;
  GeofenceValidationResult? _precheck;

  bool get _busy => _stage != _ClockStage.idle && _stage != _ClockStage.success;

  @override
  Widget build(BuildContext context) {
    return EmployeePage(
      title: 'Clock out',
      subtitle: 'GPS geofence required',
      child: ListView(
        children: [
          const _PrivacyNotice(),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            key: const ValueKey('employee.clockOut.submit'),
            onPressed: _busy ? null : _clockOut,
            icon: const Icon(Icons.logout),
            label: Text(_busy ? 'Clocking out...' : 'Clock out'),
          ),
          const SizedBox(height: 14),
          if (_error != null) ...[
            _InlineFailure(error: _error!),
            const SizedBox(height: 14),
          ],
          if (_result != null) ...[
            _AttendanceResultCard(result: _result!),
            const SizedBox(height: 14),
          ],
          if (_precheck != null) ...[
            _GeofenceCard(result: _precheck!),
            const SizedBox(height: 14),
          ],
          _StepCard(
            stage: _stage,
            steps: const [
              _StepSpec(_ClockStage.location, 'GPS location'),
              _StepSpec(_ClockStage.geofence, 'Geofence precheck'),
              _StepSpec(_ClockStage.attendance, 'Clock-out write'),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _clockOut() async {
    setState(() {
      _stage = _ClockStage.location;
      _error = null;
      _result = null;
      _precheck = null;
    });

    try {
      final device = ref.read(deviceAttendanceServiceProvider);
      final repo = ref.read(employeeRepositoryProvider);
      final location = await device.currentLocation();

      setState(() => _stage = _ClockStage.geofence);
      final precheck = await repo.validateLocation(location);
      if (!mounted) return;
      setState(() => _precheck = precheck);
      if (!precheck.isWithinGeofence) {
        throw ValidationFailure(
          precheck.reason ?? 'Location is outside active company geofences.',
        );
      }

      setState(() => _stage = _ClockStage.attendance);
      final result = await repo.clockOut(location: location);

      ref.invalidate(employeeDashboardProvider);
      ref.invalidate(attendanceSessionsProvider);
      if (!mounted) return;
      setState(() {
        _stage = _ClockStage.success;
        _result = result;
      });
      showEmployeeSuccessSnack(context, 'Clocked out.');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = _ClockStage.idle;
        _error = error;
      });
    }
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      child: Text(
        'Aurelia does not store raw camera images or raw GPS history on this device. Location is sent only for the active attendance action.',
      ),
    );
  }
}

class _StepSpec {
  const _StepSpec(this.stage, this.label);

  final _ClockStage stage;
  final String label;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.stage, required this.steps});

  final _ClockStage stage;
  final List<_StepSpec> steps;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sequence', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          for (final spec in steps)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(_iconFor(spec.stage)),
              title: Text(spec.label),
              trailing: _trailing(spec.stage),
            ),
        ],
      ),
    );
  }

  IconData _iconFor(_ClockStage step) {
    return switch (step) {
      _ClockStage.camera => Icons.photo_camera_outlined,
      _ClockStage.face => Icons.face_retouching_natural_outlined,
      _ClockStage.location => Icons.my_location_outlined,
      _ClockStage.geofence => Icons.location_searching_outlined,
      _ClockStage.attendance => Icons.verified_outlined,
      _ => Icons.circle_outlined,
    };
  }

  Widget _trailing(_ClockStage step) {
    if (stage == _ClockStage.success) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }
    if (stage == step) {
      return const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return const Icon(Icons.circle_outlined, size: 18);
  }
}

class _GeofenceCard extends StatelessWidget {
  const _GeofenceCard({required this.result});

  final GeofenceValidationResult result;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Geofence',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip(
                label: result.isWithinGeofence ? 'INSIDE' : 'OUTSIDE',
                color: result.isWithinGeofence ? null : Colors.red,
              ),
            ],
          ),
          const Divider(height: 24),
          InfoLine(
            label: 'Distance',
            value: result.distanceMeters == null
                ? 'Not reported'
                : '${dayCount(result.distanceMeters!)} m',
          ),
          InfoLine(
            label: 'Radius',
            value: result.radiusMeters == null
                ? 'Not reported'
                : '${dayCount(result.radiusMeters!)} m',
          ),
        ],
      ),
    );
  }
}

class _AttendanceResultCard extends StatelessWidget {
  const _AttendanceResultCard({required this.result});

  final AttendanceActionResult result;

  @override
  Widget build(BuildContext context) {
    final session = result.attendanceSession;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Attendance recorded',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip(label: session.status),
            ],
          ),
          const Divider(height: 24),
          InfoLine(label: 'Clock in', value: shortDateTime(session.clockInAt)),
          InfoLine(
              label: 'Clock out', value: shortDateTime(session.clockOutAt)),
          InfoLine(
            label: 'Geofence',
            value: '${dayCount(result.geofence.distanceMeters)} m inside',
          ),
        ],
      ),
    );
  }
}

class _InlineFailure extends StatelessWidget {
  const _InlineFailure({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final message = error is AppFailure
        ? (error as AppFailure).message
        : 'Action failed. Please try again.';
    return ErrorStateView(
      title: 'Action blocked',
      message: message,
    );
  }
}
