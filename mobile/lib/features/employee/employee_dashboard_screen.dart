import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/states.dart';
import 'employee_models.dart';
import 'employee_repository.dart';
import 'widgets/employee_widgets.dart';

class EmployeeDashboardScreen extends ConsumerWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(employeeProfileProvider);
    final dashboard = ref.watch(employeeDashboardProvider);

    return EmployeePage(
      title: 'Dashboard',
      subtitle: 'Employee self-service',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () {
          ref.invalidate(employeeProfileProvider);
          ref.invalidate(employeeDashboardProvider);
        },
        icon: const Icon(Icons.refresh),
      ),
      child: _dashboardBody(context, ref, profile, dashboard),
    );
  }

  Widget _dashboardBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<EmployeeProfile> profile,
    AsyncValue<EmployeeDashboard> dashboard,
  ) {
    if (profile.isLoading || dashboard.isLoading) {
      return const LoadingState(label: 'Loading dashboard...');
    }
    if (profile.hasError) {
      return employeeErrorView(
        profile.error!,
        () => ref.invalidate(employeeProfileProvider),
      );
    }
    if (dashboard.hasError) {
      return employeeErrorView(
        dashboard.error!,
        () => ref.invalidate(employeeDashboardProvider),
      );
    }

    final employee = profile.value!;
    final summary = dashboard.value!;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(employeeProfileProvider);
        ref.invalidate(employeeDashboardProvider);
        await Future.wait([
          ref.read(employeeProfileProvider.future),
          ref.read(employeeDashboardProvider.future),
        ]);
      },
      child: ListView(
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good day, ${employee.firstName.isEmpty ? 'colleague' : employee.firstName}.',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${employee.employeeCode} - ${employee.email}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    StatusChip(label: employee.status),
                  ],
                ),
                const Divider(height: 28),
                InfoLine(
                  label: 'Today',
                  value: titleCase(summary.attendance.todayStatus),
                ),
                if (summary.attendance.openSession != null)
                  InfoLine(
                    label: 'Clock in',
                    value: shortDateTime(
                      summary.attendance.openSession!.clockInAt,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              MetricTile(
                label: 'Current shifts',
                value: '${summary.shift.currentAssignments.length}',
                icon: Icons.calendar_month_outlined,
              ),
              MetricTile(
                label: 'Pending leave',
                value: '${summary.leave.pendingRequestsCount}',
                icon: Icons.beach_access_outlined,
              ),
              MetricTile(
                label: 'Active OKRs',
                value: '${summary.okrs.activeCount}',
                icon: Icons.track_changes_outlined,
              ),
              MetricTile(
                label: 'Unread inbox',
                value: '${summary.notifications.unreadCount}',
                icon: Icons.notifications_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Self-service',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const _ActionRow(
                  icon: Icons.history_outlined,
                  title: 'Attendance history',
                  subtitle: 'View prior clock sessions',
                  route: '/employee/attendance/history',
                ),
                const _ActionRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'My shifts',
                  subtitle: 'Current and upcoming assignments',
                  route: '/employee/shifts',
                ),
                const _ActionRow(
                  icon: Icons.beach_access_outlined,
                  title: 'Leave',
                  subtitle: 'Balances, requests, and new leave submission',
                  route: '/employee/leave',
                ),
                const _ActionRow(
                  icon: Icons.track_changes_outlined,
                  title: 'OKRs',
                  subtitle: 'Update progress and approve your objectives',
                  route: '/employee/okrs',
                ),
                const _ActionRow(
                  icon: Icons.rate_review_outlined,
                  title: 'Reviews',
                  subtitle: 'View manager-submitted performance reviews',
                  route: '/employee/reviews',
                ),
                const _ActionRow(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Read and clear your inbox',
                  route: '/employee/notifications',
                ),
              ],
            ),
          ),
          if (summary.leave.balances.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Leave balances',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  for (final balance in summary.leave.balances) ...[
                    InfoLine(
                      label: balance.leaveTypeName,
                      value:
                          '${dayCount(balance.remainingDays)} of ${dayCount(balance.totalDays)} days remaining',
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (summary.performance.latestReview != null) ...[
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest review',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  InfoLine(
                    label: 'Status',
                    value: titleCase(summary.performance.latestReview!.status),
                  ),
                  InfoLine(
                    label: 'Rating',
                    value: summary.performance.latestReview!.rating == null
                        ? 'Not rated'
                        : summary.performance.latestReview!.rating!
                            .toStringAsFixed(1),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmployeeFe3GateScreen extends StatelessWidget {
  const EmployeeFe3GateScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return EmployeePage(
      title: title,
      subtitle: 'Face and GPS gated attendance',
      child: const EmptyState(
        icon: Icons.face_retouching_natural_outlined,
        title: 'Enabled in FE3',
        message:
            'Clock-in and clock-out require the face verification and GPS checkpoint. Attendance history is available now.',
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
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
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.go(route),
    );
  }
}
