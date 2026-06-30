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

final leaveTypesProvider =
    FutureProvider.autoDispose<List<AdminLeaveType>>((ref) {
  return ref.watch(adminRepositoryProvider).listLeaveTypes();
});

final leaveTypeProvider =
    FutureProvider.autoDispose.family<AdminLeaveType, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).getLeaveType(id);
});

final leaveEntitlementsProvider =
    FutureProvider.autoDispose<List<AdminLeaveEntitlement>>((ref) {
  return ref.watch(adminRepositoryProvider).listLeaveEntitlements();
});

final leaveEntitlementProvider =
    FutureProvider.autoDispose.family<AdminLeaveEntitlement, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).getLeaveEntitlement(id);
});

final adminLeaveRequestsProvider = FutureProvider.autoDispose
    .family<List<AdminLeaveRequest>, String?>((ref, status) {
  return ref.watch(adminRepositoryProvider).listAdminLeaveRequests(
        status: status,
      );
});

final adminOkrsProvider =
    FutureProvider.autoDispose.family<List<AdminOkr>, String?>((ref, status) {
  return ref.watch(adminRepositoryProvider).listAdminOkrs(status: status);
});

final adminOkrProvider =
    FutureProvider.autoDispose.family<AdminOkr, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).getOkr(id);
});

final adminReviewCyclesProvider =
    FutureProvider.autoDispose<List<AdminReviewCycle>>((ref) {
  return ref.watch(adminRepositoryProvider).listReviewCycles();
});

final adminReviewCycleProvider =
    FutureProvider.autoDispose.family<AdminReviewCycle, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).getReviewCycle(id);
});

final adminReviewsProvider = FutureProvider.autoDispose
    .family<List<AdminPerformanceReview>, String?>((ref, status) {
  return ref.watch(adminRepositoryProvider).listAdminReviews(status: status);
});

final adminReviewProvider = FutureProvider.autoDispose
    .family<AdminPerformanceReview, String>((ref, id) {
  return ref.watch(adminRepositoryProvider).getReview(id);
});

final adminSubscriptionProvider =
    FutureProvider.autoDispose<AdminCompanySubscription?>((ref) {
  return ref.watch(adminRepositoryProvider).getAdminSubscription();
});

