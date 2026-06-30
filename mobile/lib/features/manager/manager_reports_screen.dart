import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'manager_models.dart';
import 'manager_repository.dart';
import 'widgets/manager_widgets.dart';

class ManagerReportsScreen extends ConsumerWidget {
  const ManagerReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(managerReportsBundleProvider);

    return ManagerPage(
      title: 'Reports',
      subtitle: 'Direct-report summaries',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(managerReportsBundleProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: reports.when(
        loading: () => const LoadingState(label: 'Loading team reports...'),
        error: (error, _) => managerErrorView(
          error,
          () => ref.invalidate(managerReportsBundleProvider),
        ),
        data: (bundle) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(managerReportsBundleProvider);
            await ref.read(managerReportsBundleProvider.future);
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

  final ManagerDashboard report;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          InfoLine(label: 'Direct reports', value: '${report.totalEmployees}'),
          InfoLine(label: 'Active', value: '${report.activeEmployees}'),
          InfoLine(label: 'Departments', value: '${report.departmentsTotal}'),
          InfoLine(label: 'Unread inbox', value: '${report.unreadCount}'),
        ],
      ),
    );
  }
}

class _AttendanceReportCard extends StatelessWidget {
  const _AttendanceReportCard({required this.report});

  final ManagerAttendanceReport report;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          InfoLine(label: 'Sessions', value: '${report.totalSessions}'),
          InfoLine(label: 'Open', value: '${report.openSessions}'),
          InfoLine(label: 'Closed', value: '${report.closedSessions}'),
          if (report.clockInsByDay.isEmpty)
            Text(
              'No daily clock-in buckets.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (final day in report.clockInsByDay.take(5))
              InfoLine(label: day.date, value: '${day.count} clock-ins'),
        ],
      ),
    );
  }
}

class _LeaveReportCard extends StatelessWidget {
  const _LeaveReportCard({required this.report});

  final ManagerLeaveReport report;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Leave', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          InfoLine(label: 'Requests', value: '${report.totalRequests}'),
          InfoLine(label: 'Pending', value: '${report.pendingRequests}'),
          InfoLine(label: 'Approved', value: '${report.approvedRequests}'),
          InfoLine(label: 'Rejected', value: '${report.rejectedRequests}'),
          if (report.lowRemainingLeave.isNotEmpty) ...[
            const Divider(height: 24),
            Text('Low balances',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            for (final item in report.lowRemainingLeave.take(5))
              InfoLine(
                label: item.leaveTypeName,
                value:
                    'Employee ${shortId(item.employeeId)}: ${dayCount(item.remainingDays)} days',
              ),
          ],
        ],
      ),
    );
  }
}

class _OkrReportCard extends StatelessWidget {
  const _OkrReportCard({required this.report});

  final ManagerOkrReport report;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('OKRs', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          InfoLine(label: 'Total', value: '${report.totalOkrs}'),
          InfoLine(label: 'Active', value: '${report.activeCount}'),
          InfoLine(label: 'Completed', value: '${report.completedCount}'),
          InfoLine(label: 'Overdue', value: '${report.overdueCount}'),
          InfoLine(
            label: 'Avg progress',
            value: report.averageProgressPercent == null
                ? 'Not available'
                : '${report.averageProgressPercent!.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }
}

class _PerformanceReportCard extends StatelessWidget {
  const _PerformanceReportCard({required this.report});

  final ManagerPerformanceReport report;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          InfoLine(label: 'Reviews', value: '${report.totalReviews}'),
          InfoLine(label: 'Draft', value: '${report.pendingReviews}'),
          InfoLine(label: 'Submitted', value: '${report.submittedReviews}'),
          InfoLine(label: 'Finalized', value: '${report.finalizedReviews}'),
          InfoLine(
            label: 'Average',
            value: report.averageRating == null
                ? 'Not rated'
                : report.averageRating!.toStringAsFixed(1),
          ),
          if (report.reviewsByCycle.isNotEmpty) ...[
            const Divider(height: 24),
            for (final cycle in report.reviewsByCycle.take(5))
              InfoLine(label: cycle.reviewCycleName, value: '${cycle.count}'),
          ],
        ],
      ),
    );
  }
}
