import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import 'manager_models.dart';

final managerRepositoryProvider = Provider<ManagerRepository>((ref) {
  return ManagerRepository(ref.watch(apiClientProvider));
});

final managerDashboardProvider = FutureProvider.autoDispose<ManagerDashboard>(
  (ref) => ref.watch(managerRepositoryProvider).getDashboard(),
);

final managerAttendanceReportProvider =
    FutureProvider.autoDispose<ManagerAttendanceReport>(
  (ref) => ref.watch(managerRepositoryProvider).getAttendanceReport(),
);

final managerLeaveRequestsProvider =
    FutureProvider.autoDispose<List<ManagerLeaveRequest>>(
  (ref) => ref.watch(managerRepositoryProvider).listLeaveRequests(),
);

final managerLeaveReportProvider =
    FutureProvider.autoDispose<ManagerLeaveReport>(
  (ref) => ref.watch(managerRepositoryProvider).getLeaveReport(),
);

final managerOkrsProvider = FutureProvider.autoDispose<List<ManagerOkr>>(
  (ref) => ref.watch(managerRepositoryProvider).listOkrs(),
);

final managerOkrProvider =
    FutureProvider.autoDispose.family<ManagerOkr, String>(
  (ref, id) => ref.watch(managerRepositoryProvider).getOkr(id),
);

final managerOkrReportProvider = FutureProvider.autoDispose<ManagerOkrReport>(
  (ref) => ref.watch(managerRepositoryProvider).getOkrReport(),
);

final managerReviewsProvider =
    FutureProvider.autoDispose<List<ManagerPerformanceReview>>(
  (ref) => ref.watch(managerRepositoryProvider).listReviews(),
);

final managerReviewProvider =
    FutureProvider.autoDispose.family<ManagerPerformanceReview, String>(
  (ref, id) => ref.watch(managerRepositoryProvider).getReview(id),
);

final managerPerformanceReportProvider =
    FutureProvider.autoDispose<ManagerPerformanceReport>(
  (ref) => ref.watch(managerRepositoryProvider).getPerformanceReport(),
);

final managerReportsBundleProvider =
    FutureProvider.autoDispose<ManagerReportsBundle>((ref) async {
  final repo = ref.watch(managerRepositoryProvider);
  final results = await Future.wait<Object>([
    repo.getDashboard(),
    repo.getAttendanceReport(),
    repo.getLeaveReport(),
    repo.getOkrReport(),
    repo.getPerformanceReport(),
  ]);
  return ManagerReportsBundle(
    dashboard: results[0] as ManagerDashboard,
    attendance: results[1] as ManagerAttendanceReport,
    leave: results[2] as ManagerLeaveReport,
    okrs: results[3] as ManagerOkrReport,
    performance: results[4] as ManagerPerformanceReport,
  );
});

final managerTeamMembersProvider =
    FutureProvider.autoDispose<List<ManagerTeamMember>>((ref) async {
  final repo = ref.watch(managerRepositoryProvider);
  final results = await Future.wait<Object>([
    repo.listLeaveRequests(),
    repo.listOkrs(),
    repo.listReviews(),
  ]);
  final members = <String, ManagerTeamMember>{};

  for (final request in results[0] as List<ManagerLeaveRequest>) {
    members[request.employeeId] = ManagerTeamMember(
      id: request.employeeId,
      status: 'ACTIVE',
    );
  }
  for (final okr in results[1] as List<ManagerOkr>) {
    members[okr.employeeId] = ManagerTeamMember(
      id: okr.employeeId,
      status: okr.employee?.status ?? 'ACTIVE',
    );
  }
  for (final review in results[2] as List<ManagerPerformanceReview>) {
    members[review.employeeId] = ManagerTeamMember(
      id: review.employeeId,
      status: review.employee?.status ?? 'ACTIVE',
    );
  }

  final sorted = members.values.toList(growable: false)
    ..sort((left, right) => left.id.compareTo(right.id));
  return sorted;
});

class ManagerRepository {
  const ManagerRepository(this._api);

  final ApiClient _api;

