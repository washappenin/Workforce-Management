import 'package:aurelia_mobile/core/auth/models.dart';
import 'package:aurelia_mobile/core/config/app_flavor.dart';
import 'package:aurelia_mobile/core/routing/router.dart';
import 'package:aurelia_mobile/features/shell/app_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('flavor config', () {
    test('maps each primary role to the correct app flavor', () {
      expect(flavorForRole(AppRole.employee), employeeFlavorConfig);
      expect(flavorForRole(AppRole.manager), managerFlavorConfig);
      expect(flavorForRole(AppRole.companyAdmin), adminFlavorConfig);
      expect(flavorForRole(AppRole.hrAdmin), adminFlavorConfig);
      expect(flavorForRole(AppRole.superAdmin), platformFlavorConfig);
    });

    test('uses unified workforce routing by default', () {
      expect(landingFor(AppRole.employee), '/employee');
      expect(landingFor(AppRole.manager), '/manager');
      expect(landingFor(AppRole.companyAdmin), '/admin');
      expect(landingFor(AppRole.superAdmin), '/super-admin');
    });

    test('redirects wrong-role users to the wrong-app screen', () {
      expect(
        landingFor(AppRole.employee, flavor: adminFlavorConfig),
        '/wrong-app',
      );
      expect(
        landingFor(AppRole.companyAdmin, flavor: employeeFlavorConfig),
        '/wrong-app',
      );
    });

    test('allows only the active flavor route family', () {
      expect(
        routeAllowedFor(AppRole.employee, '/employee/leave',
            flavor: employeeFlavorConfig),
        isTrue,
      );
      expect(
        routeAllowedFor(AppRole.employee, '/manager/leave',
            flavor: employeeFlavorConfig),
        isFalse,
      );
      expect(
        routeAllowedFor(AppRole.hrAdmin, '/admin/employees',
            flavor: adminFlavorConfig),
        isTrue,
      );
      expect(
        routeAllowedFor(AppRole.superAdmin, '/admin/employees',
            flavor: platformFlavorConfig),
        isFalse,
      );
    });

    test('keeps navigation scoped to the active flavor', () {
      final employeeLabels = destinationsForFlavor(
        employeeFlavorConfig,
        AppRole.employee,
      ).map((d) => d.label);
      expect(employeeLabels, containsAll(['Home', 'Time', 'Leave', 'OKRs']));
      expect(employeeLabels, isNot(contains('Companies')));

      final platformLabels = destinationsForFlavor(
        platformFlavorConfig,
        AppRole.superAdmin,
      ).map((d) => d.label);
      expect(platformLabels, containsAll(['Platform', 'Companies', 'Plans']));
      expect(platformLabels, isNot(contains('Leave')));
    });
  });
}
