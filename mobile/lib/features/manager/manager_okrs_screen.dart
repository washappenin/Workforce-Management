import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'manager_models.dart';
import 'manager_repository.dart';
import 'widgets/manager_widgets.dart';

const _okrStatuses = [
  'DRAFT',
  'ASSIGNED',
  'IN_PROGRESS',
  'SUBMITTED',
  'APPROVED',
  'REJECTED',
  'ARCHIVED',
];

class ManagerOkrsScreen extends ConsumerWidget {
  const ManagerOkrsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final okrs = ref.watch(managerOkrsProvider);
    final report = ref.watch(managerOkrReportProvider);

    return ManagerPage(
      title: 'OKRs',
      subtitle: 'Direct-report objectives',
      action: IconButton.outlined(
        key: const ValueKey('manager.okr.create'),
        tooltip: 'New OKR',
        onPressed: () => _showOkrSheet(context, ref),
        icon: const Icon(Icons.add),
      ),
      child: _body(context, ref, okrs, report),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ManagerOkr>> okrs,
    AsyncValue<ManagerOkrReport> report,
  ) {
    if (okrs.isLoading || report.isLoading) {
      return const LoadingState(label: 'Loading team OKRs...');
    }
    if (okrs.hasError) {
      return managerErrorView(
          okrs.error!, () => ref.invalidate(managerOkrsProvider));
    }
    if (report.hasError) {
      return managerErrorView(
          report.error!, () => ref.invalidate(managerOkrReportProvider));
    }

    final items = okrs.value!;
    final summary = report.value!;
    return RefreshIndicator(
      onRefresh: () async {
        _refresh(ref);
        await Future.wait([
          ref.read(managerOkrsProvider.future),
          ref.read(managerOkrReportProvider.future),
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
                label: 'OKRs',
                value: '${summary.totalOkrs}',
                icon: Icons.track_changes_outlined,
              ),
              MetricTile(
                label: 'Active',
                value: '${summary.activeCount}',
                icon: Icons.bolt_outlined,
              ),
              MetricTile(
                label: 'Completed',
                value: '${summary.completedCount}',
                icon: Icons.verified_outlined,
              ),
              MetricTile(
                label: 'Overdue',
                value: '${summary.overdueCount}',
                icon: Icons.warning_amber_outlined,
              ),
            ],
          ),
          if (summary.averageProgressPercent != null) ...[
            const SizedBox(height: 14),
            SectionCard(
              child: InfoLine(
                label: 'Avg progress',
                value: '${summary.averageProgressPercent!.toStringAsFixed(1)}%',
              ),
            ),
          ],
          const SizedBox(height: 14),
          if (items.isEmpty)
            const EmptyState(
              icon: Icons.track_changes_outlined,
              title: 'No team OKRs',
              message:
                  'Assign objectives once direct-report IDs are available.',
            )
          else
            for (final okr in items) ...[
              _OkrCard(okr: okr),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class ManagerOkrDetailScreen extends ConsumerWidget {
  const ManagerOkrDetailScreen({super.key, required this.okrId});

  final String okrId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final okr = ref.watch(managerOkrProvider(okrId));

    return ManagerPage(
      title: 'OKR detail',
      subtitle: 'Objective metadata and approvals',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(managerOkrProvider(okrId)),
        icon: const Icon(Icons.refresh),
      ),
      child: okr.when(
        loading: () => const LoadingState(label: 'Loading OKR...'),
        error: (error, _) => managerErrorView(
            error, () => ref.invalidate(managerOkrProvider(okrId))),
        data: (item) => ListView(children: [_OkrCard(okr: item)]),
      ),
    );
  }
}

class _OkrCard extends ConsumerWidget {
  const _OkrCard({required this.okr});

  final ManagerOkr okr;

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
                  okr.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              StatusChip(label: okr.status),
            ],
          ),
          if (okr.description != null) ...[
            const SizedBox(height: 8),
            Text(okr.description!),
          ],
          const SizedBox(height: 8),
          InfoLine(
              label: 'Employee',
              value:
                  okr.employee?.label ?? 'Employee ${shortId(okr.employeeId)}'),
          InfoLine(label: 'Progress', value: '${okr.progressPercent}%'),
          InfoLine(label: 'Due', value: shortDate(okr.dueDate)),
          InfoLine(
              label: 'Employee approval',
              value: okr.employeeApproved ? 'Approved' : 'Pending'),
          InfoLine(
              label: 'Manager approval',
              value: okr.managerApproved ? 'Approved' : 'Pending'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                key: ValueKey('manager.okr.edit.${okr.id}'),
                onPressed: () => _showOkrSheet(context, ref, existing: okr),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              OutlinedButton.icon(
                key: ValueKey('manager.okr.status.${okr.id}'),
                onPressed: () => _showStatusSheet(context, ref, okr),
                icon: const Icon(Icons.swap_horiz_outlined),
                label: const Text('Status'),
              ),
              ElevatedButton.icon(
                key: ValueKey('manager.okr.approve.${okr.id}'),
                onPressed: okr.canApprove ? () => _approve(context, ref) : null,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final comment = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve OKR'),
          content: TextField(
            key: const ValueKey('manager.okr.approve.comment'),
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
              key: const ValueKey('manager.okr.approve.confirm'),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Approve'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await ref.read(managerRepositoryProvider).approveOkr(
            okr.id,
            comment: comment.text,
          );
      _refresh(ref);
      ref.invalidate(managerOkrProvider(okr.id));
      if (context.mounted) showManagerSuccessSnack(context, 'OKR approved.');
    } catch (error) {
      if (context.mounted) showManagerFailureSnack(context, error);
    } finally {
      comment.dispose();
    }
  }
}

