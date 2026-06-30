import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/aurelia_theme.dart';
import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

class AdminHubScreen extends ConsumerWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(adminDashboardReportProvider);

    return AdminPage(
      title: 'Admin setup',
      subtitle: 'Company structure and employee records.',
      action: IconButton.outlined(
        tooltip: 'Refresh dashboard',
        onPressed: () => ref.invalidate(adminDashboardReportProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardReportProvider);
          await ref.read(adminDashboardReportProvider.future);
        },
        child: ListView(
          children: [
            dashboard.when(
              loading: () => const _AdminDashboardLoadingCard(),
              error: (error, _) => _AdminDashboardErrorCard(
                error: error,
                onRetry: () => ref.invalidate(adminDashboardReportProvider),
              ),
              data: (report) => _AdminDashboardCard(report: report),
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.account_tree_outlined,
              title: 'Departments',
              subtitle: 'Create teams and manage active department scope.',
              route: '/admin/departments',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.badge_outlined,
              title: 'Designations',
              subtitle: 'Maintain job titles and optional department mapping.',
              route: '/admin/designations',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.people_outline,
              title: 'Employees',
              subtitle: 'Provision staff, roles, managers, and profile status.',
              route: '/admin/employees',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.location_on_outlined,
              title: 'Geofences',
              subtitle: 'Maintain circular worksites for attendance checks.',
              route: '/admin/geofences',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.assignment_turned_in_outlined,
              title: 'Attendance',
              subtitle:
                  'Review company clock sessions and verification status.',
              route: '/admin/attendance',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.schedule_outlined,
              title: 'Shifts',
              subtitle: 'Create work schedules and assign employee coverage.',
              route: '/admin/shifts',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.beach_access_outlined,
              title: 'Leave',
              subtitle: 'Configure leave types, balances, and approvals.',
              route: '/admin/leave',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.track_changes_outlined,
              title: 'OKRs',
              subtitle: 'Assign objectives and review completion approvals.',
              route: '/admin/okrs',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.rate_review_outlined,
              title: 'Reviews',
              subtitle: 'Manage review cycles and submit performance reviews.',
              route: '/admin/reviews',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.campaign_outlined,
              title: 'Broadcasts',
              subtitle: 'Send in-app announcements to active recipients.',
              route: '/admin/notifications/broadcast',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.receipt_long_outlined,
              title: 'Billing',
              subtitle: 'View subscription status and payment history.',
              route: '/admin/subscription',
            ),
            const SizedBox(height: 12),
            const _AdminHubTile(
              icon: Icons.bar_chart_outlined,
              title: 'Reports',
              subtitle: 'Read company dashboard and workflow summaries.',
              route: '/admin/reports',
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboardCard extends StatelessWidget {
  const _AdminDashboardCard({required this.report});

  final AdminDashboardReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('admin.dashboard.summary'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company dashboard',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MiniMetric(
                  label: 'Employees',
                  value: '${report.totalEmployees}',
                ),
                _MiniMetric(
                  label: 'Departments',
                  value: '${report.departmentsTotal}',
                ),
                _MiniMetric(
                  label: 'Clock-ins',
                  value: '${report.todayClockIns}',
                ),
                _MiniMetric(
                  label: 'Pending leave',
                  value: '${report.pendingLeaveRequests}',
                ),
              ],
            ),
            const Divider(height: 24),
            InfoRow(
                label: 'Active employees', value: '${report.activeEmployees}'),
            InfoRow(label: 'Open sessions', value: '${report.openSessions}'),
            InfoRow(label: 'Active OKRs', value: '${report.activeOkrs}'),
            InfoRow(label: 'Draft reviews', value: '${report.pendingReviews}'),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboardLoadingCard extends StatelessWidget {
  const _AdminDashboardLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: LoadingState(label: 'Loading dashboard...'),
      ),
    );
  }
}

class _AdminDashboardErrorCard extends StatelessWidget {
  const _AdminDashboardErrorCard({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: adminErrorView(error, onRetry),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 132,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AureliaColors.hairline),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminHubTile extends StatelessWidget {
  const _AdminHubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        key: ValueKey('admin.hub.$route'),
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AureliaColors.royal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AureliaColors.royal),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
