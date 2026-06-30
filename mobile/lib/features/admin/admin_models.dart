class AdminDepartment {
  const AdminDepartment({
    required this.id,
    required this.companyId,
    required this.name,
    required this.isActive,
  });

  final String id;
  final String companyId;
  final String name;
  final bool isActive;

  factory AdminDepartment.fromJson(Map<String, Object?> json) {
    return AdminDepartment(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      name: json['name'] as String,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }
}

class AdminDesignation {
  const AdminDesignation({
    required this.id,
    required this.companyId,
    required this.title,
    required this.isActive,
    this.departmentId,
  });

  final String id;
  final String companyId;
  final String title;
  final String? departmentId;
  final bool isActive;

  factory AdminDesignation.fromJson(Map<String, Object?> json) {
    return AdminDesignation(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      title: json['title'] as String,
      departmentId: json['departmentId'] as String?,
      isActive: (json['isActive'] as bool?) ?? true,
    );
  }
}

class AdminNamedRef {
  const AdminNamedRef({required this.id, required this.name});

  final String id;
  final String name;

  factory AdminNamedRef.fromJson(Map<String, Object?> json) {
    return AdminNamedRef(
      id: json['id'] as String,
      name: (json['name'] as String?) ??
          (json['title'] as String?) ??
          'Unassigned',
    );
  }
}

class AdminEmployeeRef {
  const AdminEmployeeRef({
    required this.id,
    required this.name,
    this.email,
    this.employeeCode,
  });

  final String id;
  final String name;
  final String? email;
  final String? employeeCode;

  factory AdminEmployeeRef.fromJson(Map<String, Object?> json) {
    final first = json['firstName'] as String?;
    final last = json['lastName'] as String?;
    final email = json['email'] as String?;
    final name = [first, last]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join(' ');
    return AdminEmployeeRef(
      id: json['id'] as String,
      name: name.isEmpty ? email ?? 'Employee' : name,
      email: email,
      employeeCode: json['employeeCode'] as String?,
    );
  }
}

class AdminEmployee {
  const AdminEmployee({
    required this.id,
    required this.companyId,
    required this.email,
    required this.roles,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.userId,
    this.userStatus,
    this.departmentId,
    this.designationId,
    this.managerId,
    this.phone,
    this.hireDate,
    this.department,
    this.designation,
    this.manager,
  });

  final String id;
  final String companyId;
  final String? userId;
  final String email;
  final List<String> roles;
  final String? userStatus;
  final String? departmentId;
  final String? designationId;
  final String? managerId;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String? phone;
  final String status;
  final String? hireDate;
  final AdminNamedRef? department;
  final AdminNamedRef? designation;
  final AdminEmployeeRef? manager;

  String get fullName {
    final name = [firstName, lastName]
        .where((value) => value.trim().isNotEmpty)
        .join(' ');
    return name.isEmpty ? email : name;
  }

  String get primaryRole => roles.isEmpty ? 'EMPLOYEE' : roles.first;

  factory AdminEmployee.fromJson(Map<String, Object?> json) {
    final rolesRaw = (json['roles'] as List?) ?? const [];
    return AdminEmployee(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      userId: json['userId'] as String?,
      email: json['email'] as String,
      roles: rolesRaw.map((role) => role.toString()).toList(),
      userStatus: json['userStatus'] as String?,
      departmentId: json['departmentId'] as String?,
      designationId: json['designationId'] as String?,
      managerId: json['managerId'] as String?,
      employeeCode: json['employeeCode'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      status: json['status'] as String,
      hireDate: json['hireDate']?.toString(),
      department: _object(json['department']) == null
          ? null
          : AdminNamedRef.fromJson(_object(json['department'])!),
      designation: _object(json['designation']) == null
          ? null
          : AdminNamedRef.fromJson(_object(json['designation'])!),
      manager: _object(json['manager']) == null
          ? null
          : AdminEmployeeRef.fromJson(_object(json['manager'])!),
    );
  }
}

class FaceEnrollment {
  const FaceEnrollment({
    required this.status,
    this.id,
    this.employeeId,
    this.companyId,
    this.provider,
    this.enrolledAt,
  });

  final String? id;
  final String? employeeId;
  final String? companyId;
  final String? provider;
  final String status;
  final String? enrolledAt;

  bool get exists => id != null && status != 'NOT_ENROLLED';

  factory FaceEnrollment.fromJson(Map<String, Object?> json) {
    return FaceEnrollment(
      id: json['id'] as String?,
      employeeId: json['employeeId'] as String?,
      companyId: json['companyId'] as String?,
      provider: json['provider'] as String?,
      status: (json['status'] as String?) ?? 'NOT_ENROLLED',
      enrolledAt: json['enrolledAt']?.toString(),
    );
  }
}

class AdminGeofence {
  const AdminGeofence({
    required this.id,
    required this.companyId,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  bool get isActive => status == 'ACTIVE';

  factory AdminGeofence.fromJson(Map<String, Object?> json) {
    return AdminGeofence(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      name: stringValue(json['name'], fallback: 'Geofence'),
      latitude: doubleValue(json['latitude']),
      longitude: doubleValue(json['longitude']),
      radiusMeters: intValue(json['radiusMeters']),
      status: stringValue(json['status'], fallback: 'INACTIVE'),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
    );
  }
}

class AdminAttendanceSession {
  const AdminAttendanceSession({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.status,
    required this.clockInAt,
    this.clockOutAt,
    this.clockInGeofenceId,
    this.clockOutGeofenceId,
    this.clockInFaceVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final String status;
  final String clockInAt;
  final String? clockOutAt;
  final String? clockInGeofenceId;
  final String? clockOutGeofenceId;
  final bool clockInFaceVerified;
  final String? createdAt;
  final String? updatedAt;

  bool get isOpen => status == 'OPEN';

  factory AdminAttendanceSession.fromJson(Map<String, Object?> json) {
    return AdminAttendanceSession(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      employeeId: stringValue(json['employeeId']),
      status: stringValue(json['status'], fallback: 'UNKNOWN'),
      clockInAt: stringValue(json['clockInAt']),
      clockOutAt: optionalString(json['clockOutAt']),
      clockInGeofenceId: optionalString(json['clockInGeofenceId']),
      clockOutGeofenceId: optionalString(json['clockOutGeofenceId']),
      clockInFaceVerified: boolValue(json['clockInFaceVerified']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
    );
  }
}

class AdminShift {
  const AdminShift({
    required this.id,
    required this.companyId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String name;
  final String startTime;
  final String endTime;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  bool get isActive => status == 'ACTIVE';

  factory AdminShift.fromJson(Map<String, Object?> json) {
    return AdminShift(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      name: stringValue(json['name'], fallback: 'Shift'),
      startTime: stringValue(json['startTime']),
      endTime: stringValue(json['endTime']),
      status: stringValue(json['status'], fallback: 'INACTIVE'),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
    );
  }
}

class AdminShiftAssignment {
  const AdminShiftAssignment({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.shiftId,
    required this.startsOn,
    this.endsOn,
    this.createdAt,
    this.updatedAt,
    this.shift,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final String shiftId;
  final String startsOn;
  final String? endsOn;
  final String? createdAt;
  final String? updatedAt;
  final AdminShift? shift;

  factory AdminShiftAssignment.fromJson(Map<String, Object?> json) {
    return AdminShiftAssignment(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      employeeId: stringValue(json['employeeId']),
      shiftId: stringValue(json['shiftId']),
      startsOn: stringValue(json['startsOn']),
      endsOn: optionalString(json['endsOn']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      shift: _object(json['shift']) == null
          ? null
          : AdminShift.fromJson(_object(json['shift'])!),
    );
  }
}

class AdminLeaveType {
  const AdminLeaveType({
    required this.id,
    required this.companyId,
    required this.name,
    required this.status,
    this.defaultAnnualAllowance,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String name;
  final String status;
  final double? defaultAnnualAllowance;
  final String? createdAt;
  final String? updatedAt;

  bool get isActive => status == 'ACTIVE';

  factory AdminLeaveType.fromJson(Map<String, Object?> json) {
    return AdminLeaveType(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      name: stringValue(json['name'], fallback: 'Leave type'),
      status: stringValue(json['status'], fallback: 'INACTIVE'),
      defaultAnnualAllowance: nullableDouble(json['defaultAnnualAllowance']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
    );
  }
}

class AdminLeaveEntitlement {
  const AdminLeaveEntitlement({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.leaveTypeId,
    required this.year,
    required this.totalDays,
    required this.usedDays,
    required this.remainingDays,
    this.createdAt,
    this.updatedAt,
    this.leaveType,
  });

  final String id;
  final String companyId;
  final String employeeId;
  final String leaveTypeId;
  final int year;
  final double totalDays;
  final double usedDays;
  final double remainingDays;
  final String? createdAt;
  final String? updatedAt;
  final AdminLeaveType? leaveType;

  String get leaveTypeName => leaveType?.name ?? 'Leave';

  factory AdminLeaveEntitlement.fromJson(Map<String, Object?> json) {
    return AdminLeaveEntitlement(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      employeeId: stringValue(json['employeeId']),
      leaveTypeId: stringValue(json['leaveTypeId']),
      year: intValue(json['year']),
      totalDays: doubleValue(json['totalDays']),
      usedDays: doubleValue(json['usedDays']),
      remainingDays: doubleValue(json['remainingDays']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      leaveType: _object(json['leaveType']) == null
          ? null
          : AdminLeaveType.fromJson(_object(json['leaveType'])!),
    );
  }
}

class AdminLeaveRequest {
  const AdminLeaveRequest({
    required this.id,
    required this.companyId,
    required this.employeeId,
    required this.leaveTypeId,
    required this.startDate,
    required this.endDate,
    required this.requestedDays,
    required this.status,
    this.reason,
    this.reviewedById,
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
  final String? reviewedById;
  final String? reviewedAt;
  final String? reviewComment;
  final String? createdAt;
  final String? updatedAt;
  final AdminLeaveType? leaveType;

  bool get isPending => status == 'PENDING';
  String get leaveTypeName => leaveType?.name ?? 'Leave';

  factory AdminLeaveRequest.fromJson(Map<String, Object?> json) {
    return AdminLeaveRequest(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      employeeId: stringValue(json['employeeId']),
      leaveTypeId: stringValue(json['leaveTypeId']),
      startDate: stringValue(json['startDate']),
      endDate: stringValue(json['endDate']),
      requestedDays: doubleValue(json['requestedDays']),
      status: stringValue(json['status'], fallback: 'PENDING'),
      reason: optionalString(json['reason']),
      reviewedById: optionalString(json['reviewedById']),
      reviewedAt: optionalString(json['reviewedAt']),
      reviewComment: optionalString(json['reviewComment']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      leaveType: _object(json['leaveType']) == null
          ? null
          : AdminLeaveType.fromJson(_object(json['leaveType'])!),
    );
  }
}

class AdminOkrEmployeeRef {
  const AdminOkrEmployeeRef({
    required this.id,
    required this.companyId,
    required this.status,
    this.managerId,
  });

  final String id;
  final String companyId;
  final String? managerId;
  final String status;

  factory AdminOkrEmployeeRef.fromJson(Map<String, Object?> json) {
    return AdminOkrEmployeeRef(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      managerId: optionalString(json['managerId']),
      status: stringValue(json['status'], fallback: 'UNKNOWN'),
    );
  }
}

class AdminOkrProgressUpdate {
  const AdminOkrProgressUpdate({
    required this.id,
    required this.companyId,
    required this.okrId,
    required this.employeeId,
    required this.progressPercent,
    this.note,
    this.createdAt,
  });

  final String id;
  final String companyId;
  final String okrId;
  final String employeeId;
  final int progressPercent;
  final String? note;
  final String? createdAt;

  factory AdminOkrProgressUpdate.fromJson(Map<String, Object?> json) {
    return AdminOkrProgressUpdate(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      okrId: stringValue(json['okrId']),
      employeeId: stringValue(json['employeeId']),
      progressPercent: intValue(json['progressPercent']),
      note: optionalString(json['note']),
      createdAt: optionalString(json['createdAt']),
    );
  }
}

class AdminOkrApproval {
  const AdminOkrApproval({
    required this.id,
    required this.companyId,
    required this.okrId,
    required this.approverEmployeeId,
    required this.status,
    this.comment,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String okrId;
  final String approverEmployeeId;
  final String status;
  final String? comment;
  final String? createdAt;
  final String? updatedAt;

  factory AdminOkrApproval.fromJson(Map<String, Object?> json) {
    return AdminOkrApproval(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      okrId: stringValue(json['okrId']),
      approverEmployeeId: stringValue(json['approverEmployeeId']),
      status: stringValue(json['status'], fallback: 'PENDING'),
      comment: optionalString(json['comment']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
    );
  }
}

class AdminOkr {
  const AdminOkr({
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
    this.assignedBy,
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
  final AdminOkrEmployeeRef? employee;
  final AdminOkrEmployeeRef? assignedBy;
  final List<AdminOkrProgressUpdate> progressUpdates;
  final List<AdminOkrApproval> approvals;

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

  factory AdminOkr.fromJson(Map<String, Object?> json) {
    final employee = _object(json['employee']);
    final assignedBy = _object(json['assignedBy']);
    return AdminOkr(
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
      employee:
          employee == null ? null : AdminOkrEmployeeRef.fromJson(employee),
      assignedBy:
          assignedBy == null ? null : AdminOkrEmployeeRef.fromJson(assignedBy),
      progressUpdates: listValue(json['progressUpdates'])
          .map(AdminOkrProgressUpdate.fromJson)
          .toList(growable: false),
      approvals: listValue(json['approvals'])
          .map(AdminOkrApproval.fromJson)
          .toList(growable: false),
    );
  }
}

class AdminReviewCycle {
  const AdminReviewCycle({
    required this.id,
    required this.companyId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String companyId;
  final String name;
  final String startDate;
  final String endDate;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  bool get isActive => status == 'ACTIVE';

  factory AdminReviewCycle.fromJson(Map<String, Object?> json) {
    return AdminReviewCycle(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      name: stringValue(json['name'], fallback: 'Review cycle'),
      startDate: stringValue(json['startDate']),
      endDate: stringValue(json['endDate']),
      status: stringValue(json['status'], fallback: 'DRAFT'),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
    );
  }
}

class AdminReviewEmployeeRef {
  const AdminReviewEmployeeRef({
    required this.id,
    required this.companyId,
    required this.status,
    this.managerId,
  });

  final String id;
  final String companyId;
  final String? managerId;
  final String status;

  factory AdminReviewEmployeeRef.fromJson(Map<String, Object?> json) {
    return AdminReviewEmployeeRef(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      managerId: optionalString(json['managerId']),
      status: stringValue(json['status'], fallback: 'UNKNOWN'),
    );
  }
}

class AdminPerformanceReview {
  const AdminPerformanceReview({
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
    this.manager,
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
  final AdminReviewCycle? reviewCycle;
  final AdminReviewEmployeeRef? employee;
  final AdminReviewEmployeeRef? manager;

  String get title => reviewCycle?.name ?? 'Performance review';
  bool get isEditable => status != 'ACKNOWLEDGED' && status != 'ARCHIVED';

  factory AdminPerformanceReview.fromJson(Map<String, Object?> json) {
    final reviewCycle = _object(json['reviewCycle']);
    final employee = _object(json['employee']);
    final manager = _object(json['manager']);
    return AdminPerformanceReview(
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
          reviewCycle == null ? null : AdminReviewCycle.fromJson(reviewCycle),
      employee:
          employee == null ? null : AdminReviewEmployeeRef.fromJson(employee),
      manager:
          manager == null ? null : AdminReviewEmployeeRef.fromJson(manager),
    );
  }
}

class AdminNotificationRecipient {
  const AdminNotificationRecipient({
    required this.employeeId,
    required this.userId,
    required this.roles,
  });

  final String employeeId;
  final String userId;
  final List<String> roles;

  factory AdminNotificationRecipient.fromJson(Map<String, Object?> json) {
    return AdminNotificationRecipient(
      employeeId: stringValue(json['employeeId']),
      userId: stringValue(json['userId']),
      roles: (json['roles'] as List? ?? const [])
          .map((role) => role.toString())
          .toList(growable: false),
    );
  }
}

class AdminNotificationBroadcastResult {
  const AdminNotificationBroadcastResult({
    required this.companyId,
    required this.type,
    required this.notificationCount,
    required this.recipients,
    this.targetRole,
  });

  final String companyId;
  final String type;
  final String? targetRole;
  final int notificationCount;
  final List<AdminNotificationRecipient> recipients;

  int get recipientCount => recipients.length;

  factory AdminNotificationBroadcastResult.fromJson(
    Map<String, Object?> json,
  ) {
    return AdminNotificationBroadcastResult(
      companyId: stringValue(json['companyId']),
      type: stringValue(json['type'], fallback: 'SYSTEM'),
      targetRole: optionalString(json['targetRole']),
      notificationCount: intValue(json['notificationCount']),
      recipients: listValue(json['recipients'])
          .map(AdminNotificationRecipient.fromJson)
          .toList(growable: false),
    );
  }
}

class AdminSubscriptionPlan {
  const AdminSubscriptionPlan({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerEmployee,
    required this.currency,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String type;
  final double pricePerEmployee;
  final String currency;
  final bool isActive;
  final String? createdAt;
  final String? updatedAt;

  factory AdminSubscriptionPlan.fromJson(Map<String, Object?> json) {
    return AdminSubscriptionPlan(
      id: stringValue(json['id']),
      name: stringValue(json['name'], fallback: 'Plan'),
      type: stringValue(json['type'], fallback: 'BASIC'),
      pricePerEmployee: doubleValue(json['pricePerEmployee']),
      currency: stringValue(json['currency'], fallback: 'USD'),
      isActive: boolValue(json['isActive'], fallback: true),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
    );
  }
}

class AdminCompanySubscription {
  const AdminCompanySubscription({
    required this.id,
    required this.companyId,
    required this.planId,
    required this.status,
    required this.startsAt,
    this.endsAt,
    this.createdAt,
    this.updatedAt,
    this.plan,
  });

  final String id;
  final String companyId;
  final String planId;
  final String status;
  final String startsAt;
  final String? endsAt;
  final String? createdAt;
  final String? updatedAt;
  final AdminSubscriptionPlan? plan;

  bool get isCurrent => status == 'ACTIVE' || status == 'TRIALING';

  factory AdminCompanySubscription.fromJson(Map<String, Object?> json) {
    final plan = _object(json['plan']);
    return AdminCompanySubscription(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      planId: stringValue(json['planId']),
      status: stringValue(json['status'], fallback: 'EXPIRED'),
      startsAt: stringValue(json['startsAt']),
      endsAt: optionalString(json['endsAt']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      plan: plan == null ? null : AdminSubscriptionPlan.fromJson(plan),
    );
  }
}

class AdminPaymentRecord {
  const AdminPaymentRecord({
    required this.id,
    required this.companyId,
    required this.amount,
    required this.currency,
    required this.status,
    this.subscriptionId,
    this.provider,
    this.paidAt,
    this.createdAt,
    this.updatedAt,
    this.subscription,
  });

  final String id;
  final String companyId;
  final String? subscriptionId;
  final double amount;
  final String currency;
  final String status;
  final String? provider;
  final String? paidAt;
  final String? createdAt;
  final String? updatedAt;
  final AdminCompanySubscription? subscription;

  factory AdminPaymentRecord.fromJson(Map<String, Object?> json) {
    final subscription = _object(json['subscription']);
    return AdminPaymentRecord(
      id: stringValue(json['id']),
      companyId: stringValue(json['companyId']),
      subscriptionId: optionalString(json['subscriptionId']),
      amount: doubleValue(json['amount']),
      currency: stringValue(json['currency'], fallback: 'USD'),
      status: stringValue(json['status'], fallback: 'PENDING'),
      provider: optionalString(json['provider']),
      paidAt: optionalString(json['paidAt']),
      createdAt: optionalString(json['createdAt']),
      updatedAt: optionalString(json['updatedAt']),
      subscription: subscription == null
          ? null
          : AdminCompanySubscription.fromJson(subscription),
    );
  }
}

class AdminDashboardReport {
  const AdminDashboardReport({
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

  factory AdminDashboardReport.fromJson(Map<String, Object?> json) {
    final employees = objectValue(json['employees']);
    final departments = objectValue(json['departments']);
    final attendance = objectValue(json['attendance']);
    final leave = objectValue(json['leave']);
    final okrs = objectValue(json['okrs']);
    final performance = objectValue(json['performance']);
    final notifications = objectValue(json['notifications']);

    return AdminDashboardReport(
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

class AdminClockInsByDay {
  const AdminClockInsByDay({required this.date, required this.count});

  final String date;
  final int count;

  factory AdminClockInsByDay.fromJson(Map<String, Object?> json) {
    return AdminClockInsByDay(
      date: stringValue(json['date']),
      count: intValue(json['count']),
    );
  }
}

class AdminAttendanceReport {
  const AdminAttendanceReport({
    required this.totalSessions,
    required this.openSessions,
    required this.closedSessions,
    required this.clockInsByDay,
  });

  final int totalSessions;
  final int openSessions;
  final int closedSessions;
  final List<AdminClockInsByDay> clockInsByDay;

  factory AdminAttendanceReport.fromJson(Map<String, Object?> json) {
    return AdminAttendanceReport(
      totalSessions: intValue(json['totalSessions']),
      openSessions: intValue(json['openSessions']),
      closedSessions: intValue(json['closedSessions']),
      clockInsByDay: listValue(json['clockInsByDay'])
          .map(AdminClockInsByDay.fromJson)
          .toList(growable: false),
    );
  }
}

class AdminLeaveUsageByType {
  const AdminLeaveUsageByType({
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.usedDays,
    required this.totalDays,
  });

  final String leaveTypeId;
  final String leaveTypeName;
  final double usedDays;
  final double totalDays;

  factory AdminLeaveUsageByType.fromJson(Map<String, Object?> json) {
    return AdminLeaveUsageByType(
      leaveTypeId: stringValue(json['leaveTypeId']),
      leaveTypeName: stringValue(json['leaveTypeName'], fallback: 'Leave'),
      usedDays: doubleValue(json['usedDays']),
      totalDays: doubleValue(json['totalDays']),
    );
  }
}

class AdminLowRemainingLeave {
  const AdminLowRemainingLeave({
    required this.employeeId,
    required this.leaveTypeId,
    required this.leaveTypeName,
    required this.remainingDays,
  });

  final String employeeId;
  final String leaveTypeId;
  final String leaveTypeName;
  final double remainingDays;

  factory AdminLowRemainingLeave.fromJson(Map<String, Object?> json) {
    return AdminLowRemainingLeave(
      employeeId: stringValue(json['employeeId']),
      leaveTypeId: stringValue(json['leaveTypeId']),
      leaveTypeName: stringValue(json['leaveTypeName'], fallback: 'Leave'),
      remainingDays: doubleValue(json['remainingDays']),
    );
  }
}

class AdminLeaveReport {
  const AdminLeaveReport({
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
  final List<AdminLeaveUsageByType> leaveUsageByType;
  final List<AdminLowRemainingLeave> lowRemainingLeave;

  factory AdminLeaveReport.fromJson(Map<String, Object?> json) {
    return AdminLeaveReport(
      totalRequests: intValue(json['totalRequests']),
      pendingRequests: intValue(json['pendingRequests']),
      approvedRequests: intValue(json['approvedRequests']),
      rejectedRequests: intValue(json['rejectedRequests']),
      leaveUsageByType: listValue(json['leaveUsageByType'])
          .map(AdminLeaveUsageByType.fromJson)
          .toList(growable: false),
      lowRemainingLeave: listValue(json['lowRemainingLeave'])
          .map(AdminLowRemainingLeave.fromJson)
          .toList(growable: false),
    );
  }
}

class AdminOkrReport {
  const AdminOkrReport({
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

  factory AdminOkrReport.fromJson(Map<String, Object?> json) {
    return AdminOkrReport(
      totalOkrs: intValue(json['totalOkrs']),
      statusCounts: intMapValue(json['statusCounts']),
      activeCount: intValue(json['activeCount']),
      completedCount: intValue(json['completedCount']),
      overdueCount: intValue(json['overdueCount']),
      averageProgressPercent: nullableDouble(json['averageProgressPercent']),
    );
  }
}

class AdminReviewCycleCount {
  const AdminReviewCycleCount({
    required this.reviewCycleId,
    required this.reviewCycleName,
    required this.count,
  });

  final String reviewCycleId;
  final String reviewCycleName;
  final int count;

  factory AdminReviewCycleCount.fromJson(Map<String, Object?> json) {
    return AdminReviewCycleCount(
      reviewCycleId: stringValue(json['reviewCycleId']),
      reviewCycleName: stringValue(
        json['reviewCycleName'],
        fallback: 'Review cycle',
      ),
      count: intValue(json['count']),
    );
  }
}

class AdminPerformanceReport {
  const AdminPerformanceReport({
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
  final List<AdminReviewCycleCount> reviewsByCycle;

  factory AdminPerformanceReport.fromJson(Map<String, Object?> json) {
    return AdminPerformanceReport(
      totalReviews: intValue(json['totalReviews']),
      statusCounts: intMapValue(json['statusCounts']),
      pendingReviews: intValue(json['pendingReviews']),
      submittedReviews: intValue(json['submittedReviews']),
      finalizedReviews: intValue(json['finalizedReviews']),
      averageRating: nullableDouble(json['averageRating']),
      reviewsByCycle: listValue(json['reviewsByCycle'])
          .map(AdminReviewCycleCount.fromJson)
          .toList(growable: false),
    );
  }
}

class AdminReportsBundle {
  const AdminReportsBundle({
    required this.dashboard,
    required this.attendance,
    required this.leave,
    required this.okrs,
    required this.performance,
  });

  final AdminDashboardReport dashboard;
  final AdminAttendanceReport attendance;
  final AdminLeaveReport leave;
  final AdminOkrReport okrs;
  final AdminPerformanceReport performance;
}

Map<String, Object?>? _object(Object? value) {
  if (value is Map) return Map<String, Object?>.from(value);
  return null;
}

Map<String, Object?> objectValue(Object? value) {
  if (value is Map) return Map<String, Object?>.from(value);
  return const {};
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

bool boolValue(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is String) {
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
  }
  return fallback;
}

String roleLabel(String role) {
  return switch (role) {
    'COMPANY_ADMIN' => 'Company Admin',
    'HR_ADMIN' => 'HR Admin',
    'MANAGER' => 'Manager',
    'EMPLOYEE' => 'Employee',
    _ => role,
  };
}
