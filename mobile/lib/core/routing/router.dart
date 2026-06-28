import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_hub_screen.dart';
import '../../features/admin/admin_attendance_screen.dart';
import '../../features/admin/departments_screen.dart';
import '../../features/admin/designations_screen.dart';
import '../../features/admin/employees_screen.dart';
import '../../features/admin/face_enrollment_screen.dart';
import '../../features/admin/geofences_screen.dart';
import '../../features/admin/shifts_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/employee/attendance_clock_screen.dart';
import '../../features/employee/attendance_history_screen.dart';
import '../../features/employee/employee_dashboard_screen.dart';
import '../../features/employee/leave_screen.dart';
import '../../features/employee/okrs_screen.dart';
import '../../features/employee/reviews_screen.dart';
import '../../features/employee/shifts_screen.dart';
import '../../features/notifications/notifications_screen.dart';
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
            builder: (_, __) => const EmployeeDashboardScreen(),
            routes: [
              GoRoute(
                path: 'dashboard',
                builder: (_, __) => const EmployeeDashboardScreen(),
              ),
              GoRoute(
                path: 'attendance/history',
                builder: (_, __) => const AttendanceHistoryScreen(),
              ),
              GoRoute(
                path: 'attendance/clock-in',
                builder: (_, __) => const ClockInScreen(),
              ),
              GoRoute(
                path: 'attendance/clock-out',
                builder: (_, __) => const ClockOutScreen(),
              ),
              GoRoute(
                path: 'face-verification',
                builder: (_, __) => const FaceVerificationScreen(),
              ),
              GoRoute(
                path: 'shifts',
                builder: (_, __) => const ShiftsScreen(),
              ),
              GoRoute(
                path: 'leave',
                builder: (_, __) => const LeaveScreen(),
              ),
              GoRoute(
                path: 'okrs',
                builder: (_, __) => const OkrsScreen(),
              ),
              GoRoute(
                path: 'reviews',
                builder: (_, __) => const ReviewsScreen(),
              ),
              GoRoute(
                path: 'notifications',
                builder: (_, __) => const NotificationsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/manager',
            builder: (_, __) => const ManagerHome(),
            routes: [
              GoRoute(
                path: 'notifications',
                builder: (_, __) => const NotificationsScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/admin',
            builder: (_, __) => const AdminHubScreen(),
            routes: [
              GoRoute(
                path: 'departments',
                builder: (_, __) => const DepartmentsScreen(),
              ),
              GoRoute(
                path: 'departments/:departmentId',
                builder: (_, state) => DepartmentDetailScreen(
                  departmentId: state.pathParameters['departmentId']!,
                ),
              ),
              GoRoute(
                path: 'designations',
                builder: (_, __) => const DesignationsScreen(),
              ),
              GoRoute(
                path: 'designations/:designationId',
                builder: (_, state) => DesignationDetailScreen(
                  designationId: state.pathParameters['designationId']!,
                ),
              ),
              GoRoute(
                path: 'employees',
                builder: (_, __) => const EmployeesScreen(),
              ),
              GoRoute(
                path: 'employees/:employeeId',
                builder: (_, state) => EmployeeDetailScreen(
                  employeeId: state.pathParameters['employeeId']!,
                ),
              ),
              GoRoute(
                path: 'employees/:employeeId/face',
                builder: (_, state) => FaceEnrollmentScreen(
                  employeeId: state.pathParameters['employeeId']!,
                ),
              ),
              GoRoute(
                path: 'geofences',
                builder: (_, __) => const GeofencesScreen(),
              ),
              GoRoute(
                path: 'geofences/:geofenceId',
                builder: (_, state) => GeofenceDetailScreen(
                  geofenceId: state.pathParameters['geofenceId']!,
                ),
              ),
              GoRoute(
                path: 'attendance',
                builder: (_, __) => const AdminAttendanceScreen(),
              ),
              GoRoute(
                path: 'shifts',
                builder: (_, __) => const AdminShiftsScreen(),
              ),
              GoRoute(
                path: 'shifts/:shiftId',
                builder: (_, state) => AdminShiftDetailScreen(
                  shiftId: state.pathParameters['shiftId']!,
                ),
              ),
            ],
          ),
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
