class EmployeeProfile {
  const EmployeeProfile({
    required this.id,
    required this.companyId,
    required this.email,
    required this.roles,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.phone,
    this.hireDate,
    this.departmentId,
    this.designationId,
    this.managerId,
  });

  final String id;
  final String companyId;
  final String email;
  final List<String> roles;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String status;
  final String? phone;
  final String? hireDate;
  final String? departmentId;
  final String? designationId;
  final String? managerId;

  String get fullName {
    final name = [firstName, lastName]
        .where((value) => value.trim().isNotEmpty)
        .join(' ');
    return name.isEmpty ? email : name;
  }

  factory EmployeeProfile.fromJson(Map<String, Object?> json) {
    final rolesRaw = json['roles'];
    return EmployeeProfile(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      email: stringValue(json['email']),
      roles: rolesRaw is List
          ? rolesRaw.map((role) => role.toString()).toList(growable: false)
          : const [],
      employeeCode: stringValue(json['employeeCode'], fallback: 'Unassigned'),
      firstName: stringValue(json['firstName']),
      lastName: stringValue(json['lastName']),
      status: stringValue(json['status'], fallback: 'UNKNOWN'),
      phone: optionalString(json['phone']),
      hireDate: optionalString(json['hireDate']),
      departmentId: optionalString(json['departmentId']),
      designationId: optionalString(json['designationId']),
      managerId: optionalString(json['managerId']),
    );
  }
}

class EmployeeDashboard {
  const EmployeeDashboard({
    required this.attendance,
    required this.shift,
    required this.leave,
    required this.okrs,
    required this.performance,
    required this.notifications,
  });

  final EmployeeAttendanceSummary attendance;
  final DashboardShiftSummary shift;
  final DashboardLeaveSummary leave;
  final DashboardOkrSummary okrs;
  final DashboardPerformanceSummary performance;
  final DashboardNotificationsSummary notifications;

  factory EmployeeDashboard.fromJson(Map<String, Object?> json) {
    return EmployeeDashboard(
      attendance:
          EmployeeAttendanceSummary.fromJson(objectValue(json['attendance'])),
      shift: DashboardShiftSummary.fromJson(objectValue(json['shift'])),
      leave: DashboardLeaveSummary.fromJson(objectValue(json['leave'])),
      okrs: DashboardOkrSummary.fromJson(objectValue(json['okrs'])),
      performance: DashboardPerformanceSummary.fromJson(
          objectValue(json['performance'])),
      notifications: DashboardNotificationsSummary.fromJson(
        objectValue(json['notifications']),
      ),
    );
  }
}

class EmployeeAttendanceSummary {
  const EmployeeAttendanceSummary({
    required this.todayStatus,
    this.openSession,
  });

  final String todayStatus;
  final DashboardAttendanceSession? openSession;

  factory EmployeeAttendanceSummary.fromJson(Map<String, Object?> json) {
    final session = objectOrNull(json['openSession']);
    return EmployeeAttendanceSummary(
      todayStatus: stringValue(json['todayStatus'], fallback: 'NOT_CLOCKED_IN'),
      openSession:
          session == null ? null : DashboardAttendanceSession.fromJson(session),
    );
  }
}

class DashboardAttendanceSession {
  const DashboardAttendanceSession({
    required this.id,
    required this.clockInAt,
    required this.status,
  });

  final String id;
  final String clockInAt;
  final String status;

  factory DashboardAttendanceSession.fromJson(Map<String, Object?> json) {
    return DashboardAttendanceSession(
      id: stringValue(json['id']),
      clockInAt: stringValue(json['clockInAt']),
      status: stringValue(json['status'], fallback: 'OPEN'),
    );
  }
}

class DashboardShiftSummary {
  const DashboardShiftSummary({required this.currentAssignments});

  final List<DashboardShiftAssignment> currentAssignments;

  factory DashboardShiftSummary.fromJson(Map<String, Object?> json) {
    return DashboardShiftSummary(
      currentAssignments: listValue(json['currentAssignments'])
          .map(DashboardShiftAssignment.fromJson)
          .toList(growable: false),
    );
  }
}

class DashboardShiftAssignment {
  const DashboardShiftAssignment({
    required this.assignmentId,
    required this.shiftId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.startsOn,
    this.endsOn,
  });

  final String assignmentId;
  final String shiftId;
  final String name;
  final String startTime;
  final String endTime;
  final String startsOn;
  final String? endsOn;

