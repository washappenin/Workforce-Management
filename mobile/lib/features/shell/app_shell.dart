import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/models.dart';
import '../../core/config/app_flavor.dart';
import '../../core/theme/aurelia_theme.dart';
import '../notifications/notifications_controller.dart';

class NavDestinationSpec {
  const NavDestinationSpec({
    required this.label,
    required this.icon,
    required this.route,
  });
  final String label;
  final IconData icon;
  final String route;
}

List<NavDestinationSpec> destinationsFor(AppRole role) {
  switch (role) {
    case AppRole.employee:
      return const [
        NavDestinationSpec(
            label: 'Home', icon: Icons.dashboard_outlined, route: '/employee'),
        NavDestinationSpec(
            label: 'Time',
            icon: Icons.history_outlined,
            route: '/employee/attendance/history'),
        NavDestinationSpec(
            label: 'Leave',
            icon: Icons.beach_access_outlined,
            route: '/employee/leave'),
        NavDestinationSpec(
            label: 'OKRs',
            icon: Icons.track_changes_outlined,
            route: '/employee/okrs'),
        NavDestinationSpec(
            label: 'Account', icon: Icons.person_outline, route: '/account'),
      ];
    case AppRole.manager:
      return const [
        NavDestinationSpec(
            label: 'Team', icon: Icons.groups_outlined, route: '/manager'),
        NavDestinationSpec(
            label: 'Leave',
            icon: Icons.beach_access_outlined,
            route: '/manager/leave'),
        NavDestinationSpec(
            label: 'OKRs',
            icon: Icons.track_changes_outlined,
            route: '/manager/okrs'),
        NavDestinationSpec(
            label: 'Reviews',
            icon: Icons.rate_review_outlined,
            route: '/manager/reviews'),
        NavDestinationSpec(
            label: 'Reports',
            icon: Icons.bar_chart_outlined,
            route: '/manager/reports'),
      ];
    case AppRole.companyAdmin:
    case AppRole.hrAdmin:
      return const [
        NavDestinationSpec(
            label: 'Admin', icon: Icons.dashboard_outlined, route: '/admin'),
        NavDestinationSpec(
            label: 'People',
            icon: Icons.people_outline,
            route: '/admin/employees'),
        NavDestinationSpec(
            label: 'Geo',
            icon: Icons.location_on_outlined,
            route: '/admin/geofences'),
        NavDestinationSpec(
            label: 'Time',
            icon: Icons.assignment_turned_in_outlined,
            route: '/admin/attendance'),
        NavDestinationSpec(
            label: 'Account', icon: Icons.person_outline, route: '/account'),
      ];
    case AppRole.superAdmin:
      return const [
        NavDestinationSpec(
            label: 'Platform',
            icon: Icons.business_outlined,
            route: '/super-admin'),
        NavDestinationSpec(
            label: 'Companies',
            icon: Icons.apartment_outlined,
            route: '/super-admin/companies'),
        NavDestinationSpec(
            label: 'Plans',
            icon: Icons.workspace_premium_outlined,
            route: '/super-admin/plans'),
        NavDestinationSpec(
            label: 'Billing',
            icon: Icons.fact_check_outlined,
            route: '/super-admin/subscriptions'),
        NavDestinationSpec(
            label: 'Reports',
            icon: Icons.bar_chart_outlined,
            route: '/super-admin/reports'),
      ];
    case AppRole.unknown:
      return const [
        NavDestinationSpec(
            label: 'Account', icon: Icons.person_outline, route: '/account'),
      ];
  }
}

List<NavDestinationSpec> destinationsForFlavor(
  FlavorConfig flavor,
  AppRole role,
) {
  if (!flavor.isRoleRestricted) return destinationsFor(role);
  switch (flavor.flavor) {
    case AureliaFlavor.employee:
      return destinationsFor(AppRole.employee);
    case AureliaFlavor.manager:
      return destinationsFor(AppRole.manager);
    case AureliaFlavor.admin:
      return destinationsFor(AppRole.companyAdmin);
    case AureliaFlavor.platform:
      return destinationsFor(AppRole.superAdmin);
    case AureliaFlavor.workforce:
      return destinationsFor(role);
  }
}

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthAuthenticated) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final user = auth.user;
    final flavor = ref.watch(flavorConfigProvider);
    final destinations = destinationsForFlavor(flavor, user.primaryRole);
    final unreadAsync = ref.watch(unreadCountProvider);

    final location = GoRouterState.of(context).uri.path;
    var index = 0;
    var longestMatch = -1;
    for (var i = 0; i < destinations.length; i += 1) {
      final route = destinations[i].route;
      final matches = location == route || location.startsWith('$route/');
      if (matches && route.length > longestMatch) {
        index = i;
        longestMatch = route.length;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(flavor.appName),
        actions: [
          unreadAsync.maybeWhen(
            data: (count) {
              if (count == null || count <= 0) return const SizedBox.shrink();
              final inboxRoute = user.primaryRole == AppRole.manager
                  ? '/manager/notifications'
                  : '/employee/notifications';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  tooltip: '$count unread',
                  onPressed: () => context.go(inboxRoute),
                  icon: Badge(
                    label: Text('$count'),
                    backgroundColor: AureliaColors.royal,
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(destinations[i].route),
        destinations: [
          for (final d in destinations)
            NavigationDestination(icon: Icon(d.icon), label: d.label),
        ],
      ),
    );
  }
}
