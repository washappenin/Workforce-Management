import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import 'admin_models.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

final departmentsProvider =
    FutureProvider.autoDispose<List<AdminDepartment>>((ref) {
  return ref.watch(adminRepositoryProvider).listDepartments();
});

final departmentProvider =
    FutureProvider.autoDispose.family<AdminDepartment, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).getDepartment(id);
});

final designationsProvider =
    FutureProvider.autoDispose<List<AdminDesignation>>((ref) {
  return ref.watch(adminRepositoryProvider).listDesignations();
});

final designationProvider =
    FutureProvider.autoDispose.family<AdminDesignation, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).getDesignation(id);
});

final employeesProvider =
    FutureProvider.autoDispose<List<AdminEmployee>>((ref) {
  return ref.watch(adminRepositoryProvider).listEmployees();
});

final employeeProvider =
    FutureProvider.autoDispose.family<AdminEmployee, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).getEmployee(id);
});

final faceEnrollmentProvider = FutureProvider.autoDispose
    .family<FaceEnrollment, String>((ref, employeeId) {
  return ref.watch(adminRepositoryProvider).getFaceStatus(employeeId);
});

final geofencesProvider =
    FutureProvider.autoDispose<List<AdminGeofence>>((ref) {
  return ref.watch(adminRepositoryProvider).listGeofences();
});

final geofenceProvider =
    FutureProvider.autoDispose.family<AdminGeofence, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).getGeofence(id);
});

final adminAttendanceProvider = FutureProvider.autoDispose
    .family<List<AdminAttendanceSession>, String?>((ref, status) {
  return ref.watch(adminRepositoryProvider).listAttendance(status: status);
});

final shiftsProvider = FutureProvider.autoDispose<List<AdminShift>>((ref) {
  return ref.watch(adminRepositoryProvider).listShifts();
});

final shiftProvider =
    FutureProvider.autoDispose.family<AdminShift, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).getShift(id);
});

final shiftAssignmentsProvider = FutureProvider.autoDispose
    .family<List<AdminShiftAssignment>, String>((ref, shiftId) {
  return ref.watch(adminRepositoryProvider).listShiftAssignments(shiftId);
});

class AdminRepository {
  const AdminRepository(this._api);

  final ApiClient _api;

