import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/placeholders/role_dashboards.dart';
import '../../features/shell/app_shell.dart';
import '../../shared/widgets/states.dart';
import '../auth/auth_controller.dart';
import '../auth/models.dart';

String landingFor(AppRole role) {
  switch (role) {
    case AppRole.superAdmin:
      return '/super-admin';
    case AppRole.companyAdmin:
    case AppRole.hrAdmin:
      return '/admin';
    case AppRole.manager:
      return '/manager';
    case AppRole.employee:
      return '/employee';
    case AppRole.unknown:
      return '/account';
  }
}

bool _roleAllowed(AppRole role, String path) {
  if (path.startsWith('/account')) return true;
  if (path.startsWith('/super-admin')) return role == AppRole.superAdmin;
  if (path.startsWith('/admin')) {
    return role == AppRole.companyAdmin || role == AppRole.hrAdmin;
  }
  if (path.startsWith('/manager')) return role == AppRole.manager;
  if (path.startsWith('/employee')) return role == AppRole.employee;
  return true;
}

/// Re-evaluate router redirects whenever auth state changes.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen<AuthState>(authControllerProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.uri.path;
      final atLogin = loc == '/login';

      if (auth is AuthInitial || auth is AuthLoading) {
        return null;
      }
      if (auth is AuthUnauthenticated) {
        return atLogin ? null : '/login';
      }
      if (auth is AuthAuthenticated) {
        if (atLogin || loc == '/') {
          return landingFor(auth.user.primaryRole);
        }
        if (!_roleAllowed(auth.user.primaryRole, loc)) {
          return '/denied';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const _Splash()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/denied',
        builder: (_, __) => const Scaffold(body: AccessDeniedState()),
      ),
      ShellRoute(
        builder: (_, __, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/employee',
            builder: (_, __) => const EmployeeHome(),
            routes: [
              GoRoute(
                path: 'notifications',
                builder: (_, __) => const NotificationsPlaceholder(),
              ),
            ],
          ),
          GoRoute(
            path: '/manager',
            builder: (_, __) => const ManagerHome(),
            routes: [
              GoRoute(
                path: 'notifications',
                builder: (_, __) => const NotificationsPlaceholder(),
              ),
            ],
          ),
          GoRoute(path: '/admin', builder: (_, __) => const AdminHome()),
          GoRoute(
            path: '/super-admin',
            builder: (_, __) => const SuperAdminHome(),
          ),
          GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
        ],
      ),
    ],
    errorBuilder: (_, __) => const Scaffold(body: NotFoundState()),
  );
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: LoadingState(label: 'Loading...'));
}