Future<void> _showOkrSheet(
  BuildContext context,
  WidgetRef ref, {
  ManagerOkr? existing,
}) async {
  final formKey = GlobalKey<FormState>();
  final members = await ref.read(managerTeamMembersProvider.future);
  if (!context.mounted) return;
  final employee = TextEditingController(
    text: existing?.employeeId ?? (members.isEmpty ? '' : members.first.id),
  );
  final title = TextEditingController(text: existing?.title ?? '');
  final description = TextEditingController(text: existing?.description ?? '');
  final dueDate = TextEditingController(text: _dateOnly(existing?.dueDate));
  var selectedEmployeeId = employee.text;

  try {
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? 'New OKR' : 'Edit OKR'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (existing == null && members.isNotEmpty)
                    DropdownButtonFormField<String>(
                      key: const ValueKey('manager.okr.employee.dropdown'),
                      initialValue: selectedEmployeeId,
                      decoration: const InputDecoration(labelText: 'Employee'),
                      items: [
                        for (final member in members)
                          DropdownMenuItem(
                            value: member.id,
                            child: Text(member.label),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedEmployeeId = value ?? '';
                          employee.text = selectedEmployeeId;
                        });
                      },
                    )
                  else
                    TextFormField(
                      key: const ValueKey('manager.okr.employeeId'),
                      controller: employee,
                      decoration:
                          const InputDecoration(labelText: 'Employee ID'),
                      readOnly: existing != null,
                      validator: _required,
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('manager.okr.title'),
                    controller: title,
                    maxLength: 200,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: _required,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('manager.okr.description'),
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description optional',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const ValueKey('manager.okr.dueDate'),
                    controller: dueDate,
                    decoration: const InputDecoration(
                      labelText: 'Due date optional',
                      hintText: 'YYYY-MM-DD',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const ValueKey('manager.okr.save'),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final repo = ref.read(managerRepositoryProvider);
                  if (existing == null) {
                    await repo.createOkr(
                      employeeId: employee.text,
                      title: title.text,
                      description: description.text,
                      dueDate: dueDate.text,
                    );
                  } else {
                    await repo.updateOkr(
                      existing.id,
                      title: title.text,
                      description: description.text,
                      dueDate: dueDate.text,
                    );
                  }
                  _refresh(ref);
                  if (existing != null) {
                    ref.invalidate(managerOkrProvider(existing.id));
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    showManagerSuccessSnack(
                      context,
                      existing == null ? 'OKR assigned.' : 'OKR updated.',
                    );
                  }
                } catch (error) {
                  if (context.mounted) showManagerFailureSnack(context, error);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  } finally {
    employee.dispose();
    title.dispose();
    description.dispose();
    dueDate.dispose();
  }
}

Future<void> _showStatusSheet(
  BuildContext context,
  WidgetRef ref,
  ManagerOkr okr,
) async {
  var status = okr.status;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Update OKR status'),
        content: DropdownButtonFormField<String>(
          key: const ValueKey('manager.okr.status.dropdown'),
          initialValue: status,
          decoration: const InputDecoration(labelText: 'Status'),
          items: [
            for (final item in _okrStatuses)
              DropdownMenuItem(value: item, child: Text(titleCase(item))),
          ],
          onChanged: (value) => setState(() => status = value ?? okr.status),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            key: const ValueKey('manager.okr.status.save'),
            onPressed: () async {
              try {
                await ref.read(managerRepositoryProvider).updateOkrStatus(
                      okr.id,
                      status: status,
                    );
                _refresh(ref);
                ref.invalidate(managerOkrProvider(okr.id));
                if (context.mounted) {
                  Navigator.of(context).pop();
                  showManagerSuccessSnack(context, 'OKR status updated.');
                }
              } catch (error) {
                if (context.mounted) showManagerFailureSnack(context, error);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

void _refresh(WidgetRef ref) {
  ref.invalidate(managerOkrsProvider);
  ref.invalidate(managerOkrReportProvider);
  ref.invalidate(managerTeamMembersProvider);
}

String? _required(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;

String _dateOnly(String? value) {
  if (value == null || value.isEmpty) return '';
  return value.length >= 10 ? value.substring(0, 10) : value;
}
