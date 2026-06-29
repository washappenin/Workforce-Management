import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

const _notificationTypes = [
  'SYSTEM',
  'ATTENDANCE',
  'LEAVE',
  'OKR',
  'PERFORMANCE',
  'SUBSCRIPTION',
  'SECURITY',
];

const _targetRoles = [
  'EMPLOYEE',
  'MANAGER',
  'HR_ADMIN',
  'COMPANY_ADMIN',
  'SUPER_ADMIN',
];

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _message = TextEditingController();
  final _employeeSearch = TextEditingController();
  final Set<String> _selectedEmployeeIds = {};
  String _type = 'SYSTEM';
  String? _targetRole;
  bool _sending = false;
  AdminNotificationBroadcastResult? _result;

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _employeeSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);

    return AdminPage(
      title: 'Broadcasts',
      subtitle: 'Send in-app announcements to active company users.',
      child: employees.when(
        loading: () => const LoadingState(label: 'Loading recipients...'),
        error: (error, _) => adminErrorView(
          error,
          () => ref.invalidate(employeesProvider),
        ),
        data: (items) {
          final activeEmployees = items
              .where((employee) => employee.status == 'ACTIVE')
              .toList(growable: false);

          return Form(
            key: _formKey,
            child: ListView(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Compose broadcast',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          key: const ValueKey('admin.broadcast.title'),
                          controller: _title,
                          textInputAction: TextInputAction.next,
                          maxLength: 200,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          key: const ValueKey('admin.broadcast.message'),
                          controller: _message,
                          maxLength: 1000,
                          maxLines: 5,
                          decoration:
                              const InputDecoration(labelText: 'Message'),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: const ValueKey('admin.broadcast.type'),
                          initialValue: _type,
                          decoration: const InputDecoration(labelText: 'Type'),
                          items: [
                            for (final type in _notificationTypes)
                              DropdownMenuItem(value: type, child: Text(type)),
                          ],
                          onChanged: (value) =>
                              setState(() => _type = value ?? 'SYSTEM'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String?>(
                          key: const ValueKey('admin.broadcast.targetRole'),
                          initialValue: _targetRole,
                          decoration: const InputDecoration(
                            labelText: 'Role filter optional',
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('All active users'),
                            ),
                            for (final role in _targetRoles)
                              DropdownMenuItem(value: role, child: Text(role)),
                          ],
                          onChanged: (value) =>
                              setState(() => _targetRole = value),
                        ),
                        const SizedBox(height: 18),
                        _EmployeeTargetPicker(
                          employees: activeEmployees,
                          selectedIds: _selectedEmployeeIds,
                          searchController: _employeeSearch,
                          onChanged: () => setState(() {}),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          key: const ValueKey('admin.broadcast.send'),
                          onPressed: _sending ? null : _send,
                          icon: const Icon(Icons.campaign_outlined),
                          label: Text(
                            _sending ? 'Sending...' : 'Send broadcast',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_result != null) ...[
                  const SizedBox(height: 12),
                  _BroadcastResultCard(result: _result!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final result =
          await ref.read(adminRepositoryProvider).broadcastNotification(
                title: _title.text,
                message: _message.text,
                type: _type,
                targetRole: _targetRole,
                employeeIds: _selectedEmployeeIds.toList(growable: false),
              );
      if (!mounted) return;
      setState(() => _result = result);
      showSuccessSnack(
        context,
        '${result.notificationCount} notifications sent.',
      );
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _EmployeeTargetPicker extends StatefulWidget {
  const _EmployeeTargetPicker({
    required this.employees,
    required this.selectedIds,
    required this.searchController,
    required this.onChanged,
  });

  final List<AdminEmployee> employees;
  final Set<String> selectedIds;
  final TextEditingController searchController;
  final VoidCallback onChanged;

  @override
  State<_EmployeeTargetPicker> createState() => _EmployeeTargetPickerState();
}

class _EmployeeTargetPickerState extends State<_EmployeeTargetPicker> {
  @override
  Widget build(BuildContext context) {
    final term = widget.searchController.text.trim().toLowerCase();
    final filtered = term.isEmpty
        ? widget.employees.take(6).toList(growable: false)
        : widget.employees
            .where(
              (employee) => _employeeSearchText(employee).contains(term),
            )
            .take(10)
            .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Specific recipients optional',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: const ValueKey('admin.broadcast.employee.search'),
          controller: widget.searchController,
          decoration: const InputDecoration(
            labelText: 'Employee search',
            helperText: 'Leave empty to send to every eligible user.',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        if (widget.selectedIds.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final employee in widget.employees.where(
                (employee) => widget.selectedIds.contains(employee.id),
              ))
                InputChip(
                  key: ValueKey('admin.broadcast.employeeChip.${employee.id}'),
                  label: Text(employee.fullName),
                  onDeleted: () {
                    widget.selectedIds.remove(employee.id);
                    widget.onChanged();
                    setState(() {});
                  },
                ),
            ],
          ),
        if (widget.selectedIds.isNotEmpty) const SizedBox(height: 10),
        if (filtered.isEmpty)
          Text('No matches', style: Theme.of(context).textTheme.bodyMedium)
        else
          for (final employee in filtered)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                key: ValueKey('admin.broadcast.employee.${employee.id}'),
                onPressed: () {
                  if (widget.selectedIds.contains(employee.id)) {
                    widget.selectedIds.remove(employee.id);
                  } else {
                    widget.selectedIds.add(employee.id);
                  }
                  widget.onChanged();
                  setState(() {});
                },
                child: Row(
                  children: [
                    Icon(
                      widget.selectedIds.contains(employee.id)
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _employeeLabel(employee),
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

class _BroadcastResultCard extends StatelessWidget {
  const _BroadcastResultCard({required this.result});

  final AdminNotificationBroadcastResult result;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Broadcast sent',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StatusPill(label: result.type),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(
              label: 'Notifications',
              value: result.notificationCount.toString(),
            ),
            InfoRow(
              label: 'Recipients',
              value: result.recipientCount.toString(),
            ),
            InfoRow(
              label: 'Role filter',
              value: result.targetRole ?? 'All active users',
            ),
          ],
        ),
      ),
    );
  }
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}

String _employeeLabel(AdminEmployee employee) {
  if (employee.fullName == employee.email) return employee.email;
  return '${employee.fullName} - ${employee.email}';
}

String _employeeSearchText(AdminEmployee employee) {
  return '${employee.fullName} ${employee.email} ${employee.employeeCode} ${employee.roles.join(' ')}'
      .toLowerCase();
}