  factory DashboardShiftAssignment.fromJson(Map<String, Object?> json) {
    return DashboardShiftAssignment(
      assignmentId: stringValue(json['assignmentId']),
      shiftId: stringValue(json['shiftId']),
      name: stringValue(json['name'], fallback: 'Shift'),
      startTime: stringValue(json['startTime']),
      endTime: stringValue(json['endTime']),
      startsOn: stringValue(json['startsOn']),
      endsOn: optionalString(json['endsOn']),
    );
  }
}

class DashboardLeaveSummary {
  const DashboardLeaveSummary({
    required this.pendingRequestsCount,
    required this.balances,
  });

  final int pendingRequestsCount;
  final List<LeaveBalance> balances;

  factory DashboardLeaveSummary.fromJson(Map<String, Object?> json) {
    return DashboardLeaveSummary(
      pendingRequestsCount: intValue(json['pendingRequestsCount']),
      balances: listValue(json['balances'])
          .map(LeaveBalance.fromJson)
          .toList(growable: false),
    );
  }
}

class LeaveBalance {
  const LeaveBalance({
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.remainingDays,
  });

  final String leaveTypeId;
  final String leaveTypeName;
  final int year;
  final double totalDays;
  final double usedDays;
  final double remainingDays;

  factory LeaveBalance.fromJson(Map<String, Object?> json) {
    return LeaveBalance(
      leaveTypeId: stringValue(json['leaveTypeId']),
      leaveTypeName: stringValue(json['leaveTypeName'], fallback: 'Leave'),
      year: intValue(json['year']),
      totalDays: doubleValue(json['totalDays']),
      usedDays: doubleValue(json['usedDays']),
      remainingDays: doubleValue(json['remainingDays']),
    );
  }
}

class DashboardOkrSummary {
  const DashboardOkrSummary({required this.activeCount});

  final int activeCount;

  factory DashboardOkrSummary.fromJson(Map<String, Object?> json) {
    return DashboardOkrSummary(activeCount: intValue(json['activeCount']));
  }
}

class DashboardPerformanceSummary {
  const DashboardPerformanceSummary({this.latestReview});

  final LatestReviewSummary? latestReview;

  factory DashboardPerformanceSummary.fromJson(Map<String, Object?> json) {
    final review = objectOrNull(json['latestReview']);
    return DashboardPerformanceSummary(
      latestReview:
          review == null ? null : LatestReviewSummary.fromJson(review),
    );
  }
}

class LatestReviewSummary {
  const LatestReviewSummary({
    required this.id,
    required this.reviewCycleId,
    required this.status,
    this.rating,
    this.submittedAt,
    this.createdAt,
  });

  final String id;
  final String reviewCycleId;
  final String status;
  final double? rating;
  final String? submittedAt;
  final String? createdAt;

  factory LatestReviewSummary.fromJson(Map<String, Object?> json) {
    return LatestReviewSummary(
      id: stringValue(json['id']),
      reviewCycleId: stringValue(json['reviewCycleId']),
      status: stringValue(json['status'], fallback: 'DRAFT'),
      rating: nullableDouble(json['rating']),
      submittedAt: optionalString(json['submittedAt']),
      createdAt: optionalString(json['createdAt']),
    );
  }
}

class DashboardNotificationsSummary {
  const DashboardNotificationsSummary({required this.unreadCount});

  final int unreadCount;

  factory DashboardNotificationsSummary.fromJson(Map<String, Object?> json) {
    return DashboardNotificationsSummary(
      unreadCount: intValue(json['unreadCount']),
    );
  }
}

class AttendanceSession {
  const AttendanceSession({
    required this.id,
    required this.status,
    required this.clockInAt,
    this.clockOutAt,
    this.clockInFaceVerified,
    this.clockOutFaceVerified,
  });

  final String id;
  final String status;
  final String clockInAt;
  final String? clockOutAt;
  final bool? clockInFaceVerified;
  final bool? clockOutFaceVerified;

  factory AttendanceSession.fromJson(Map<String, Object?> json) {
    return AttendanceSession(
      id: stringValue(json['id']),
      status: stringValue(json['status'], fallback: 'UNKNOWN'),
      clockInAt: stringValue(json['clockInAt']),
      clockOutAt: optionalString(json['clockOutAt']),
      clockInFaceVerified: boolOrNull(json['clockInFaceVerified']),
      clockOutFaceVerified: boolOrNull(json['clockOutFaceVerified']),
    );
  }
}

