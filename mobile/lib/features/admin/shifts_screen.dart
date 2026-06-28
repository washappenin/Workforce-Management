import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

class AdminShiftsScreen extends ConsumerWidget {
  const AdminShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shifts = ref.watch(shiftsProvider);
    return AdminPage(
      title: 'Shifts',
      subtitle: 'Work schedules and employee assignments.',
      action: IconButton.filled(
        key: const ValueKey('admin.shift.create'),
        tooltip: 'New shift',
        onPressed: () => _showShiftSheet(context),
        icon: const Icon(Icons.add_alarm_outlined),
      ),
      child: shifts.when(
        loading: () => const LoadingState(label: 'Loading shifts...'),
        error: (error, _) =>
            adminErrorView(error, () => ref.invalidate(shiftsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.schedule_outlined,
              title: 'No shifts configured',
              message: 'Create shifts before assigning employees.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(shiftsProvider),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final shift = items[index];
                return Card(
                  child: ListTile(
                    key: ValueKey('admin.shift.item.${shift.id}'),
                    onTap: () => context.go('/admin/shifts/${shift.id}'),
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(shift.name),
                    subtitle: Text('${shift.startTime} - ${shift.endTime}'),
                    trailing: StatusPill(
                      label: shift.status,
                      active: shift.isActive,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AdminShiftDetailScreen extends ConsumerWidget {
  const AdminShiftDetailScreen({super.key, required this.shiftId});

  final String shiftId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shift = ref.watch(shiftProvider(shiftId));
    final assignments = ref.watch(shiftAssignmentsProvider(shiftId));
    final employees = ref.watch(employeesProvider).valueOrNull ?? const [];
    final employeeNames = {
      for (final employee in employees) employee.id: employee.fullName,
    };

    return AdminPage(
      title: 'Shift',
      subtitle: 'Schedule details and employee coverage.',
      child: shift.when(
        loading: () => const LoadingState(label: 'Loading shift...'),
        error: (error, _) => adminErrorView(
          error,
          () => ref.invalidate(shiftProvider(shiftId)),
        ),
        data: (item) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(shiftProvider(shiftId));
            ref.invalidate(shiftAssignmentsProvider(shiftId));
            ref.invalidate(employeesProvider);
          },
          child: ListView(
            children: [
              ElevatedButton.icon(
                key: const ValueKey('admin.shift.edit'),
                onPressed: () => _showShiftSheet(context, existing: item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit shift'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('admin.shift.toggleStatus'),
                onPressed: item.status == 'ARCHIVED'
                    ? null
                    : () => _toggleShiftStatus(context, ref, item),
                icon: Icon(item.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline),
                label: Text(item.isActive ? 'Deactivate' : 'Activate'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('admin.shift.archive'),
                onPressed: item.status == 'ARCHIVED'
                    ? null
                    : () => _archiveShift(context, ref, item),
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive shift'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('admin.shift.assign'),
                onPressed: item.isActive
                    ? () => _showAssignmentSheet(context, shiftId: item.id)
                    : null,
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('Assign employee'),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StatusPill(label: item.status, active: item.isActive),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InfoRow(label: 'Start', value: item.startTime),
                      InfoRow(label: 'End', value: item.endTime),
                      InfoRow(label: 'Company', value: item.companyId),
                      InfoRow(label: 'Record', value: item.id),
                      if (item.updatedAt != null)
                        InfoRow(
                            label: 'Updated', value: _dateTime(item.updatedAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Assignments',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              assignments.when(
                loading: () => const SizedBox(
                  height: 180,
                  child: LoadingState(label: 'Loading assignments...'),
                ),
                error: (error, _) => SizedBox(
                  height: 260,
                  child: adminErrorView(
                    error,
                    () => ref.invalidate(shiftAssignmentsProvider(shiftId)),
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const EmptyState(
                      icon: Icons.event_available_outlined,
                      title: 'No employees assigned',
                      message: 'Assign active employees to this shift.',
                    );
                  }
                  return Column(
                    children: [
                      for (final assignment in items) ...[
                        _AssignmentCard(
                          assignment: assignment,
                          employeeName: employeeNames[assignment.employeeId],
                          onEdit: () => _showAssignmentSheet(
                            context,
                            shiftId: item.id,
                            existing: assignment,
                          ),
                          onDelete: () =>
                              _deleteAssignment(context, ref, assignment),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.employeeName,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminShiftAssignment assignment;
  final String? employeeName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = employeeName ?? assignment.employeeId;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: ValueKey('admin.shiftAssignment.edit.${assignment.id}'),
                  tooltip: 'Edit assignment',
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  key:
                      ValueKey('admin.shiftAssignment.delete.${assignment.id}'),
                  tooltip: 'Remove assignment',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            const SizedBox(height: 8),
            InfoRow(label: 'Starts', value: _dateOnly(assignment.startsOn)),
            InfoRow(
              label: 'Ends',
              value: _dateOnly(assignment.endsOn, fallback: 'Open ended'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showShiftSheet(
  BuildContext context, {
  AdminShift? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ShiftFormSheet(existing: existing),
  );
}

Future<void> _showAssignmentSheet(
  BuildContext context, {
  required String shiftId,
  AdminShiftAssignment? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _AssignmentFormSheet(
      shiftId: shiftId,
      existing: existing,
    ),
  );
}

Future<void> _toggleShiftStatus(
  BuildContext context,
  WidgetRef ref,
  AdminShift shift,
) async {
  final nextStatus = shift.isActive ? 'INACTIVE' : 'ACTIVE';
  final confirmed = await confirmAction(
    context,
    title: shift.isActive ? 'Deactivate shift?' : 'Activate shift?',
    message: shift.isActive
        ? 'New employee assignments will be paused for this shift.'
        : 'This shift can receive employee assignments.',
    confirmLabel: shift.isActive ? 'Deactivate' : 'Activate',
  );
  if (!confirmed || !context.mounted) return;
  await _setShiftStatus(context, ref, shift, nextStatus);
}

Future<void> _archiveShift(
  BuildContext context,
  WidgetRef ref,
  AdminShift shift,
) async {
  final confirmed = await confirmAction(
    context,
    title: 'Archive shift?',
    message:
        'Historical assignments remain intact, but this shift will no longer be used.',
    confirmLabel: 'Archive',
  );
  if (!confirmed || !context.mounted) return;
  await _setShiftStatus(context, ref, shift, 'ARCHIVED');
}

Future<void> _setShiftStatus(
  BuildContext context,
  WidgetRef ref,
  AdminShift shift,
  String status,
) async {
  try {
    await ref
        .read(adminRepositoryProvider)
        .updateShiftStatus(shift.id, status: status);
    ref.invalidate(shiftsProvider);
    ref.invalidate(shiftProvider(shift.id));
    if (context.mounted) showSuccessSnack(context, 'Shift status updated.');
  } catch (error) {
    if (context.mounted) showFailureSnack(context, error);
  }
}

Future<void> _deleteAssignment(
  BuildContext context,
  WidgetRef ref,
  AdminShiftAssignment assignment,
) async {
  final confirmed = await confirmAction(
    context,
    title: 'Remove assignment?',
    message: 'This employee will no longer be attached to the shift.',
    confirmLabel: 'Remove',
  );
  if (!confirmed || !context.mounted) return;
  try {
    await ref
        .read(adminRepositoryProvider)
        .deleteShiftAssignment(assignment.id);
    ref.invalidate(shiftAssignmentsProvider(assignment.shiftId));
    if (context.mounted) showSuccessSnack(context, 'Assignment removed.');
  } catch (error) {
    if (context.mounted) showFailureSnack(context, error);
  }
}

class _ShiftFormSheet extends ConsumerStatefulWidget {
  const _ShiftFormSheet({this.existing});

  final AdminShift? existing;

  @override
  ConsumerState<_ShiftFormSheet> createState() => _ShiftFormSheetState();
}

class _ShiftFormSheetState extends ConsumerState<_ShiftFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _startTime;
  late final TextEditingController _endTime;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final shift = widget.existing;
    _name = TextEditingController(text: shift?.name ?? '');
    _startTime = TextEditingController(text: shift?.startTime ?? '');
    _endTime = TextEditingController(text: shift?.endTime ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _startTime.dispose();
    _endTime.dispose();
    super.dispose();
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
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              _editing ? 'Edit shift' : 'New shift',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const ValueKey('admin.shift.name'),
              controller: _name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.shift.startTime'),
              controller: _startTime,
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Start time',
                hintText: 'HH:mm',
              ),
              validator: _timeValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.shift.endTime'),
              controller: _endTime,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'End time',
                hintText: 'HH:mm',
              ),
              validator: _timeValidator,
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              key: const ValueKey('admin.shift.save'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save shift'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repo.createShift(
          name: _name.text,
          startTime: _startTime.text,
          endTime: _endTime.text,
        );
      } else {
        await repo.updateShift(
          existing.id,
          name: _name.text,
          startTime: _startTime.text,
          endTime: _endTime.text,
        );
        ref.invalidate(shiftProvider(existing.id));
      }
      ref.invalidate(shiftsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Shift saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _AssignmentFormSheet extends ConsumerStatefulWidget {
  const _AssignmentFormSheet({
    required this.shiftId,
    this.existing,
  });

  final String shiftId;
  final AdminShiftAssignment? existing;

  @override
  ConsumerState<_AssignmentFormSheet> createState() =>
      _AssignmentFormSheetState();
}

class _AssignmentFormSheetState extends ConsumerState<_AssignmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _startsOn;
  late final TextEditingController _endsOn;
  String? _employeeId;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final assignment = widget.existing;
    _employeeId = assignment?.employeeId;
    _startsOn = TextEditingController(
      text: _dateOnly(assignment?.startsOn, fallback: _todayDate()),
    );
    _endsOn = TextEditingController(text: _dateOnly(assignment?.endsOn));
  }

  @override
  void dispose() {
    _startsOn.dispose();
    _endsOn.dispose();
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
              _editing ? 'Edit assignment' : 'Assign employee',
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
                data: (items) {
                  final activeEmployees = items
                      .where((employee) => employee.status == 'ACTIVE')
                      .toList(growable: false);
                  return DropdownButtonFormField<String>(
                    key: const ValueKey('admin.shiftAssignment.employee'),
                    initialValue: _employeeId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Employee'),
                    items: [
                      for (final employee in activeEmployees)
                        DropdownMenuItem(
                          value: employee.id,
                          child: Text(
                            _employeeLabel(employee),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                    onChanged: (value) => setState(() => _employeeId = value),
                  );
                },
              ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.shiftAssignment.startsOn'),
              controller: _startsOn,
              keyboardType: TextInputType.datetime,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Starts on',
                hintText: 'YYYY-MM-DD',
              ),
              validator: (value) => _dateValidator(value, optional: false),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const ValueKey('admin.shiftAssignment.endsOn'),
              controller: _endsOn,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Ends on optional',
                hintText: 'YYYY-MM-DD',
              ),
              validator: (value) => _dateValidator(value, optional: true),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              key: const ValueKey('admin.shiftAssignment.save'),
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save assignment'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_editing && (_employeeId == null || _employeeId!.isEmpty)) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repo.assignShift(
          widget.shiftId,
          employeeId: _employeeId!,
          startsOn: _startsOn.text,
          endsOn: _endsOn.text,
        );
      } else {
        await repo.updateShiftAssignment(
          existing.id,
          startsOn: _startsOn.text,
          endsOn: _endsOn.text,
        );
      }
      ref.invalidate(shiftAssignmentsProvider(widget.shiftId));
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(
        context,
        existing == null ? 'Shift assigned.' : 'Assignment saved.',
      );
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}

String? _timeValidator(String? value) {
  final text = value?.trim() ?? '';
  final valid = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$').hasMatch(text);
  return valid ? null : 'Use HH:mm';
}

String? _dateValidator(String? value, {required bool optional}) {
  final text = value?.trim() ?? '';
  if (optional && text.isEmpty) return null;
  final valid = RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text);
  if (!valid) return 'Use YYYY-MM-DD';
  return null;
}

String _employeeLabel(AdminEmployee employee) {
  if (employee.fullName == employee.email) return employee.email;
  return '${employee.fullName} - ${employee.email}';
}

String _dateOnly(String? value, {String fallback = ''}) {
  if (value == null || value.isEmpty) return fallback;
  return value.length >= 10 ? value.substring(0, 10) : value;
}

String _dateTime(String? value) {
  if (value == null || value.isEmpty) return 'Not recorded';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return parsed.toLocal().toString().split('.').first;
}

String _todayDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';
}
