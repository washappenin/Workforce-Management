import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import 'employee_models.dart';

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(ref.watch(apiClientProvider));
});

final employeeProfileProvider =
    FutureProvider.autoDispose<EmployeeProfile>((ref) {
  return ref.watch(employeeRepositoryProvider).getMyProfile();
});

final employeeDashboardProvider =
    FutureProvider.autoDispose<EmployeeDashboard>((ref) {
  return ref.watch(employeeRepositoryProvider).getMyDashboard();
});

final attendanceSessionsProvider =
    FutureProvider.autoDispose<List<AttendanceSession>>((ref) {
  return ref.watch(employeeRepositoryProvider).listMyAttendance();
});

final shiftAssignmentsProvider =
    FutureProvider.autoDispose<List<ShiftAssignment>>((ref) {
  return ref.watch(employeeRepositoryProvider).listMyShifts();
});

final leaveSummaryProvider = FutureProvider.autoDispose<LeaveSummary>((ref) {
  return ref.watch(employeeRepositoryProvider).listMyLeave();
});

final okrsProvider = FutureProvider.autoDispose<List<OkrItem>>((ref) {
  return ref.watch(employeeRepositoryProvider).listMyOkrs();
});

final reviewsProvider =
    FutureProvider.autoDispose<List<PerformanceReviewItem>>((ref) {
  return ref.watch(employeeRepositoryProvider).listMyReviews();
});

final okrProvider =
    FutureProvider.autoDispose.family<OkrItem, String>((ref, okrId) {
  return ref.watch(employeeRepositoryProvider).getOkr(okrId);
});

final reviewProvider = FutureProvider.autoDispose
    .family<PerformanceReviewItem, String>((ref, reviewId) {
  return ref.watch(employeeRepositoryProvider).getReview(reviewId);
});

class EmployeeRepository {
  const EmployeeRepository(this._api);

  final ApiClient _api;

  Future<EmployeeProfile> getMyProfile() async {
    final data = await _api.get<Map<String, Object?>>('/api/employees/me');
    return EmployeeProfile.fromJson(_object(data, 'employee'));
  }

  Future<EmployeeDashboard> getMyDashboard() async {
    final data =
        await _api.get<Map<String, Object?>>('/api/reports/me/dashboard');
    return EmployeeDashboard.fromJson(_object(data, 'dashboard'));
  }

  Future<List<AttendanceSession>> listMyAttendance() async {
    final data = await _api.get<Map<String, Object?>>('/api/attendance/me');
    return _list(data, 'attendanceSessions')
        .map(AttendanceSession.fromJson)
        .toList(growable: false);
  }

  Future<List<ShiftAssignment>> listMyShifts() async {
    final data = await _api.get<Map<String, Object?>>('/api/shifts/me');
    return _list(data, 'assignments')
        .map(ShiftAssignment.fromJson)
        .toList(growable: false);
  }

  Future<LeaveSummary> listMyLeave() async {
    final data = await _api.get<Map<String, Object?>>('/api/leave/me');
    return LeaveSummary.fromJson(data);
  }

  Future<LeaveRequest> submitLeaveRequest({
    required String leaveTypeId,
    required String startDate,
    required String endDate,
    String? reason,
  }) async {
    final body = <String, Object?>{
      'leaveTypeId': leaveTypeId,
      'startDate': startDate,
      'endDate': endDate,
      'reason': _hasText(reason) ? reason!.trim() : null,
    };
    final data = await _api.post<Map<String, Object?>>(
      '/api/leave/request',
      body: body,
    );
    return LeaveRequest.fromJson(_object(data, 'leaveRequest'));
  }

  Future<List<OkrItem>> listMyOkrs({String? status}) async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/okrs/me',
      query: _hasText(status) ? {'status': status} : null,
    );
    return _list(data, 'okrs').map(OkrItem.fromJson).toList(growable: false);
  }

  Future<OkrItem> getOkr(String okrId) async {
    final data = await _api.get<Map<String, Object?>>('/api/okrs/$okrId');
    return OkrItem.fromJson(_object(data, 'okr'));
  }

  Future<OkrItem> updateOkrProgress(
    String okrId, {
    required int progressPercent,
    String? note,
  }) async {
    final data = await _api.post<Map<String, Object?>>(
      '/api/okrs/$okrId/progress',
      body: {
        'progressPercent': progressPercent,
        'note': _hasText(note) ? note!.trim() : null,
      },
    );
    return OkrItem.fromJson(_object(data, 'okr'));
  }

  Future<OkrItem> employeeApproveOkr(
    String okrId, {
    String? comment,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/okrs/$okrId/employee-approve',
      body: {'comment': _hasText(comment) ? comment!.trim() : null},
    );
    return OkrItem.fromJson(_object(data, 'okr'));
  }

  Future<List<PerformanceReviewItem>> listMyReviews() async {
    final data = await _api.get<Map<String, Object?>>('/api/reviews/me');
    return _list(data, 'reviews')
        .map(PerformanceReviewItem.fromJson)
        .toList(growable: false);
  }

  Future<PerformanceReviewItem> getReview(String reviewId) async {
    final data = await _api.get<Map<String, Object?>>('/api/reviews/$reviewId');
    return PerformanceReviewItem.fromJson(_object(data, 'review'));
  }
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

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