  Future<List<AdminDepartment>> listDepartments({String? companyId}) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/departments',
      query: _scopeQuery(companyId),
    );
    return _list(data, 'departments')
        .map(AdminDepartment.fromJson)
        .toList(growable: false);
  }

  Future<AdminDepartment> getDepartment(
    String departmentId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/departments/$departmentId',
      query: _scopeQuery(companyId),
    );
    return AdminDepartment.fromJson(_object(data, 'department'));
  }

  Future<AdminDepartment> createDepartment({
    required String name,
    bool? isActive,
    String? companyId,
  }) async {
    final body = <String, Object?>{'name': name.trim()};
    if (isActive != null) body['isActive'] = isActive;
    if (_hasScope(companyId)) body['companyId'] = companyId;
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/departments',
      body: body,
    );
    return AdminDepartment.fromJson(_object(data, 'department'));
  }

  Future<AdminDepartment> updateDepartment(
    String departmentId, {
    required String name,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/departments/$departmentId',
      query: _scopeQuery(companyId),
      body: {'name': name.trim()},
    );
    return AdminDepartment.fromJson(_object(data, 'department'));
  }

  Future<AdminDepartment> updateDepartmentStatus(
    String departmentId, {
    required bool isActive,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/departments/$departmentId/status',
      query: _scopeQuery(companyId),
      body: {'isActive': isActive},
    );
    return AdminDepartment.fromJson(_object(data, 'department'));
  }

  Future<List<AdminDesignation>> listDesignations({String? companyId}) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/designations',
      query: _scopeQuery(companyId),
    );
    return _list(data, 'designations')
        .map(AdminDesignation.fromJson)
        .toList(growable: false);
  }

  Future<AdminDesignation> getDesignation(
    String designationId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/designations/$designationId',
      query: _scopeQuery(companyId),
    );
    return AdminDesignation.fromJson(_object(data, 'designation'));
  }

  Future<AdminDesignation> createDesignation({
    required String title,
    String? departmentId,
    bool? isActive,
    String? companyId,
  }) async {
    final body = <String, Object?>{'title': title.trim()};
    if (_hasText(departmentId)) body['departmentId'] = departmentId;
    if (isActive != null) body['isActive'] = isActive;
    if (_hasScope(companyId)) body['companyId'] = companyId;
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/designations',
      body: body,
    );
    return AdminDesignation.fromJson(_object(data, 'designation'));
  }

  Future<AdminDesignation> updateDesignation(
    String designationId, {
    required String title,
    required String? departmentId,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/designations/$designationId',
      query: _scopeQuery(companyId),
      body: {
        'title': title.trim(),
        'departmentId': _hasText(departmentId) ? departmentId : null,
      },
    );
    return AdminDesignation.fromJson(_object(data, 'designation'));
  }

  Future<AdminDesignation> updateDesignationStatus(
    String designationId, {
    required bool isActive,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/designations/$designationId/status',
      query: _scopeQuery(companyId),
      body: {'isActive': isActive},
    );
    return AdminDesignation.fromJson(_object(data, 'designation'));
  }

  Future<List<AdminEmployee>> listEmployees({String? companyId}) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/employees',
      query: _scopeQuery(companyId),
    );
    return _list(data, 'employees')
        .map(AdminEmployee.fromJson)
        .toList(growable: false);
  }

  Future<AdminEmployee> getEmployee(
    String employeeId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/employees/$employeeId',
      query: _scopeQuery(companyId),
    );
    return AdminEmployee.fromJson(_object(data, 'employee'));
  }

  Future<AdminEmployee> createEmployee({
    required String email,
    required String temporaryPassword,
    required String firstName,
    required String lastName,
    required String employeeCode,
    required String role,
    String? phone,
    String? departmentId,
    String? designationId,
    String? managerId,
    String? hireDate,
    String? companyId,
  }) async {
    final body = <String, Object?>{
      'email': email.trim().toLowerCase(),
      'temporaryPassword': temporaryPassword,
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'employeeCode': employeeCode.trim(),
      'role': role,
    };
    if (_hasText(phone)) body['phone'] = phone!.trim();
    if (_hasText(departmentId)) body['departmentId'] = departmentId;
    if (_hasText(designationId)) body['designationId'] = designationId;
    if (_hasText(managerId)) body['managerId'] = managerId;
    if (_hasText(hireDate)) body['hireDate'] = hireDate;
    if (_hasScope(companyId)) body['companyId'] = companyId;
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/employees',
      body: body,
    );
    return AdminEmployee.fromJson(_object(data, 'employee'));
  }

  Future<AdminEmployee> updateEmployee(
    String employeeId, {
    required String firstName,
    required String lastName,
    required String employeeCode,
    required String? phone,
    required String? departmentId,
    required String? designationId,
    String? hireDate,
    String? companyId,
  }) async {
    final body = <String, Object?>{
      'firstName': firstName.trim(),
      'lastName': lastName.trim(),
      'employeeCode': employeeCode.trim(),
      'phone': _hasText(phone) ? phone!.trim() : null,
      'departmentId': _hasText(departmentId) ? departmentId : null,
      'designationId': _hasText(designationId) ? designationId : null,
    };
    if (hireDate != null) {
      body['hireDate'] = _hasText(hireDate) ? hireDate : null;
    }
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/employees/$employeeId',
      query: _scopeQuery(companyId),
      body: body,
    );
    return AdminEmployee.fromJson(_object(data, 'employee'));
  }

  Future<AdminEmployee> updateEmployeeStatus(
    String employeeId, {
    required String status,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/employees/$employeeId/status',
      query: _scopeQuery(companyId),
      body: {'status': status},
    );
    return AdminEmployee.fromJson(_object(data, 'employee'));
  }

  Future<AdminEmployee> updateEmployeeManager(
    String employeeId, {
    required String? managerId,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/employees/$employeeId/manager',
      query: _scopeQuery(companyId),
      body: {'managerId': _hasText(managerId) ? managerId : null},
    );
    return AdminEmployee.fromJson(_object(data, 'employee'));
  }

  Future<FaceEnrollment> getFaceStatus(
    String employeeId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/employees/$employeeId/face-status',
      query: _scopeQuery(companyId),
    );
    return FaceEnrollment.fromJson(_object(data, 'faceEnrollment'));
  }

  Future<FaceEnrollment> upsertFaceEnrollment(
    String employeeId, {
    String provider = 'mock',
    String? providerSubjectId,
    String? templateReference,
    String? companyId,
  }) async {
    final body = <String, Object?>{'provider': provider};
    if (_hasText(providerSubjectId)) {
      body['providerSubjectId'] = providerSubjectId!.trim();
    }
    if (_hasText(templateReference)) {
      body['templateReference'] = templateReference!.trim();
    }
    if (_hasScope(companyId)) body['companyId'] = companyId;
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/employees/$employeeId/face-enrollment',
      body: body,
    );
    return FaceEnrollment.fromJson(_object(data, 'faceEnrollment'));
  }

  Future<FaceEnrollment> updateFaceEnrollmentStatus(
    String employeeId, {
    required String status,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/employees/$employeeId/face-enrollment/status',
      query: _scopeQuery(companyId),
      body: {'status': status},
    );
    return FaceEnrollment.fromJson(_object(data, 'faceEnrollment'));
  }

  Future<List<AdminGeofence>> listGeofences({String? companyId}) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/geofences',
      query: _scopeQuery(companyId),
    );
    return _list(data, 'geofences')
        .map(AdminGeofence.fromJson)
        .toList(growable: false);
  }

  Future<AdminGeofence> getGeofence(
    String geofenceId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/geofences/$geofenceId',
      query: _scopeQuery(companyId),
    );
    return AdminGeofence.fromJson(_object(data, 'geofence'));
  }

  Future<AdminGeofence> createGeofence({
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String status = 'ACTIVE',
    String? companyId,
  }) async {
    final body = <String, Object?>{
      'name': name.trim(),
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'status': status,
    };
    if (_hasScope(companyId)) body['companyId'] = companyId;
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/geofences',
      body: body,
    );
    return AdminGeofence.fromJson(_object(data, 'geofence'));
  }

  Future<AdminGeofence> updateGeofence(
    String geofenceId, {
    required String name,
    required double latitude,
    required double longitude,
    required int radiusMeters,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/geofences/$geofenceId',
      query: _scopeQuery(companyId),
      body: {
        'name': name.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
      },
    );
    return AdminGeofence.fromJson(_object(data, 'geofence'));
  }

  Future<AdminGeofence> updateGeofenceStatus(
    String geofenceId, {
    required String status,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/geofences/$geofenceId/status',
      query: _scopeQuery(companyId),
      body: {'status': status},
    );
    return AdminGeofence.fromJson(_object(data, 'geofence'));
  }

  Future<List<AdminAttendanceSession>> listAttendance({
    String? employeeId,
    String? from,
    String? to,
    String? status,
    String? companyId,
  }) async {
    final query = <String, Object?>{
      if (_hasScope(companyId)) 'companyId': companyId,
      if (_hasText(employeeId)) 'employeeId': employeeId!.trim(),
      if (_hasText(from)) 'from': from,
      if (_hasText(to)) 'to': to,
      if (_hasText(status)) 'status': status,
    };
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/attendance',
      query: query.isEmpty ? null : query,
    );
    return _list(data, 'attendanceSessions')
        .map(AdminAttendanceSession.fromJson)
        .toList(growable: false);
  }

  Future<List<AdminShift>> listShifts({String? companyId}) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/shifts',
      query: _scopeQuery(companyId),
    );
    return _list(data, 'shifts')
        .map(AdminShift.fromJson)
        .toList(growable: false);
  }

  Future<AdminShift> getShift(
    String shiftId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/shifts/$shiftId',
      query: _scopeQuery(companyId),
    );
    return AdminShift.fromJson(_object(data, 'shift'));
  }

  Future<AdminShift> createShift({
    required String name,
    required String startTime,
    required String endTime,
    String? companyId,
  }) async {
    final body = <String, Object?>{
      'name': name.trim(),
      'startTime': startTime.trim(),
      'endTime': endTime.trim(),
    };
    if (_hasScope(companyId)) body['companyId'] = companyId;
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/shifts',
      body: body,
    );
    return AdminShift.fromJson(_object(data, 'shift'));
  }

  Future<AdminShift> updateShift(
    String shiftId, {
    required String name,
    required String startTime,
    required String endTime,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/shifts/$shiftId',
      query: _scopeQuery(companyId),
      body: {
        'name': name.trim(),
        'startTime': startTime.trim(),
        'endTime': endTime.trim(),
      },
    );
    return AdminShift.fromJson(_object(data, 'shift'));
  }

  Future<AdminShift> updateShiftStatus(
    String shiftId, {
    required String status,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/shifts/$shiftId/status',
      query: _scopeQuery(companyId),
      body: {'status': status},
    );
    return AdminShift.fromJson(_object(data, 'shift'));
  }

  Future<AdminShiftAssignment> assignShift(
    String shiftId, {
    required String employeeId,
    required String startsOn,
    String? endsOn,
    String? companyId,
  }) async {
    final body = <String, Object?>{
      'employeeId': employeeId,
      'startsOn': startsOn,
      'endsOn': _hasText(endsOn) ? endsOn : null,
    };
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/shifts/$shiftId/assign',
      query: _scopeQuery(companyId),
      body: body,
    );
    return AdminShiftAssignment.fromJson(_object(data, 'assignment'));
  }

  Future<List<AdminShiftAssignment>> listShiftAssignments(
    String shiftId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/shifts/$shiftId/assignments',
      query: _scopeQuery(companyId),
    );
    return _list(data, 'assignments')
        .map(AdminShiftAssignment.fromJson)
        .toList(growable: false);
  }

  Future<AdminShiftAssignment> updateShiftAssignment(
    String assignmentId, {
    required String startsOn,
    String? endsOn,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/shift-assignments/$assignmentId',
      query: _scopeQuery(companyId),
      body: {
        'startsOn': startsOn,
        'endsOn': _hasText(endsOn) ? endsOn : null,
      },
    );
    return AdminShiftAssignment.fromJson(_object(data, 'assignment'));
  }

  Future<void> deleteShiftAssignment(
    String assignmentId, {
    String? companyId,
  }) async {
    await _api.delete<Map<String, Object?>>(
      '/api/admin/shift-assignments/$assignmentId',
      query: _scopeQuery(companyId),
    );
  }
}

Map<String, Object?>? _scopeQuery(String? companyId) {
  if (!_hasScope(companyId)) return null;
  return {'companyId': companyId};
}

List<Map<String, Object?>> _list(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList(growable: false);
}

Map<String, Object?> _object(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is Map) return Map<String, Object?>.from(value);
  return data;
}

bool _hasScope(String? value) => _hasText(value);

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
