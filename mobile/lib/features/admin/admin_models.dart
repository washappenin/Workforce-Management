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

Map<String, Object?>? _object(Object? value) {
  if (value is Map) return Map<String, Object?>.from(value);
  return null;
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
