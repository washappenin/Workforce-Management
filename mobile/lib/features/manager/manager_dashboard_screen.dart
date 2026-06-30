import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/states.dart';
import 'manager_repository.dart';
import 'widgets/manager_widgets.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(managerDashboardProvider);

    return ManagerPage(
      title: 'Team',
      subtitle: 'Direct-report operations',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(managerDashboardProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: dashboard.when(
        loading: () => const LoadingState(label: 'Loading team dashboard...'),
        error: (error, _) => managerErrorView(
          error,
          () => ref.invalidate(managerDashboardProvider),
        ),
        data: (summary) {
          if (summary.totalEmployees == 0) {
            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(managerDashboardProvider),
              child: const ManagerEmptyList(
                icon: Icons.groups_outlined,
                title: 'No direct-report summary yet',
                message:
                    'Team metrics will appear once active employees report to you.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(managerDashboardProvider);
              await ref.read(managerDashboardProvider.future);
            },
            child: ListView(
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team command',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${summary.activeEmployees} active of ${summary.totalEmployees} direct reports',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Divider(height: 28),
                      InfoLine(
                        label: 'Today',
                        value: '${summary.todayClockIns} clock-ins',
                      ),
                      InfoLine(
                        label: 'Open',
                        value: '${summary.openSessions} sessions',
                      ),
                      InfoLine(
                        label: 'Inbox',
                        value: '${summary.unreadCount} unread',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    MetricTile(
                      label: 'Direct reports',
                      value: '${summary.totalEmployees}',
                      icon: Icons.groups_outlined,
                    ),
                    MetricTile(
                      label: 'Pending leave',
                      value: '${summary.pendingLeaveRequests}',
                      icon: Icons.beach_access_outlined,
                    ),
                    MetricTile(
                      label: 'Active OKRs',
                      value: '${summary.activeOkrs}',
                      icon: Icons.track_changes_outlined,
                    ),
                    MetricTile(
                      label: 'Draft reviews',
                      value: '${summary.pendingReviews}',
                      icon: Icons.rate_review_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manager workflows',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      ManagerActionRow(
                        key: const ValueKey('manager.hub./manager/attendance'),
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Team attendance',
                        subtitle: 'Daily direct-report attendance summary',
                        onTap: () => context.go('/manager/attendance'),
                      ),
                      ManagerActionRow(
                        key: const ValueKey('manager.hub./manager/leave'),
                        icon: Icons.beach_access_outlined,
                        title: 'Leave approvals',
                        subtitle: 'Approve or reject pending requests',
                        onTap: () => context.go('/manager/leave'),
                      ),
                      ManagerActionRow(
                        key: const ValueKey('manager.hub./manager/okrs'),
                        icon: Icons.track_changes_outlined,
                        title: 'Team OKRs',
                        subtitle: 'Assign objectives and approve completion',
                        onTap: () => context.go('/manager/okrs'),
                      ),
                      ManagerActionRow(
                        key: const ValueKey('manager.hub./manager/reviews'),
                        icon: Icons.rate_review_outlined,
                        title: 'Performance reviews',
                        subtitle: 'Submit and maintain direct-report reviews',
                        onTap: () => context.go('/manager/reviews'),
                      ),
                      ManagerActionRow(
                        key: const ValueKey('manager.hub./manager/reports'),
                        icon: Icons.bar_chart_outlined,
                        title: 'Team reports',
                        subtitle:
                            'Read attendance, leave, OKR, and review summaries',
                        onTap: () => context.go('/manager/reports'),
                      ),
                      ManagerActionRow(
                        key: const ValueKey(
                          'manager.hub./manager/notifications',
                        ),
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        subtitle: 'Read your workflow inbox',
                        onTap: () => context.go('/manager/notifications'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
