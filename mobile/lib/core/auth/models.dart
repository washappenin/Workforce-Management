enum AppRole {
  superAdmin,
  companyAdmin,
  hrAdmin,
  manager,
  employee,
  unknown;

  static AppRole fromApi(String value) {
    switch (value) {
      case 'SUPER_ADMIN':
        return AppRole.superAdmin;
      case 'COMPANY_ADMIN':
        return AppRole.companyAdmin;
      case 'HR_ADMIN':
        return AppRole.hrAdmin;
      case 'MANAGER':
        return AppRole.manager;
      case 'EMPLOYEE':
        return AppRole.employee;
      default:
        return AppRole.unknown;
    }
  }

  String get label => switch (this) {
        AppRole.superAdmin => 'Super Admin',
        AppRole.companyAdmin => 'Company Admin',
        AppRole.hrAdmin => 'HR Admin',
        AppRole.manager => 'Manager',
        AppRole.employee => 'Employee',
        AppRole.unknown => 'User',
      };
}

class AuthUser {
  AuthUser({
    required this.id,
    required this.email,
    required this.companyId,
    required this.roles,
    required this.status,
  });

  final String id;
  final String email;
  final String? companyId;
  final List<AppRole> roles;
  final String status;

  AppRole get primaryRole {
    // Priority order matches the web app.
    const order = [
      AppRole.superAdmin,
      AppRole.companyAdmin,
      AppRole.hrAdmin,
      AppRole.manager,
      AppRole.employee,
    ];
    for (final r in order) {
      if (roles.contains(r)) return r;
    }
    return AppRole.unknown;
  }

  factory AuthUser.fromJson(Map<String, Object?> json) {
    final rolesRaw = (json['roles'] as List?) ?? const [];
    return AuthUser(
      id: json['id'] as String,
      email: json['email'] as String,
      companyId: json['companyId'] as String?,
      roles: rolesRaw.map((e) => AppRole.fromApi(e as String)).toList(),
      status: (json['status'] as String?) ?? 'ACTIVE',
    );
  }
}