final adminPaymentRecordsProvider =
    FutureProvider.autoDispose<List<AdminPaymentRecord>>((ref) {
  return ref.watch(adminRepositoryProvider).listAdminPaymentRecords();
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

  Future<List<AdminLeaveType>> listLeaveTypes({String? companyId}) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/leave-types',
      query: _scopeQuery(companyId),
    );
    return _list(data, 'leaveTypes')
        .map(AdminLeaveType.fromJson)
        .toList(growable: false);
  }

  Future<AdminLeaveType> getLeaveType(
    String leaveTypeId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/leave-types/$leaveTypeId',
      query: _scopeQuery(companyId),
    );
    return AdminLeaveType.fromJson(_object(data, 'leaveType'));
  }

  Future<AdminLeaveType> createLeaveType({
    required String name,
    double? defaultAnnualAllowance,
    String? companyId,
  }) async {
    final body = <String, Object?>{
      'name': name.trim(),
      'defaultAnnualAllowance': defaultAnnualAllowance,
    };
    if (_hasScope(companyId)) body['companyId'] = companyId;
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/leave-types',
      body: body,
    );
    return AdminLeaveType.fromJson(_object(data, 'leaveType'));
  }

  Future<AdminLeaveType> updateLeaveType(
    String leaveTypeId, {
    required String name,
    double? defaultAnnualAllowance,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/leave-types/$leaveTypeId',
      query: _scopeQuery(companyId),
      body: {
        'name': name.trim(),
        'defaultAnnualAllowance': defaultAnnualAllowance,
      },
    );
    return AdminLeaveType.fromJson(_object(data, 'leaveType'));
  }

  Future<AdminLeaveType> updateLeaveTypeStatus(
    String leaveTypeId, {
    required String status,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/leave-types/$leaveTypeId/status',
      query: _scopeQuery(companyId),
      body: {'status': status},
    );
    return AdminLeaveType.fromJson(_object(data, 'leaveType'));
  }

  Future<List<AdminLeaveEntitlement>> listLeaveEntitlements({
    String? employeeId,
    String? leaveTypeId,
    int? year,
    String? companyId,
  }) async {
    final query = <String, Object?>{
      if (_hasScope(companyId)) 'companyId': companyId,
      if (_hasText(employeeId)) 'employeeId': employeeId,
      if (_hasText(leaveTypeId)) 'leaveTypeId': leaveTypeId,
      if (year != null) 'year': year,
    };
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/leave-entitlements',
      query: query.isEmpty ? null : query,
    );
    return _list(data, 'entitlements')
        .map(AdminLeaveEntitlement.fromJson)
        .toList(growable: false);
  }

  Future<AdminLeaveEntitlement> getLeaveEntitlement(
    String entitlementId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/leave-entitlements/$entitlementId',
      query: _scopeQuery(companyId),
    );
    return AdminLeaveEntitlement.fromJson(_object(data, 'entitlement'));
  }

  Future<AdminLeaveEntitlement> upsertLeaveEntitlement({
    required String employeeId,
    required String leaveTypeId,
    required int year,
    required double totalDays,
    double usedDays = 0,
    String? companyId,
  }) async {
    final body = <String, Object?>{
      'employeeId': employeeId,
      'leaveTypeId': leaveTypeId,
      'year': year,
      'totalDays': totalDays,
      'usedDays': usedDays,
    };
    if (_hasScope(companyId)) body['companyId'] = companyId;
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/leave-entitlements',
      body: body,
    );
    return AdminLeaveEntitlement.fromJson(_object(data, 'entitlement'));
  }

  Future<AdminLeaveEntitlement> updateLeaveEntitlement(
    String entitlementId, {
    required double totalDays,
    required double usedDays,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/leave-entitlements/$entitlementId',
      query: _scopeQuery(companyId),
      body: {
        'totalDays': totalDays,
        'usedDays': usedDays,
      },
    );
    return AdminLeaveEntitlement.fromJson(_object(data, 'entitlement'));
  }

  Future<List<AdminLeaveRequest>> listAdminLeaveRequests({
    String? employeeId,
    String? leaveTypeId,
    String? status,
    String? from,
    String? to,
    String? companyId,
  }) async {
    final query = <String, Object?>{
      if (_hasScope(companyId)) 'companyId': companyId,
      if (_hasText(employeeId)) 'employeeId': employeeId,
      if (_hasText(leaveTypeId)) 'leaveTypeId': leaveTypeId,
      if (_hasText(status)) 'status': status,
      if (_hasText(from)) 'from': from,
      if (_hasText(to)) 'to': to,
    };
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/leave-requests',
      query: query.isEmpty ? null : query,
    );
    return _list(data, 'leaveRequests')
        .map(AdminLeaveRequest.fromJson)
        .toList(growable: false);
  }

  Future<AdminLeaveRequest> approveLeaveRequest(
    String leaveRequestId, {
    String? comment,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/leave/$leaveRequestId/approve',
      query: _scopeQuery(companyId),
      body: {'comment': _hasText(comment) ? comment!.trim() : null},
    );
    return AdminLeaveRequest.fromJson(_object(data, 'leaveRequest'));
  }

  Future<AdminLeaveRequest> rejectLeaveRequest(
    String leaveRequestId, {
    String? comment,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/leave/$leaveRequestId/reject',
      query: _scopeQuery(companyId),
      body: {'comment': _hasText(comment) ? comment!.trim() : null},
    );
    return AdminLeaveRequest.fromJson(_object(data, 'leaveRequest'));
  }

  Future<List<AdminOkr>> listAdminOkrs({
    String? employeeId,
    String? status,
    String? from,
    String? to,
    String? companyId,
  }) async {
    final query = <String, Object?>{
      if (_hasScope(companyId)) 'companyId': companyId,
      if (_hasText(employeeId)) 'employeeId': employeeId,
      if (_hasText(status)) 'status': status,
      if (_hasText(from)) 'from': from,
      if (_hasText(to)) 'to': to,
    };
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/okrs',
      query: query.isEmpty ? null : query,
    );
    return _list(data, 'okrs').map(AdminOkr.fromJson).toList(growable: false);
  }

  Future<AdminOkr> createOkr({
    required String employeeId,
    required String title,
    String? description,
    String? dueDate,
    String? companyId,
  }) async {
    final body = <String, Object?>{
      'employeeId': employeeId,
      'title': title.trim(),
      'description': _hasText(description) ? description!.trim() : null,
      'dueDate': _hasText(dueDate) ? dueDate : null,
    };
    if (_hasScope(companyId)) body['companyId'] = companyId;
    final data = await _api.post<Map<String, Object?>>(
      '/api/okrs',
      body: body,
    );
    return AdminOkr.fromJson(_object(data, 'okr'));
  }

  Future<AdminOkr> getOkr(
    String okrId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/okrs/$okrId',
      query: _scopeQuery(companyId),
    );
    return AdminOkr.fromJson(_object(data, 'okr'));
  }

  Future<AdminOkr> updateOkr(
    String okrId, {
    required String title,
    required String? description,
    required String? dueDate,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/okrs/$okrId',
      query: _scopeQuery(companyId),
      body: {
        'title': title.trim(),
        'description': _hasText(description) ? description!.trim() : null,
        'dueDate': _hasText(dueDate) ? dueDate : null,
      },
    );
    return AdminOkr.fromJson(_object(data, 'okr'));
  }

  Future<AdminOkr> updateOkrStatus(
    String okrId, {
    required String status,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/okrs/$okrId/status',
      query: _scopeQuery(companyId),
      body: {'status': status},
    );
    return AdminOkr.fromJson(_object(data, 'okr'));
  }

  Future<AdminOkr> managerApproveOkr(
    String okrId, {
    String? comment,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/okrs/$okrId/manager-approve',
      query: _scopeQuery(companyId),
      body: {'comment': _hasText(comment) ? comment!.trim() : null},
    );
    return AdminOkr.fromJson(_object(data, 'okr'));
  }

  Future<List<AdminReviewCycle>> listReviewCycles({String? companyId}) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/review-cycles',
      query: _scopeQuery(companyId),
    );
    return _list(data, 'reviewCycles')
        .map(AdminReviewCycle.fromJson)
        .toList(growable: false);
  }

  Future<AdminReviewCycle> getReviewCycle(
    String reviewCycleId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/review-cycles/$reviewCycleId',
      query: _scopeQuery(companyId),
    );
    return AdminReviewCycle.fromJson(_object(data, 'reviewCycle'));
  }

  Future<AdminReviewCycle> createReviewCycle({
    required String name,
    required String startDate,
    required String endDate,
    String? companyId,
  }) async {
    final body = <String, Object?>{
      'name': name.trim(),
      'startDate': startDate,
      'endDate': endDate,
    };
    if (_hasScope(companyId)) body['companyId'] = companyId;
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/review-cycles',
      body: body,
    );
    return AdminReviewCycle.fromJson(_object(data, 'reviewCycle'));
  }

  Future<AdminReviewCycle> updateReviewCycle(
    String reviewCycleId, {
    required String name,
    required String startDate,
    required String endDate,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/review-cycles/$reviewCycleId',
      query: _scopeQuery(companyId),
      body: {
        'name': name.trim(),
        'startDate': startDate,
        'endDate': endDate,
      },
    );
    return AdminReviewCycle.fromJson(_object(data, 'reviewCycle'));
  }

  Future<AdminReviewCycle> updateReviewCycleStatus(
    String reviewCycleId, {
    required String status,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/admin/review-cycles/$reviewCycleId/status',
      query: _scopeQuery(companyId),
      body: {'status': status},
    );
    return AdminReviewCycle.fromJson(_object(data, 'reviewCycle'));
  }

  Future<List<AdminPerformanceReview>> listAdminReviews({
    String? employeeId,
    String? reviewCycleId,
    String? status,
    String? from,
    String? to,
    String? companyId,
  }) async {
    final query = <String, Object?>{
      if (_hasScope(companyId)) 'companyId': companyId,
      if (_hasText(employeeId)) 'employeeId': employeeId,
      if (_hasText(reviewCycleId)) 'reviewCycleId': reviewCycleId,
      if (_hasText(status)) 'status': status,
      if (_hasText(from)) 'from': from,
      if (_hasText(to)) 'to': to,
    };
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/reviews',
      query: query.isEmpty ? null : query,
    );
    return _list(data, 'reviews')
        .map(AdminPerformanceReview.fromJson)
        .toList(growable: false);
  }

  Future<AdminPerformanceReview> getReview(
    String reviewId, {
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/reviews/$reviewId',
      query: _scopeQuery(companyId),
    );
    return AdminPerformanceReview.fromJson(_object(data, 'review'));
  }

  Future<AdminPerformanceReview> submitManagerReview({
    required String employeeId,
    required String reviewCycleId,
    required String summary,
    double? rating,
    String? companyId,
  }) async {
    final data = await _api.post<Map<String, Object?>>(
      '/api/reviews/$employeeId/manager-review',
      query: _scopeQuery(companyId),
      body: {
        'reviewCycleId': reviewCycleId,
        'summary': summary.trim(),
        'rating': rating,
      },
    );
    return AdminPerformanceReview.fromJson(_object(data, 'review'));
  }

  Future<AdminPerformanceReview> updateReview(
    String reviewId, {
    required String summary,
    double? rating,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/reviews/$reviewId',
      query: _scopeQuery(companyId),
      body: {
        'summary': summary.trim(),
        'rating': rating,
      },
    );
    return AdminPerformanceReview.fromJson(_object(data, 'review'));
  }

  Future<AdminPerformanceReview> updateReviewStatus(
    String reviewId, {
    required String status,
    String? companyId,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/reviews/$reviewId/status',
      query: _scopeQuery(companyId),
      body: {'status': status},
    );
    return AdminPerformanceReview.fromJson(_object(data, 'review'));
  }

  Future<AdminNotificationBroadcastResult> broadcastNotification({
    required String title,
    required String message,
    required String type,
    String? targetRole,
    List<String>? employeeIds,
    String? companyId,
  }) async {
    final body = <String, Object?>{
      'title': title.trim(),
      'message': message.trim(),
      'type': type,
      if (_hasText(targetRole)) 'targetRole': targetRole,
      if (employeeIds != null && employeeIds.isNotEmpty)
        'employeeIds': employeeIds,
      if (_hasScope(companyId)) 'companyId': companyId,
    };
    final data = await _api.post<Map<String, Object?>>(
      '/api/admin/notifications/broadcast',
      body: body,
    );
    return AdminNotificationBroadcastResult.fromJson(data);
  }

  Future<AdminCompanySubscription?> getAdminSubscription({
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/subscription',
      query: _scopeQuery(companyId),
    );
    final value = data['subscription'];
    if (value == null) return null;
    if (value is Map) {
      return AdminCompanySubscription.fromJson(
        Map<String, Object?>.from(value),
      );
    }
    return AdminCompanySubscription.fromJson(data);
  }

  Future<List<AdminPaymentRecord>> listAdminPaymentRecords({
    String? companyId,
  }) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/admin/payment-records',
      query: _scopeQuery(companyId),
    );
    return _list(data, 'paymentRecords')
        .map(AdminPaymentRecord.fromJson)
        .toList(growable: false);
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
