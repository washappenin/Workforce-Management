import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'manager_models.dart';
import 'manager_repository.dart';
import 'widgets/manager_widgets.dart';

class ManagerLeaveScreen extends ConsumerWidget {
  const ManagerLeaveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(managerLeaveRequestsProvider);
    final report = ref.watch(managerLeaveReportProvider);

    return ManagerPage(
      title: 'Leave',
      subtitle: 'Direct-report requests',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () {
          ref.invalidate(managerLeaveRequestsProvider);
          ref.invalidate(managerLeaveReportProvider);
        },
        icon: const Icon(Icons.refresh),
      ),
      child: _body(context, ref, requests, report),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ManagerLeaveRequest>> requests,
    AsyncValue<ManagerLeaveReport> report,
  ) {
    if (requests.isLoading || report.isLoading) {
      return const LoadingState(label: 'Loading leave requests...');
    }
    if (requests.hasError) {
      return managerErrorView(
        requests.error!,
        () => ref.invalidate(managerLeaveRequestsProvider),
      );
    }
    if (report.hasError) {
      return managerErrorView(
        report.error!,
        () => ref.invalidate(managerLeaveReportProvider),
      );
    }

    final items = requests.value!;
    final summary = report.value!;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(managerLeaveRequestsProvider);
        ref.invalidate(managerLeaveReportProvider);
        await Future.wait([
          ref.read(managerLeaveRequestsProvider.future),
          ref.read(managerLeaveReportProvider.future),
        ]);
      },
      child: ListView(
        children: [
          GridView.count(
            crossAxisCount: MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.18,
            children: [
              MetricTile(
                label: 'Requests',
                value: '${summary.totalRequests}',
                icon: Icons.beach_access_outlined,
              ),
              MetricTile(
                label: 'Pending',
                value: '${summary.pendingRequests}',
                icon: Icons.pending_actions_outlined,
              ),
              MetricTile(
                label: 'Approved',
                value: '${summary.approvedRequests}',
                icon: Icons.check_circle_outline,
              ),
              MetricTile(
                label: 'Rejected',
                value: '${summary.rejectedRequests}',
                icon: Icons.cancel_outlined,
              ),
            ],
          ),
          if (summary.leaveUsageByType.isNotEmpty) ...[
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage by type',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  for (final usage in summary.leaveUsageByType)
                    InfoLine(
                      label: usage.leaveTypeName,
                      value:
                          '${dayCount(usage.usedDays)} of ${dayCount(usage.totalDays)} days used',
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (items.isEmpty)
            const EmptyState(
              icon: Icons.beach_access_outlined,
              title: 'No team leave requests',
              message: 'Direct-report leave requests will appear here.',
            )
          else
            for (final request in items) ...[
              _LeaveRequestCard(request: request),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _LeaveRequestCard extends ConsumerWidget {
  const _LeaveRequestCard({required this.request});

  final ManagerLeaveRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  request.leaveTypeName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip(label: request.status),
            ],
          ),
          const SizedBox(height: 8),
          InfoLine(
              label: 'Employee',
              value: 'Employee ${shortId(request.employeeId)}'),
          InfoLine(label: 'Start', value: shortDate(request.startDate)),
          InfoLine(label: 'End', value: shortDate(request.endDate)),
          InfoLine(label: 'Days', value: dayCount(request.requestedDays)),
          if (request.reason != null)
            InfoLine(label: 'Reason', value: request.reason!),
          if (request.reviewedAt != null)
            InfoLine(
                label: 'Reviewed', value: shortDateTime(request.reviewedAt)),
          if (request.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('manager.leave.reject.${request.id}'),
                    onPressed: () => _review(context, ref, approve: false),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    key: ValueKey('manager.leave.approve.${request.id}'),
                    onPressed: () => _review(context, ref, approve: true),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref, {
    required bool approve,
  }) async {
    final comment = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(approve ? 'Approve leave' : 'Reject leave'),
          content: TextField(
            key: const ValueKey('manager.leave.review.comment'),
            controller: comment,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Comment optional'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const ValueKey('manager.leave.review.confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(approve ? 'Approve' : 'Reject'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      final repo = ref.read(managerRepositoryProvider);
      if (approve) {
        await repo.approveLeaveRequest(request.id, comment: comment.text);
      } else {
        await repo.rejectLeaveRequest(request.id, comment: comment.text);
      }
      ref.invalidate(managerLeaveRequestsProvider);
      ref.invalidate(managerLeaveReportProvider);
      if (context.mounted) {
        showManagerSuccessSnack(
          context,
          approve ? 'Leave approved.' : 'Leave rejected.',
        );
      }
    } catch (error) {
      if (context.mounted) showManagerFailureSnack(context, error);
    } finally {
      comment.dispose();
    }
  }
}
