import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/models.dart';
import '../../core/theme/aurelia_theme.dart';
import '../../shared/widgets/states.dart';

class _PlaceholderDashboard extends StatelessWidget {
  const _PlaceholderDashboard({required this.role, required this.message});
  final AppRole role;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(role.label, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text('Signed in',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AureliaColors.muted)),
          const SizedBox(height: 20),
          Expanded(
            child: EmptyState(
              icon: Icons.construction_outlined,
              title: 'Workflows arrive in FE2+',
              message: message,
            ),
          ),
        ],
      ),
    );
  }
}

class EmployeeHome extends StatelessWidget {
  const EmployeeHome({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderDashboard(
        role: AppRole.employee,
        message:
            'Clock in/out, attendance, shifts, leave, OKRs, and reviews land in later checkpoints.',
      );
}

class ManagerHome extends StatelessWidget {
  const ManagerHome({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderDashboard(
        role: AppRole.manager,
        message:
            'Team attendance, leave approvals, OKRs, reviews, and reports arrive in later checkpoints.',
      );
}

class AdminHome extends ConsumerWidget {
  const AdminHome({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final role = auth is AuthAuthenticated
        ? auth.user.primaryRole
        : AppRole.companyAdmin;
    return _PlaceholderDashboard(
      role: role,
      message:
          'Employees, departments, designations, geofences, shifts, leave setup, OKRs, reviews, broadcasts, billing, and reports arrive in later checkpoints.',
    );
  }
}

class SuperAdminHome extends StatelessWidget {
  const SuperAdminHome({super.key});
  @override
  Widget build(BuildContext context) => const _PlaceholderDashboard(
        role: AppRole.superAdmin,
        message:
            'Companies, plans, subscriptions, payment records, platform reports, and company rollups arrive in later checkpoints.',
      );
}

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth is! AuthAuthenticated) return const SizedBox.shrink();
    final u = auth.user;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Account', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _row('Email', u.email),
                  const Divider(height: 24),
                  _row('Role', u.primaryRole.label),
                  const Divider(height: 24),
                  _row('Status', u.status),
                  if (u.companyId != null) ...[
                    const Divider(height: 24),
                    _row('Company ID', u.companyId!),
                  ],
                ],
              ),
            ),
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(k, style: const TextStyle(color: AureliaColors.muted)),
          ),
          Expanded(
              child:
                  Text(v, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      );
}

class NotificationsPlaceholder extends StatelessWidget {
  const NotificationsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(20),
      child: EmptyState(
        icon: Icons.notifications_none,
        title: 'Inbox',
        message: 'Full notifications inbox arrives in FE2.',
      ),
    );
  }
}