class ShiftInfo {
  const ShiftInfo({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  final String id;
  final String name;
  final String startTime;
  final String endTime;
  final String status;

  factory ShiftInfo.fromJson(Map<String, Object?> json) {
    return ShiftInfo(
      id: stringValue(json['id']),
      name: stringValue(json['name'], fallback: 'Shift'),
      startTime: stringValue(json['startTime']),
      endTime: stringValue(json['endTime']),
      status: stringValue(json['status'], fallback: 'ACTIVE'),
    );
  }
}

class ShiftAssignment {
  const ShiftAssignment({
    required this.id,
    required this.shiftId,
    required this.startsOn,
    this.endsOn,
    this.shift,
  });

  final String id;
  final String shiftId;
  final String startsOn;
  final String? endsOn;
  final ShiftInfo? shift;

  String get name => shift?.name ?? 'Shift';
  String get timeRange {
    final start = shift?.startTime ?? '';
    final end = shift?.endTime ?? '';
    if (start.isEmpty && end.isEmpty) return 'Time not set';
    return '$start - $end';
  }

  factory ShiftAssignment.fromJson(Map<String, Object?> json) {
    final shift = objectOrNull(json['shift']);
    return ShiftAssignment(
      id: stringValue(json['id']),
      shiftId: stringValue(json['shiftId']),
      startsOn: stringValue(json['startsOn']),
      endsOn: optionalString(json['endsOn']),
      shift: shift == null ? null : ShiftInfo.fromJson(shift),
    );
  }
}

class LeaveTypeSummary {
  const LeaveTypeSummary({
    required this.id,
    required this.name,
    required this.status,
    this.defaultAnnualAllowance,
  });

  final String id;
  final String name;
  final String status;
  final double? defaultAnnualAllowance;

  factory LeaveTypeSummary.fromJson(Map<String, Object?> json) {
    return LeaveTypeSummary(
      id: stringValue(json['id']),
      name: stringValue(json['name'], fallback: 'Leave'),
      status: stringValue(json['status'], fallback: 'ACTIVE'),
      defaultAnnualAllowance: nullableDouble(json['defaultAnnualAllowance']),
    );
  }
}

class LeaveEntitlement {
  const LeaveEntitlement({
    required this.id,
    required this.leaveTypeId,
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.remainingDays,
    this.leaveType,
  });

  final String id;
  final String leaveTypeId;
  final int year;
  final double totalDays;
  final double usedDays;
  final double remainingDays;
  final LeaveTypeSummary? leaveType;

  String get name => leaveType?.name ?? 'Leave';

  factory LeaveEntitlement.fromJson(Map<String, Object?> json) {
    final leaveType = objectOrNull(json['leaveType']);
    return LeaveEntitlement(
      id: stringValue(json['id']),
      leaveTypeId: stringValue(json['leaveTypeId']),
      year: intValue(json['year']),
      totalDays: doubleValue(json['totalDays']),
      usedDays: doubleValue(json['usedDays']),
      remainingDays: doubleValue(json['remainingDays']),
      leaveType:
          leaveType == null ? null : LeaveTypeSummary.fromJson(leaveType),
    );
  }
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.requestedDays,
    required this.status,
    this.reason,
    this.reviewedAt,
    this.reviewComment,
    this.createdAt,
    this.leaveType,
  });

  final String id;
  final String leaveTypeId;
  final String startDate;
  final String endDate;
  final double requestedDays;
  final String status;
  final String? reason;
  final String? reviewedAt;
  final String? reviewComment;
  final String? createdAt;
  final LeaveTypeSummary? leaveType;

  String get name => leaveType?.name ?? 'Leave';

  factory LeaveRequest.fromJson(Map<String, Object?> json) {
    final leaveType = objectOrNull(json['leaveType']);
    return LeaveRequest(
      id: stringValue(json['id']),
      leaveTypeId: stringValue(json['leaveTypeId']),
      startDate: stringValue(json['startDate']),
      endDate: stringValue(json['endDate']),
      requestedDays: doubleValue(json['requestedDays']),
      status: stringValue(json['status'], fallback: 'PENDING'),
      reason: optionalString(json['reason']),
      reviewedAt: optionalString(json['reviewedAt']),
      reviewComment: optionalString(json['reviewComment']),
      createdAt: optionalString(json['createdAt']),
      leaveType:
          leaveType == null ? null : LeaveTypeSummary.fromJson(leaveType),
    );
  }
}

class LeaveSummary {
  const LeaveSummary({
    required this.entitlements,
    required this.leaveRequests,
  });

  final List<LeaveEntitlement> entitlements;
  final List<LeaveRequest> leaveRequests;

