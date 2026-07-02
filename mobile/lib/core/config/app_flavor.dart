import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/models.dart';

enum AureliaFlavor {
  workforce,
  employee,
  manager,
  admin,
  platform,
}

class FlavorConfig {
  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.loginSubtitle,
    required this.allowedRoles,
    required this.initialAuthedRoute,
  });

  final AureliaFlavor flavor;
  final String appName;
  final String loginSubtitle;
  final Set<AppRole> allowedRoles;
  final String initialAuthedRoute;

  bool get isRoleRestricted => flavor != AureliaFlavor.workforce;

  bool allowsRole(AppRole role) =>
      !isRoleRestricted || allowedRoles.contains(role);
}

const workforceFlavorConfig = FlavorConfig(
  flavor: AureliaFlavor.workforce,
  appName: 'Aurelia',
  loginSubtitle: 'Workforce management',
  allowedRoles: {
    AppRole.superAdmin,
    AppRole.companyAdmin,
    AppRole.hrAdmin,
    AppRole.manager,
    AppRole.employee,
  },
  initialAuthedRoute: '/',
);

const employeeFlavorConfig = FlavorConfig(
  flavor: AureliaFlavor.employee,
  appName: 'Aurelia Employee',
  loginSubtitle: 'Employee self-service',
  allowedRoles: {AppRole.employee},
  initialAuthedRoute: '/employee',
);

const managerFlavorConfig = FlavorConfig(
  flavor: AureliaFlavor.manager,
  appName: 'Aurelia Manager',
  loginSubtitle: 'Team management',
  allowedRoles: {AppRole.manager},
  initialAuthedRoute: '/manager',
);

const adminFlavorConfig = FlavorConfig(
  flavor: AureliaFlavor.admin,
  appName: 'Aurelia Admin',
  loginSubtitle: 'Company operations',
  allowedRoles: {AppRole.companyAdmin, AppRole.hrAdmin},
  initialAuthedRoute: '/admin',
);

const platformFlavorConfig = FlavorConfig(
  flavor: AureliaFlavor.platform,
  appName: 'Aurelia Platform',
  loginSubtitle: 'Platform administration',
  allowedRoles: {AppRole.superAdmin},
  initialAuthedRoute: '/super-admin',
);

final flavorConfigProvider = Provider<FlavorConfig>(
  (_) => workforceFlavorConfig,
);

FlavorConfig flavorForRole(AppRole role) {
  switch (role) {
    case AppRole.superAdmin:
      return platformFlavorConfig;
    case AppRole.companyAdmin:
    case AppRole.hrAdmin:
      return adminFlavorConfig;
    case AppRole.manager:
      return managerFlavorConfig;
    case AppRole.employee:
      return employeeFlavorConfig;
    case AppRole.unknown:
      return workforceFlavorConfig;
  }
}
