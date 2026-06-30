class ManagerEmployeeRef {
  const ManagerEmployeeRef({
    required this.id,
    required this.companyId,
    required this.status,
    this.managerId,
  });

  final String id;
  final String companyId;
  final String? managerId;
  final String status;

  String get label => 'Employee ${shortId(id)}';

  factory ManagerEmployeeRef.fromJson(Map<String, Object?> json) {
    return ManagerEmployeeRef(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      managerId: optionalString(json['managerId']),
      status: stringValue(json['status'], fallback: 'ACTIVE'),
    );
  }
}

class ManagerTeamMember {
  const ManagerTeamMember({required this.id, required this.status});

  final String id;
  final String status;

  String get label => 'Employee ${shortId(id)}';
}

class ManagerDashboard {
  const ManagerDashboard({
    required this.companyId,
    required this.totalEmployees,
    required this.activeEmployees,
    required this.inactiveEmployees,
    required this.departmentsTotal,
    required this.todayClockIns,
    required this.openSessions,
    required this.pendingLeaveRequests,
    required this.activeOkrs,
    required this.pendingReviews,
    required this.unreadCount,
  });

  final String companyId;
  final int totalEmployees;
  final int activeEmployees;
  final int inactiveEmployees;
  final int departmentsTotal;
  final int todayClockIns;
  final int openSessions;
  final int pendingLeaveRequests;
  final int activeOkrs;
  final int pendingReviews;
  final int unreadCount;

  factory ManagerDashboard.fromJson(Map<String, Object?> json) {
    final employees = objectValue(json['employees']);
    final departments = objectValue(json['departments']);
    final attendance = objectValue(json['attendance']);
    final leave = objectValue(json['leave']);
    final okrs = objectValue(json['okrs']);
    final performance = objectValue(json['performance']);
    final notifications = objectValue(json['notifications']);

    return ManagerDashboard(
      companyId: stringValue(json['companyId']),
      totalEmployees: intValue(employees['total']),
      activeEmployees: intValue(employees['active']),
      inactiveEmployees: intValue(employees['inactive']),
      departmentsTotal: intValue(departments['total']),
      todayClockIns: intValue(attendance['todayClockIns']),
      openSessions: intValue(attendance['openSessions']),
      pendingLeaveRequests: intValue(leave['pendingRequests']),
      activeOkrs: intValue(okrs['active']),
      pendingReviews: intValue(performance['pendingReviews']),
      unreadCount: intValue(notifications['unreadCount']),
    );
  }
}

class ManagerClockInsByDay {
  const ManagerClockInsByDay({required this.date, required this.count});

  final String date;
  final int count;

  factory ManagerClockInsByDay.fromJson(Map<String, Object?> json) {
    return ManagerClockInsByDay(
      date: stringValue(json['date']),
      count: intValue(json['count']),
    );
  }
}

class ManagerAttendanceReport {
  const ManagerAttendanceReport({
    required this.totalSessions,
    required this.openSessions,
    required this.closedSessions,
    required this.clockInsByDay,
  });

  final int totalSessions;
  final int openSessions;
  final int closedSessions;
  final List<ManagerClockInsByDay> clockInsByDay;

  factory ManagerAttendanceReport.fromJson(Map<String, Object?> json) {
    return ManagerAttendanceReport(
      totalSessions: intValue(json['totalSessions']),
      openSessions: intValue(json['openSessions']),
      closedSessions: intValue(json['closedSessions']),
      clockInsByDay: listValue(json['clockInsByDay'])
          .map(ManagerClockInsByDay.fromJson)
          .toList(growable: false),
    );
  }
}

class ManagerLeaveType {
  const ManagerLeaveType({
    required this.id,
    required this.name,
    required this.status,
  });

  final String id;
  final String name;
  final String status;

  factory ManagerLeaveType.fromJson(Map<String, Object?> json) {
    return ManagerLeaveType(
      id: stringValue(json['id']),
      name: stringValue(json['name'], fallback: 'Leave'),
      status: stringValue(json['status'], fallback: 'ACTIVE'),
    );
  }
}