  factory LeaveSummary.fromJson(Map<String, Object?> json) {
    return LeaveSummary(
      entitlements: listValue(json['entitlements'])
          .map(LeaveEntitlement.fromJson)
          .toList(growable: false),
      leaveRequests: listValue(json['leaveRequests'])
          .map(LeaveRequest.fromJson)
          .toList(growable: false),
    );
  }
}

class OkrProgressUpdate {
  const OkrProgressUpdate({
    required this.id,
    required this.progressPercent,
    this.note,
    this.createdAt,
  });

  final String id;
  final int progressPercent;
  final String? note;
  final String? createdAt;

  factory OkrProgressUpdate.fromJson(Map<String, Object?> json) {
    return OkrProgressUpdate(
      id: stringValue(json['id']),
      progressPercent: intValue(json['progressPercent']),
      note: optionalString(json['note']),
      createdAt: optionalString(json['createdAt']),
    );
  }
}

class OkrApproval {
  const OkrApproval({
    required this.id,
    required this.approverEmployeeId,
    required this.status,
    this.comment,
    this.createdAt,
  });

  final String id;
  final String approverEmployeeId;
  final String status;
  final String? comment;
  final String? createdAt;

  factory OkrApproval.fromJson(Map<String, Object?> json) {
    return OkrApproval(
      id: stringValue(json['id']),
      approverEmployeeId: stringValue(json['approverEmployeeId']),
      status: stringValue(json['status'], fallback: 'PENDING'),
      comment: optionalString(json['comment']),
      createdAt: optionalString(json['createdAt']),
    );
  }
}

class OkrItem {
  const OkrItem({
    required this.id,
    required this.employeeId,
    required this.title,
    required this.status,
    required this.progressUpdates,
    required this.approvals,
    this.description,
    this.dueDate,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String employeeId;
  final String title;
  final String? description;
  final String status;
  final String? dueDate;
  final String? createdAt;
  final String? updatedAt;
  final List<OkrProgressUpdate> progressUpdates;
  final List<OkrApproval> approvals;

  int get progressPercent =>
      progressUpdates.isEmpty ? 0 : progressUpdates.first.progressPercent;

  bool get employeeApproved => approvals.any(
        (approval) =>
            approval.approverEmployeeId == employeeId &&
            approval.status == 'APPROVED',
      );

  factory OkrItem.fromJson(Map<String, Object?> json) {
    return OkrItem(
      id: stringValue(json['id']),
      employeeId: stringValue(json['employeeId']),
      title: stringValue(json['title'], fallback: 'Objective'),
      description: optionalString(json['description']),
      status: stringValue(json['status'], fallback: 'ASSIGNED'),
      dueDate: optionalString(json['dueDate']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      progressUpdates: listValue(json['progressUpdates'])
          .map(OkrProgressUpdate.fromJson)
          .toList(growable: false),
      approvals: listValue(json['approvals'])
          .map(OkrApproval.fromJson)
          .toList(growable: false),
    );
  }
}

class ReviewCycleSummary {
  const ReviewCycleSummary({
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

  factory ReviewCycleSummary.fromJson(Map<String, Object?> json) {
    return ReviewCycleSummary(
      id: stringValue(json['id']),
      name: stringValue(json['name'], fallback: 'Review cycle'),
      status: stringValue(json['status'], fallback: 'ACTIVE'),
      startDate: optionalString(json['startDate']),
      endDate: optionalString(json['endDate']),
    );
  }
}

class PerformanceReviewItem {
  const PerformanceReviewItem({
    required this.id,
    required this.reviewCycleId,
    required this.status,
    this.summary,
    this.rating,
    this.submittedAt,
    this.createdAt,
    this.reviewCycle,
  });

  final String id;
  final String reviewCycleId;
  final String? summary;
  final double? rating;
  final String status;
  final String? submittedAt;
  final String? createdAt;
  final ReviewCycleSummary? reviewCycle;

  String get title => reviewCycle?.name ?? 'Performance review';

  factory PerformanceReviewItem.fromJson(Map<String, Object?> json) {
    final cycle = objectOrNull(json['reviewCycle']);
    return PerformanceReviewItem(
      id: stringValue(json['id']),
      reviewCycleId: stringValue(json['reviewCycleId']),
      summary: optionalString(json['summary']),
      rating: nullableDouble(json['rating']),
      status: stringValue(json['status'], fallback: 'DRAFT'),
      submittedAt: optionalString(json['submittedAt']),
      createdAt: optionalString(json['createdAt']),
      reviewCycle: cycle == null ? null : ReviewCycleSummary.fromJson(cycle),
    );
  }
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

bool? boolOrNull(Object? value) {
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return null;
}