  Future<ManagerDashboard> getDashboard() async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/reports/team/dashboard',
    );
    return ManagerDashboard.fromJson(_object(data, 'dashboard'));
  }

  Future<ManagerAttendanceReport> getAttendanceReport() async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/reports/team/attendance',
    );
    return ManagerAttendanceReport.fromJson(_object(data, 'report'));
  }

  Future<ManagerLeaveReport> getLeaveReport() async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/reports/team/leave',
    );
    return ManagerLeaveReport.fromJson(_object(data, 'report'));
  }

  Future<List<ManagerLeaveRequest>> listLeaveRequests() async {
    final data = await _api.get<Map<String, Object?>>('/api/leave/team');
    return listValue(data['leaveRequests'])
        .map(ManagerLeaveRequest.fromJson)
        .toList(growable: false);
  }

  Future<ManagerLeaveRequest> approveLeaveRequest(
    String leaveRequestId, {
    String? comment,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/leave/$leaveRequestId/approve',
      body: {'comment': _hasText(comment) ? comment!.trim() : null},
    );
    return ManagerLeaveRequest.fromJson(_object(data, 'leaveRequest'));
  }

  Future<ManagerLeaveRequest> rejectLeaveRequest(
    String leaveRequestId, {
    String? comment,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/leave/$leaveRequestId/reject',
      body: {'comment': _hasText(comment) ? comment!.trim() : null},
    );
    return ManagerLeaveRequest.fromJson(_object(data, 'leaveRequest'));
  }

  Future<ManagerOkrReport> getOkrReport() async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/reports/team/okrs',
    );
    return ManagerOkrReport.fromJson(_object(data, 'report'));
  }

  Future<List<ManagerOkr>> listOkrs() async {
    final data = await _api.get<Map<String, Object?>>('/api/okrs/team');
    return listValue(data['okrs'])
        .map(ManagerOkr.fromJson)
        .toList(growable: false);
  }

  Future<ManagerOkr> getOkr(String okrId) async {
    final data = await _api.get<Map<String, Object?>>('/api/okrs/$okrId');
    return ManagerOkr.fromJson(_object(data, 'okr'));
  }

  Future<ManagerOkr> createOkr({
    required String employeeId,
    required String title,
    String? description,
    String? dueDate,
  }) async {
    final data = await _api.post<Map<String, Object?>>(
      '/api/okrs',
      body: {
        'employeeId': employeeId.trim(),
        'title': title.trim(),
        'description': _hasText(description) ? description!.trim() : null,
        'dueDate': _hasText(dueDate) ? dueDate!.trim() : null,
      },
    );
    return ManagerOkr.fromJson(_object(data, 'okr'));
  }

  Future<ManagerOkr> updateOkr(
    String okrId, {
    required String title,
    required String? description,
    required String? dueDate,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/okrs/$okrId',
      body: {
        'title': title.trim(),
        'description': _hasText(description) ? description!.trim() : null,
        'dueDate': _hasText(dueDate) ? dueDate!.trim() : null,
      },
    );
    return ManagerOkr.fromJson(_object(data, 'okr'));
  }

  Future<ManagerOkr> updateOkrStatus(
    String okrId, {
    required String status,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/okrs/$okrId/status',
      body: {'status': status},
    );
    return ManagerOkr.fromJson(_object(data, 'okr'));
  }

  Future<ManagerOkr> approveOkr(
    String okrId, {
    String? comment,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/okrs/$okrId/manager-approve',
      body: {'comment': _hasText(comment) ? comment!.trim() : null},
    );
    return ManagerOkr.fromJson(_object(data, 'okr'));
  }

  Future<ManagerPerformanceReport> getPerformanceReport() async {
    final data = await _api.get<Map<String, Object?>>(
      '/api/reports/team/performance',
    );
    return ManagerPerformanceReport.fromJson(_object(data, 'report'));
  }

  Future<List<ManagerPerformanceReview>> listReviews() async {
    final data = await _api.get<Map<String, Object?>>('/api/reviews/team');
    return listValue(data['reviews'])
        .map(ManagerPerformanceReview.fromJson)
        .toList(growable: false);
  }

  Future<ManagerPerformanceReview> getReview(String reviewId) async {
    final data = await _api.get<Map<String, Object?>>('/api/reviews/$reviewId');
    return ManagerPerformanceReview.fromJson(_object(data, 'review'));
  }

  Future<ManagerPerformanceReview> submitReview({
    required String employeeId,
    required String reviewCycleId,
    required String summary,
    double? rating,
  }) async {
    final data = await _api.post<Map<String, Object?>>(
      '/api/reviews/${employeeId.trim()}/manager-review',
      body: {
        'reviewCycleId': reviewCycleId.trim(),
        'summary': summary.trim(),
        'rating': rating,
      },
    );
    return ManagerPerformanceReview.fromJson(_object(data, 'review'));
  }

  Future<ManagerPerformanceReview> updateReview(
    String reviewId, {
    required String summary,
    double? rating,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/reviews/$reviewId',
      body: {
        'summary': summary.trim(),
        'rating': rating,
      },
    );
    return ManagerPerformanceReview.fromJson(_object(data, 'review'));
  }

  Future<ManagerPerformanceReview> updateReviewStatus(
    String reviewId, {
    required String status,
  }) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/reviews/$reviewId/status',
      body: {'status': status},
    );
    return ManagerPerformanceReview.fromJson(_object(data, 'review'));
  }
}

Map<String, Object?> _object(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is Map) return Map<String, Object?>.from(value);
  return data;
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
