import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(adminReportsBundleProvider);

    return AdminPage(
      title: 'Reports',
      subtitle: 'Company dashboard, attendance, leave, OKRs, and reviews.',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(adminReportsBundleProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: reports.when(
        loading: () => const LoadingState(label: 'Loading reports...'),
        error: (error, _) => adminErrorView(
          error,
          () => ref.invalidate(adminReportsBundleProvider),
        ),
        data: (bundle) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminReportsBundleProvider);
            await ref.read(adminReportsBundleProvider.future);
          },
          child: ListView(
            children: [
              _DashboardReportCard(report: bundle.dashboard),
              const SizedBox(height: 12),
              _AttendanceReportCard(report: bundle.attendance),
              const SizedBox(height: 12),
              _LeaveReportCard(report: bundle.leave),
              const SizedBox(height: 12),
              _OkrReportCard(report: bundle.okrs),
              const SizedBox(height: 12),
              _PerformanceReportCard(report: bundle.performance),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardReportCard extends StatelessWidget {
  const _DashboardReportCard({required this.report});

  final AdminDashboardReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            InfoRow(label: 'Employees', value: '${report.totalEmployees}'),
            InfoRow(label: 'Active', value: '${report.activeEmployees}'),
            InfoRow(label: 'Inactive', value: '${report.inactiveEmployees}'),
            InfoRow(label: 'Departments', value: '${report.departmentsTotal}'),
            InfoRow(label: 'Unread inbox', value: '${report.unreadCount}'),
          ],
        ),
      ),
    );
  }
}

class _AttendanceReportCard extends StatelessWidget {
  const _AttendanceReportCard({required this.report});

  final AdminAttendanceReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attendance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            InfoRow(label: 'Sessions', value: '${report.totalSessions}'),
            InfoRow(label: 'Open', value: '${report.openSessions}'),
            InfoRow(label: 'Closed', value: '${report.closedSessions}'),
            if (report.clockInsByDay.isEmpty)
              Text(
                'No daily clock-in buckets.',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              for (final day in report.clockInsByDay.take(7))
                InfoRow(label: day.date, value: '${day.count} clock-ins'),
          ],
        ),
      ),
    );
  }
}

class _LeaveReportCard extends StatelessWidget {
  const _LeaveReportCard({required this.report});

  final AdminLeaveReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Leave', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            InfoRow(label: 'Requests', value: '${report.totalRequests}'),
            InfoRow(label: 'Pending', value: '${report.pendingRequests}'),
            InfoRow(label: 'Approved', value: '${report.approvedRequests}'),
            InfoRow(label: 'Rejected', value: '${report.rejectedRequests}'),
            if (report.leaveUsageByType.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Usage by type',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              for (final item in report.leaveUsageByType.take(6))
                InfoRow(
                  label: item.leaveTypeName,
                  value:
                      '${_dayCount(item.usedDays)} of ${_dayCount(item.totalDays)} days used',
                ),
            ],
            if (report.lowRemainingLeave.isNotEmpty) ...[
              const Divider(height: 24),
              Text('Low balances',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              for (final item in report.lowRemainingLeave.take(6))
                InfoRow(
                  label: item.leaveTypeName,
                  value:
                      'Employee ${_shortId(item.employeeId)}: ${_dayCount(item.remainingDays)} days',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _OkrReportCard extends StatelessWidget {
  const _OkrReportCard({required this.report});

  final AdminOkrReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OKRs', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            InfoRow(label: 'Total', value: '${report.totalOkrs}'),
            InfoRow(label: 'Active', value: '${report.activeCount}'),
            InfoRow(label: 'Completed', value: '${report.completedCount}'),
            InfoRow(label: 'Overdue', value: '${report.overdueCount}'),
            InfoRow(
              label: 'Avg progress',
              value: report.averageProgressPercent == null
                  ? 'Not available'
                  : '${report.averageProgressPercent!.toStringAsFixed(1)}%',
            ),
            if (report.statusCounts.isNotEmpty) ...[
              const Divider(height: 24),
              for (final entry in report.statusCounts.entries)
                InfoRow(label: _titleCase(entry.key), value: '${entry.value}'),
            ],
          ],
        ),
      ),
    );
  }
}

class _PerformanceReportCard extends StatelessWidget {
  const _PerformanceReportCard({required this.report});

  final AdminPerformanceReport report;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            InfoRow(label: 'Reviews', value: '${report.totalReviews}'),
            InfoRow(label: 'Draft', value: '${report.pendingReviews}'),
            InfoRow(label: 'Submitted', value: '${report.submittedReviews}'),
            InfoRow(label: 'Finalized', value: '${report.finalizedReviews}'),
            InfoRow(
              label: 'Average',
              value: report.averageRating == null
                  ? 'Not rated'
                  : report.averageRating!.toStringAsFixed(1),
            ),
            if (report.reviewsByCycle.isNotEmpty) ...[
              const Divider(height: 24),
              Text('By review cycle',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              for (final cycle in report.reviewsByCycle.take(6))
                InfoRow(label: cycle.reviewCycleName, value: '${cycle.count}'),
            ],
          ],
        ),
      ),
    );
  }
}

String _shortId(String value) {
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}

String _dayCount(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

String _titleCase(String value) {
  final words = value
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .where((word) => word.isNotEmpty);
  return words
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