class ManagerLeaveRequest {
  const ManagerLeaveRequest({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.requestedDays,
    required this.status,
    this.reason,
    this.reviewedAt,
    this.reviewComment,
    this.createdAt,
    this.updatedAt,
    this.leaveType,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final String leaveTypeId;
  final String startDate;
  final String endDate;
  final double requestedDays;
  final String status;
  final String? reason;
  final String? reviewedAt;
  final String? reviewComment;
  final String? createdAt;
  final String? updatedAt;
  final ManagerLeaveType? leaveType;

  bool get isPending => status == 'PENDING';
  String get leaveTypeName => leaveType?.name ?? 'Leave';

  factory ManagerLeaveRequest.fromJson(Map<String, Object?> json) {
    final leaveType = objectOrNull(json['leaveType']);
    return ManagerLeaveRequest(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      employeeId: stringValue(json['employeeId']),
      leaveTypeId: stringValue(json['leaveTypeId']),
      startDate: stringValue(json['startDate']),
      endDate: stringValue(json['endDate']),
      requestedDays: doubleValue(json['requestedDays']),
      status: stringValue(json['status'], fallback: 'PENDING'),
      reason: optionalString(json['reason']),
      reviewedAt: optionalString(json['reviewedAt']),
      reviewComment: optionalString(json['reviewComment']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      leaveType:
          leaveType == null ? null : ManagerLeaveType.fromJson(leaveType),
    );
  }
}

class ManagerLeaveUsageByType {
  const ManagerLeaveUsageByType({
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.usedDays,
    required this.totalDays,
  });

  final String leaveTypeId;
  final String leaveTypeName;
  final double usedDays;
  final double totalDays;

  factory ManagerLeaveUsageByType.fromJson(Map<String, Object?> json) {
    return ManagerLeaveUsageByType(
      leaveTypeId: stringValue(json['leaveTypeId']),
      leaveTypeName: stringValue(json['leaveTypeName'], fallback: 'Leave'),
      usedDays: doubleValue(json['usedDays']),
      totalDays: doubleValue(json['totalDays']),
    );
  }
}

class ManagerLowRemainingLeave {
  const ManagerLowRemainingLeave({
    required this.employeeId,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.remainingDays,
  });

  final String employeeId;
  final String leaveTypeId;
  final String leaveTypeName;
  final double remainingDays;

  factory ManagerLowRemainingLeave.fromJson(Map<String, Object?> json) {
    return ManagerLowRemainingLeave(
      employeeId: stringValue(json['employeeId']),
      leaveTypeId: stringValue(json['leaveTypeId']),
      leaveTypeName: stringValue(json['leaveTypeName'], fallback: 'Leave'),
      remainingDays: doubleValue(json['remainingDays']),
    );
  }
}

class ManagerLeaveReport {
  const ManagerLeaveReport({
    required this.totalRequests,
    required this.pendingRequests,
    required this.approvedRequests,
    required this.rejectedRequests,
    required this.leaveUsageByType,
    required this.lowRemainingLeave,
  });

  final int totalRequests;
  final int pendingRequests;
  final int approvedRequests;
  final int rejectedRequests;
  final List<ManagerLeaveUsageByType> leaveUsageByType;
  final List<ManagerLowRemainingLeave> lowRemainingLeave;

  factory ManagerLeaveReport.fromJson(Map<String, Object?> json) {
    return ManagerLeaveReport(
      totalRequests: intValue(json['totalRequests']),
      pendingRequests: intValue(json['pendingRequests']),
      approvedRequests: intValue(json['approvedRequests']),
      rejectedRequests: intValue(json['rejectedRequests']),
      leaveUsageByType: listValue(json['leaveUsageByType'])
          .map(ManagerLeaveUsageByType.fromJson)
          .toList(growable: false),
      lowRemainingLeave: listValue(json['lowRemainingLeave'])
          .map(ManagerLowRemainingLeave.fromJson)
          .toList(growable: false),
    );
  }
}

class ManagerOkrProgressUpdate {
  const ManagerOkrProgressUpdate({
    required this.id,
    required this.progressPercent,
    this.note,
    this.createdAt,
  });

  final String id;
  final int progressPercent;
  final String? note;
  final String? createdAt;

  factory ManagerOkrProgressUpdate.fromJson(Map<String, Object?> json) {
    return ManagerOkrProgressUpdate(
      id: stringValue(json['id']),
      progressPercent: intValue(json['progressPercent']),
      note: optionalString(json['note']),
      createdAt: optionalString(json['createdAt']),
    );
  }
}

class ManagerOkrApproval {
  const ManagerOkrApproval({
    required this.id,
    required this.approverEmployeeId,
    required this.status,
    this.comment,
  });

  final String id;
  final String approverEmployeeId;
  final String status;
  final String? comment;

  factory ManagerOkrApproval.fromJson(Map<String, Object?> json) {
    return ManagerOkrApproval(
      id: stringValue(json['id']),
      approverEmployeeId: stringValue(json['approverEmployeeId']),
      status: stringValue(json['status'], fallback: 'PENDING'),
      comment: optionalString(json['comment']),
    );
  }
}

class ManagerOkr {
  const ManagerOkr({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.assignedById,
    required this.title,
    required this.status,
    required this.progressUpdates,
    required this.approvals,
    this.description,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.employee,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final String assignedById;
  final String title;
  final String? description;
  final String status;
  final String? dueDate;
  final String? createdAt;
  final String? updatedAt;
  final ManagerEmployeeRef? employee;
  final List<ManagerOkrProgressUpdate> progressUpdates;
  final List<ManagerOkrApproval> approvals;

  int get progressPercent =>
      progressUpdates.isEmpty ? 0 : progressUpdates.first.progressPercent;

  bool get employeeApproved => approvals.any(
        (approval) =>
            approval.approverEmployeeId == employeeId &&
            approval.status == 'APPROVED',
      );

  bool get managerApproved => approvals.any(
        (approval) =>
            approval.approverEmployeeId != employeeId &&
            approval.status == 'APPROVED',
      );

  bool get canApprove => !managerApproved && status != 'ARCHIVED';

  factory ManagerOkr.fromJson(Map<String, Object?> json) {
    final employee = objectOrNull(json['employee']);
    return ManagerOkr(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      employeeId: stringValue(json['employeeId']),
      assignedById: stringValue(json['assignedById']),
      title: stringValue(json['title'], fallback: 'Objective'),
      description: optionalString(json['description']),
      status: stringValue(json['status'], fallback: 'ASSIGNED'),
      dueDate: optionalString(json['dueDate']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      employee: employee == null ? null : ManagerEmployeeRef.fromJson(employee),
      progressUpdates: listValue(json['progressUpdates'])
          .map(ManagerOkrProgressUpdate.fromJson)
          .toList(growable: false),
      approvals: listValue(json['approvals'])
          .map(ManagerOkrApproval.fromJson)
          .toList(growable: false),
    );
  }
}

class ManagerOkrReport {
  const ManagerOkrReport({
    required this.totalOkrs,
    required this.statusCounts,
    required this.activeCount,
    required this.completedCount,
    required this.overdueCount,
    this.averageProgressPercent,
  });

  final int totalOkrs;
  final Map<String, int> statusCounts;
  final int activeCount;
  final int completedCount;
  final int overdueCount;
  final double? averageProgressPercent;

  factory ManagerOkrReport.fromJson(Map<String, Object?> json) {
    return ManagerOkrReport(
      totalOkrs: intValue(json['totalOkrs']),
      statusCounts: intMapValue(json['statusCounts']),
      activeCount: intValue(json['activeCount']),
      completedCount: intValue(json['completedCount']),
      overdueCount: intValue(json['overdueCount']),
      averageProgressPercent: nullableDouble(json['averageProgressPercent']),
    );
  }
}

class ManagerReviewCycle {
  const ManagerReviewCycle({
    required this.id,
    required this.name,
    required this.status,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String name;
  final String status;
  final String? startDate;
  final String? endDate;

  factory ManagerReviewCycle.fromJson(Map<String, Object?> json) {
    return ManagerReviewCycle(
      id: stringValue(json['id']),
      name: stringValue(json['name'], fallback: 'Review cycle'),
      status: stringValue(json['status'], fallback: 'ACTIVE'),
      startDate: optionalString(json['startDate']),
      endDate: optionalString(json['endDate']),
    );
  }
}

class ManagerPerformanceReview {
  const ManagerPerformanceReview({
    required this.id,
    required this.companyId,
    required this.reviewCycleId,
    required this.employeeId,
    required this.managerId,
    required this.summary,
    required this.status,
    this.rating,
    this.submittedAt,
    this.createdAt,
    this.updatedAt,
    this.reviewCycle,
    this.employee,
  });

  final String id;
  final String companyId;
  final String reviewCycleId;
  final String employeeId;
  final String managerId;
  final String summary;
  final double? rating;
  final String status;
  final String? submittedAt;
  final String? createdAt;
  final String? updatedAt;
  final ManagerReviewCycle? reviewCycle;
  final ManagerEmployeeRef? employee;

  bool get isEditable => status != 'ACKNOWLEDGED' && status != 'ARCHIVED';

  factory ManagerPerformanceReview.fromJson(Map<String, Object?> json) {
    final reviewCycle = objectOrNull(json['reviewCycle']);
    final employee = objectOrNull(json['employee']);
    return ManagerPerformanceReview(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      reviewCycleId: stringValue(json['reviewCycleId']),
      employeeId: stringValue(json['employeeId']),
      managerId: stringValue(json['managerId']),
      summary: stringValue(json['summary']),
      rating: nullableDouble(json['rating']),
      status: stringValue(json['status'], fallback: 'SUBMITTED'),
      submittedAt: optionalString(json['submittedAt']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      reviewCycle:
          reviewCycle == null ? null : ManagerReviewCycle.fromJson(reviewCycle),
      employee: employee == null ? null : ManagerEmployeeRef.fromJson(employee),
    );
  }
}

class ManagerReviewCycleCount {
  const ManagerReviewCycleCount({
    required this.reviewCycleId,
    required this.reviewCycleName,
    required this.count,
  });

  final String reviewCycleId;
  final String reviewCycleName;
  final int count;

  factory ManagerReviewCycleCount.fromJson(Map<String, Object?> json) {
    return ManagerReviewCycleCount(
      reviewCycleId: stringValue(json['reviewCycleId']),
      reviewCycleName: stringValue(
        json['reviewCycleName'],
        fallback: 'Review cycle',
      ),
      count: intValue(json['count']),
    );
  }
}

class ManagerPerformanceReport {
  const ManagerPerformanceReport({
    required this.totalReviews,
    required this.statusCounts,
    required this.pendingReviews,
    required this.submittedReviews,
    required this.finalizedReviews,
    required this.reviewsByCycle,
    this.averageRating,
  });

  final int totalReviews;
  final Map<String, int> statusCounts;
  final int pendingReviews;
  final int submittedReviews;
  final int finalizedReviews;
  final double? averageRating;
  final List<ManagerReviewCycleCount> reviewsByCycle;

  factory ManagerPerformanceReport.fromJson(Map<String, Object?> json) {
    return ManagerPerformanceReport(
      totalReviews: intValue(json['totalReviews']),
      statusCounts: intMapValue(json['statusCounts']),
      pendingReviews: intValue(json['pendingReviews']),
      submittedReviews: intValue(json['submittedReviews']),
      finalizedReviews: intValue(json['finalizedReviews']),
      averageRating: nullableDouble(json['averageRating']),
      reviewsByCycle: listValue(json['reviewsByCycle'])
          .map(ManagerReviewCycleCount.fromJson)
          .toList(growable: false),
    );
  }
}

class ManagerReportsBundle {
  const ManagerReportsBundle({
    required this.dashboard,
    required this.attendance,
    required this.leave,
    required this.okrs,
    required this.performance,
  });

  final ManagerDashboard dashboard;
  final ManagerAttendanceReport attendance;
  final ManagerLeaveReport leave;
  final ManagerOkrReport okrs;
  final ManagerPerformanceReport performance;
}

Map<String, Object?> objectValue(Object? value) {
  if (value is Map) return Map<String, Object?>.from(value);
  return const {};
}

Map<String, Object?>? objectOrNull(Object? value) {
  if (value is Map) return Map<String, Object?>.from(value);
  return null;
}

List<Map<String, Object?>> listValue(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList(growable: false);
}

Map<String, int> intMapValue(Object? value) {
  if (value is! Map) return const {};
  final result = <String, int>{};
  for (final entry in value.entries) {
    result[entry.key.toString()] = intValue(entry.value);
  }
  return result;
}

String stringValue(Object? value, {String fallback = ''}) {
  final parsed = optionalString(value);
  return parsed == null || parsed.isEmpty ? fallback : parsed;
}

String? optionalString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.trim().isEmpty ? null : text;
}

int intValue(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double doubleValue(Object? value, {double fallback = 0}) {
  return nullableDouble(value) ?? fallback;
}

double? nullableDouble(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String shortId(String value) {
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}
