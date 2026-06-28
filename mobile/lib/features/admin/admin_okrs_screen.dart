import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

const _okrStatuses = [
  'DRAFT',
  'ASSIGNED',
  'IN_PROGRESS',
  'SUBMITTED',
  'APPROVED',
  'REJECTED',
  'ARCHIVED',
];

class AdminOkrsScreen extends ConsumerStatefulWidget {
  const AdminOkrsScreen({super.key});

  @override
  ConsumerState<AdminOkrsScreen> createState() => _AdminOkrsScreenState();
}

class _AdminOkrsScreenState extends ConsumerState<AdminOkrsScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final okrs = ref.watch(adminOkrsProvider(_status));
    final employees = ref.watch(employeesProvider).valueOrNull ?? const [];
    final employeeNames = {
      for (final employee in employees) employee.id: employee.fullName,
    };

    return AdminPage(
      title: 'OKRs',
      subtitle: 'Company objectives and approvals.',
      action: IconButton.filled(
        key: const ValueKey('admin.okr.create'),
        tooltip: 'New OKR',
        onPressed: () => _showOkrSheet(context),
        icon: const Icon(Icons.add_task_outlined),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String?>(
            key: const ValueKey('admin.okr.statusFilter'),
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status filter'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All OKRs'),
              ),
              for (final status in _okrStatuses)
                DropdownMenuItem(value: status, child: Text(status)),
            ],
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: okrs.when(
              loading: () => const LoadingState(label: 'Loading OKRs...'),
              error: (error, _) => adminErrorView(
                error,
                () => ref.invalidate(adminOkrsProvider(_status)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.track_changes_outlined,
                    title: 'No OKRs',
                    message: 'Assign objectives to active employees.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(adminOkrsProvider(_status));
                    ref.invalidate(employeesProvider);
                  },
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final okr = items[index];
                      return Card(
                        child: ListTile(
                          key: ValueKey('admin.okr.item.${okr.id}'),
                          onTap: () => context.go('/admin/okrs/${okr.id}'),
                          leading: const Icon(Icons.track_changes_outlined),
                          title: Text(okr.title),
                          subtitle: Text(
                            '${employeeNames[okr.employeeId] ?? okr.employeeId} - ${okr.progressPercent}%',
                          ),
                          trailing: StatusPill(
                            label: okr.status,
                            active: okr.status != 'ARCHIVED' &&
                                okr.status != 'REJECTED',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AdminOkrDetailScreen extends ConsumerWidget {
  const AdminOkrDetailScreen({super.key, required this.okrId});

  final String okrId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final okr = ref.watch(adminOkrProvider(okrId));
    final employees = ref.watch(employeesProvider).valueOrNull ?? const [];
    final employeeNames = {
      for (final employee in employees) employee.id: employee.fullName,
    };

    return AdminPage(
      title: 'OKR',
      subtitle: 'Objective detail and approval state.',
      child: okr.when(
        loading: () => const LoadingState(label: 'Loading OKR...'),
        error: (error, _) => adminErrorView(
          error,
          () => ref.invalidate(adminOkrProvider(okrId)),
        ),
        data: (item) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminOkrProvider(okrId));
            ref.invalidate(adminOkrsProvider(null));
            ref.invalidate(employeesProvider);
          },
          child: ListView(
            children: [
              ElevatedButton.icon(
                key: const ValueKey('admin.okr.edit'),
                onPressed: () => _showOkrSheet(context, existing: item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit OKR'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('admin.okr.changeStatus'),
                onPressed: () => _showOkrStatusSheet(context, item),
                icon: const Icon(Icons.published_with_changes_outlined),
                label: const Text('Change status'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('admin.okr.managerApprove'),
                onPressed: item.canApprove
                    ? () => _approveOkr(context, ref, item)
                    : null,
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Approve as admin'),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StatusPill(
                            label: item.status,
                            active: item.status != 'ARCHIVED' &&
                                item.status != 'REJECTED',
                          ),
                        ],
                      ),
                      if (item.description != null) ...[
                        const SizedBox(height: 8),
                        Text(item.description!),
                      ],
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: item.progressPercent / 100,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${item.progressPercent}% complete'),
                      const Divider(height: 28),
                      InfoRow(
                        label: 'Employee',
                        value:
                            employeeNames[item.employeeId] ?? item.employeeId,
                      ),
                      InfoRow(
                        label: 'Assigned by',
                        value: employeeNames[item.assignedById] ??
                            item.assignedById,
                      ),
                      InfoRow(label: 'Due', value: _dateOnly(item.dueDate)),
                      InfoRow(
                        label: 'Employee OK',
                        value: item.employeeApproved ? 'Approved' : 'Pending',
                      ),
                      InfoRow(
                        label: 'Admin OK',
                        value: item.managerApproved ? 'Approved' : 'Pending',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Progress',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (item.progressUpdates.isEmpty)
                const EmptyState(
                  icon: Icons.trending_up_outlined,
                  title: 'No progress updates',
                  message: 'Employee updates will appear here.',
                )
              else
                for (final progress in item.progressUpdates) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoRow(
                            label: 'Progress',
                            value: '${progress.progressPercent}%',
                          ),
                          InfoRow(
                            label: 'Updated',
                            value: _dateTime(progress.createdAt),
                          ),
                          if (progress.note != null)
                            InfoRow(label: 'Note', value: progress.note!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              const SizedBox(height: 8),
              Text(
                'Approvals',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (item.approvals.isEmpty)
                const EmptyState(
                  icon: Icons.verified_outlined,
                  title: 'No approvals',
                  message: 'Employee and admin approvals will appear here.',
                )
              else
                for (final approval in item.approvals) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InfoRow(
                            label: 'Approver',
                            value: employeeNames[approval.approverEmployeeId] ??
                                approval.approverEmployeeId,
                          ),
                          InfoRow(label: 'Status', value: approval.status),
                          InfoRow(
                            label: 'Updated',
                            value: _dateTime(approval.updatedAt),
                          ),
                          if (approval.comment != null)
                            InfoRow(label: 'Comment', value: approval.comment!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _showOkrSheet(
  BuildContext context, {
  AdminOkr? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _OkrFormSheet(existing: existing),
  );
}

Future<void> _showOkrStatusSheet(
  BuildContext context,
  AdminOkr okr,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _OkrStatusSheet(okr: okr),
  );
}

Future<void> _approveOkr(
  BuildContext context,
  WidgetRef ref,
  AdminOkr okr,
) async {
  final comment = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Approve OKR?'),
      content: TextField(
        key: const ValueKey('admin.okr.approvalComment'),
        controller: comment,
        maxLength: 1000,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Comment optional'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const ValueKey('admin.okr.approvalSubmit'),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Approve'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await ref
        .read(adminRepositoryProvider)
        .managerApproveOkr(okr.id, comment: comment.text);
    ref.invalidate(adminOkrProvider(okr.id));
    ref.invalidate(adminOkrsProvider(null));
    if (context.mounted) showSuccessSnack(context, 'OKR approved.');
  } catch (error) {
    if (context.mounted) showFailureSnack(context, error);
  } finally {
    comment.dispose();
  }
}

class _OkrFormSheet extends ConsumerStatefulWidget {
  const _OkrFormSheet({this.existing});

  final AdminOkr? existing;

  @override
  ConsumerState<_OkrFormSheet> createState() => _OkrFormSheetState();
}

class _OkrFormSheetState extends ConsumerState<_OkrFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _employeeSearch = TextEditingController();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _dueDate;
  String? _employeeId;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _employeeId = existing?.employeeId;
    _title = TextEditingController(text: existing?.title ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    _dueDate = TextEditingController(text: _dateInput(existing?.dueDate));
  }

  @override
  void dispose() {
    _employeeSearch.dispose();
    _title.dispose();
    _description.dispose();
    _dueDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              _editing ? 'Edit OKR' : 'New OKR',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_editing)
              InfoRow(label: 'Employee', value: _employeeId ?? 'Employee')
            else
              employees.when(
                loading: () =>
                    const LoadingState(label: 'Loading employees...'),
                error: (error, _) => adminErrorView(
                  error,
                  () => ref.invalidate(employeesProvider),
                ),
                data: (items) => _SelectableSearchList<AdminEmployee>(
                  key: const ValueKey('admin.okr.employeePicker'),
                  title: 'Employee',
                  searchController: _employeeSearch,
                  selectedId: _employeeId,
                  items: items
                      .where((employee) => employee.status == 'ACTIVE')
                      .toList(growable: false),
                  idOf: (employee) => employee.id,
                  labelOf: _employeeLabel,
                  searchOf: (employee) =>
                      '${employee.fullName} ${employee.email} ${employee.employeeCode}',
                  itemKeyPrefix: 'admin.okr.employee',
                  onSelected: (employee) =>
                      setState(() => _employeeId = employee.id),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.okr.title'),
              controller: _title,
              textInputAction: TextInputAction.next,
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.okr.description'),
              controller: _description,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Description optional',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.okr.dueDate'),
              controller: _dueDate,
              keyboardType: TextInputType.datetime,
              inputFormatters: [LengthLimitingTextInputFormatter(10)],
              decoration: const InputDecoration(
                labelText: 'Due date optional',
                hintText: 'YYYY-MM-DD',
              ),
              validator: (value) => _dateValidator(value, optional: true),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              key: const ValueKey('admin.okr.save'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save OKR'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_editing && (_employeeId == null || _employeeId!.isEmpty)) {
      showFailureSnack(context, const _SelectionFailure());
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repo.createOkr(
          employeeId: _employeeId!,
          title: _title.text,
          description: _description.text,
          dueDate: _dueDate.text,
        );
      } else {
        await repo.updateOkr(
          existing.id,
          title: _title.text,
          description: _description.text,
          dueDate: _dueDate.text,
        );
        ref.invalidate(adminOkrProvider(existing.id));
      }
      ref.invalidate(adminOkrsProvider(null));
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'OKR saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _OkrStatusSheet extends ConsumerStatefulWidget {
  const _OkrStatusSheet({required this.okr});

  final AdminOkr okr;

  @override
  ConsumerState<_OkrStatusSheet> createState() => _OkrStatusSheetState();
}

class _OkrStatusSheetState extends ConsumerState<_OkrStatusSheet> {
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.okr.status;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Change status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            key: const ValueKey('admin.okr.status'),
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              for (final status in _okrStatuses)
                DropdownMenuItem(value: status, child: Text(status)),
            ],
            onChanged: (value) =>
                setState(() => _status = value ?? widget.okr.status),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            key: const ValueKey('admin.okr.statusSave'),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save status'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(adminRepositoryProvider)
          .updateOkrStatus(widget.okr.id, status: _status);
      ref.invalidate(adminOkrProvider(widget.okr.id));
      ref.invalidate(adminOkrsProvider(null));
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'OKR status updated.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SelectableSearchList<T> extends StatefulWidget {
  const _SelectableSearchList({
    super.key,
    required this.title,
    required this.searchController,
    required this.selectedId,
    required this.items,
    required this.idOf,
    required this.labelOf,
    required this.searchOf,
    required this.itemKeyPrefix,
    required this.onSelected,
  });

  final String title;
  final TextEditingController searchController;
  final String? selectedId;
  final List<T> items;
  final String Function(T item) idOf;
  final String Function(T item) labelOf;
  final String Function(T item) searchOf;
  final String itemKeyPrefix;
  final ValueChanged<T> onSelected;

  @override
  State<_SelectableSearchList<T>> createState() =>
      _SelectableSearchListState<T>();
}

class _SelectableSearchListState<T> extends State<_SelectableSearchList<T>> {
  @override
  Widget build(BuildContext context) {
    final term = widget.searchController.text.trim().toLowerCase();
    final filtered = term.isEmpty
        ? widget.items.take(5).toList(growable: false)
        : widget.items
            .where(
              (item) => widget.searchOf(item).toLowerCase().contains(term),
            )
            .take(8)
            .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          key: ValueKey('${widget.itemKeyPrefix}.search'),
          controller: widget.searchController,
          decoration: InputDecoration(labelText: '${widget.title} search'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Text(
            'No matches',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          for (final item in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                key: ValueKey('${widget.itemKeyPrefix}.${widget.idOf(item)}'),
                onPressed: () {
                  widget.onSelected(item);
                  widget.searchController.text = widget.labelOf(item);
                  setState(() {});
                },
                child: Row(
                  children: [
                    Icon(
                      widget.selectedId == widget.idOf(item)
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.labelOf(item),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _SelectionFailure {
  const _SelectionFailure();
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}

String? _dateValidator(String? value, {required bool optional}) {
  final text = value?.trim() ?? '';
  if (optional && text.isEmpty) return null;
  final valid = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text);
  return valid ? null : 'Use YYYY-MM-DD';
}

String _employeeLabel(AdminEmployee employee) {
  if (employee.fullName == employee.email) return employee.email;
  return '${employee.fullName} - ${employee.email}';
}

String _dateInput(String? value) {
  if (value == null || value.isEmpty) return '';
  return value.length >= 10 ? value.substring(0, 10) : value;
}

String _dateOnly(String? value) {
  if (value == null || value.isEmpty) return 'Not set';
  return value.length >= 10 ? value.substring(0, 10) : value;
}

String _dateTime(String? value) {
  if (value == null || value.isEmpty) return 'Not recorded';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return parsed.toLocal().toString().split('.').first;
}
