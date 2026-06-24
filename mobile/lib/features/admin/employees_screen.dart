import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_controller.dart';
import '../../core/auth/models.dart';
import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

const _employeeStatuses = ['ACTIVE', 'INACTIVE', 'ON_LEAVE', 'TERMINATED'];

class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});

  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final employees = ref.watch(employeesProvider);
    final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
    final designations =
        ref.watch(designationsProvider).valueOrNull ?? const [];
    final departmentNames = {
      for (final department in departments) department.id: department.name,
    };
    final designationNames = {
      for (final designation in designations) designation.id: designation.title,
    };

    return AdminPage(
      title: 'Employees',
      subtitle: 'Staff records, roles, managers, and status.',
      action: IconButton.filled(
        tooltip: 'New employee',
        onPressed: () => _showEmployeeCreateSheet(context),
        icon: const Icon(Icons.person_add_alt_1),
      ),
      child: employees.when(
        loading: () => const LoadingState(label: 'Loading employees...'),
        error: (error, _) =>
            adminErrorView(error, () => ref.invalidate(employeesProvider)),
        data: (items) {
          final term = _search.text.trim().toLowerCase();
          final filtered = term.isEmpty
              ? items
              : items.where((item) {
                  final haystack = [
                    item.fullName,
                    item.email,
                    item.employeeCode,
                    item.status,
                    item.roles.join(' '),
                  ].join(' ').toLowerCase();
                  return haystack.contains(term);
                }).toList(growable: false);
          return Column(
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search employees',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        icon: Icons.people_outline,
                        title: 'No employees',
                        message:
                            'Create employees before assigning shifts or managers.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(employeesProvider);
                          ref.invalidate(departmentsProvider);
                          ref.invalidate(designationsProvider);
                        },
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final employee = filtered[index];
                            final department =
                                departmentNames[employee.departmentId] ??
                                    'No department';
                            final designation =
                                designationNames[employee.designationId] ??
                                    roleLabel(employee.primaryRole);
                            return Card(
                              child: ListTile(
                                onTap: () => context
                                    .go('/admin/employees/${employee.id}'),
                                title: Text(employee.fullName),
                                subtitle: Text(
                                  '${employee.employeeCode} - $department - $designation',
                                ),
                                trailing: StatusPill(
                                  label: employee.status,
                                  active: employee.status == 'ACTIVE' ||
                                      employee.status == 'ON_LEAVE',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class EmployeeDetailScreen extends ConsumerWidget {
  const EmployeeDetailScreen({super.key, required this.employeeId});

  final String employeeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employee = ref.watch(employeeProvider(employeeId));
    final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
    final designations =
        ref.watch(designationsProvider).valueOrNull ?? const [];
    final departmentNames = {
      for (final department in departments) department.id: department.name,
    };
    final designationNames = {
      for (final designation in designations) designation.id: designation.title,
    };

    return AdminPage(
      title: 'Employee',
      subtitle: 'Profile, status, manager, and face enrollment.',
      child: employee.when(
        loading: () => const LoadingState(label: 'Loading employee...'),
        error: (error, _) => adminErrorView(
          error,
          () => ref.invalidate(employeeProvider(employeeId)),
        ),
        data: (item) {
          final department =
              departmentNames[item.departmentId] ?? 'No department';
          final designation =
              designationNames[item.designationId] ?? 'No designation';
          final manager = item.manager?.name ?? 'No manager';
          return ListView(
            children: [
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
                              item.fullName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StatusPill(
                            label: item.status,
                            active: item.status == 'ACTIVE' ||
                                item.status == 'ON_LEAVE',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      InfoRow(label: 'Email', value: item.email),
                      InfoRow(label: 'Code', value: item.employeeCode),
                      InfoRow(
                        label: 'Role',
                        value: item.roles.map(roleLabel).join(', '),
                      ),
                      InfoRow(label: 'Department', value: department),
                      InfoRow(label: 'Designation', value: designation),
                      InfoRow(label: 'Manager', value: manager),
                      InfoRow(label: 'Phone', value: item.phone ?? 'Not set'),
                      InfoRow(
                        label: 'Hire date',
                        value: item.hireDate ?? 'Not set',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showEmployeeEditSheet(context, item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit profile'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _showEmployeeStatusSheet(context, item),
                icon: const Icon(Icons.published_with_changes_outlined),
                label: const Text('Change status'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _showManagerSheet(context, item),
                icon: const Icon(Icons.supervisor_account_outlined),
                label: const Text('Assign manager'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => context.go('/admin/employees/${item.id}/face'),
                icon: const Icon(Icons.face_retouching_natural_outlined),
                label: const Text('Face enrollment'),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showEmployeeCreateSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const _EmployeeFormSheet(),
  );
}

Future<void> _showEmployeeEditSheet(
  BuildContext context,
  AdminEmployee employee,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EmployeeFormSheet(existing: employee),
  );
}

Future<void> _showEmployeeStatusSheet(
  BuildContext context,
  AdminEmployee employee,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EmployeeStatusSheet(employee: employee),
  );
}

Future<void> _showManagerSheet(
  BuildContext context,
  AdminEmployee employee,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _ManagerSheet(employee: employee),
  );
}

class _EmployeeFormSheet extends ConsumerStatefulWidget {
  const _EmployeeFormSheet({this.existing});

  final AdminEmployee? existing;

  @override
  ConsumerState<_EmployeeFormSheet> createState() => _EmployeeFormSheetState();
}

class _EmployeeFormSheetState extends ConsumerState<_EmployeeFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  late final TextEditingController _password;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _employeeCode;
  late final TextEditingController _phone;
  late final TextEditingController _hireDate;
  String _role = 'EMPLOYEE';
  String? _departmentId;
  String? _designationId;
  String? _managerId;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final employee = widget.existing;
    _email = TextEditingController(text: employee?.email ?? '');
    _password = TextEditingController();
    _firstName = TextEditingController(text: employee?.firstName ?? '');
    _lastName = TextEditingController(text: employee?.lastName ?? '');
    _employeeCode = TextEditingController(text: employee?.employeeCode ?? '');
    _phone = TextEditingController(text: employee?.phone ?? '');
    _hireDate = TextEditingController(text: _dateOnly(employee?.hireDate));
    _role = employee?.primaryRole ?? 'EMPLOYEE';
    _departmentId = employee?.departmentId;
    _designationId = employee?.designationId;
    _managerId = employee?.managerId;
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _employeeCode.dispose();
    _phone.dispose();
    _hireDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final departments = ref.watch(departmentsProvider);
    final designations = ref.watch(designationsProvider);
    final employees = ref.watch(employeesProvider);
    final roleOptions = _roleOptions(ref.watch(authControllerProvider));

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editing ? 'Edit employee' : 'New employee',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (!_editing) ...[
                const SizedBox(height: 6),
                Text(
                  'Temporary passwords are submitted once and are not shown again.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 16),
              if (!_editing) ...[
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'Temporary password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (value.length < 8) return 'Use at least 8 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _employeeCode,
                decoration: const InputDecoration(labelText: 'Employee code'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone optional'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _hireDate,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Hire date optional',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              if (!_editing) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue:
                      roleOptions.contains(_role) ? _role : 'EMPLOYEE',
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: [
                    for (final role in roleOptions)
                      DropdownMenuItem(
                        value: role,
                        child: Text(roleLabel(role)),
                      ),
                  ],
                  onChanged: (value) =>
                      setState(() => _role = value ?? 'EMPLOYEE'),
                ),
              ],
              const SizedBox(height: 12),
              departments.when(
                loading: () =>
                    const LoadingState(label: 'Loading departments...'),
                error: (error, _) => adminErrorView(
                  error,
                  () => ref.invalidate(departmentsProvider),
                ),
                data: (items) => DropdownButtonFormField<String?>(
                  initialValue: _departmentId,
                  decoration:
                      const InputDecoration(labelText: 'Department optional'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No department'),
                    ),
                    for (final item in items)
                      DropdownMenuItem<String?>(
                        value: item.id,
                        child: Text(item.name),
                      ),
                  ],
                  onChanged: (value) => setState(() => _departmentId = value),
                ),
              ),
              const SizedBox(height: 12),
              designations.when(
                loading: () =>
                    const LoadingState(label: 'Loading designations...'),
                error: (error, _) => adminErrorView(
                  error,
                  () => ref.invalidate(designationsProvider),
                ),
                data: (items) => DropdownButtonFormField<String?>(
                  initialValue: _designationId,
                  decoration:
                      const InputDecoration(labelText: 'Designation optional'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No designation'),
                    ),
                    for (final item in items)
                      DropdownMenuItem<String?>(
                        value: item.id,
                        child: Text(item.title),
                      ),
                  ],
                  onChanged: (value) => setState(() => _designationId = value),
                ),
              ),
              if (!_editing) ...[
                const SizedBox(height: 12),
                employees.when(
                  loading: () =>
                      const LoadingState(label: 'Loading managers...'),
                  error: (error, _) => adminErrorView(
                    error,
                    () => ref.invalidate(employeesProvider),
                  ),
                  data: (items) => DropdownButtonFormField<String?>(
                    initialValue: _managerId,
                    decoration:
                        const InputDecoration(labelText: 'Manager optional'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No manager'),
                      ),
                      for (final item in items)
                        DropdownMenuItem<String?>(
                          value: item.id,
                          child: Text(item.fullName),
                        ),
                    ],
                    onChanged: (value) => setState(() => _managerId = value),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save employee'),
              ),
            ],
          ),
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
        await repo.createEmployee(
          email: _email.text,
          temporaryPassword: _password.text,
          firstName: _firstName.text,
          lastName: _lastName.text,
          employeeCode: _employeeCode.text,
          phone: _phone.text,
          role: _role,
          departmentId: _departmentId,
          designationId: _designationId,
          managerId: _managerId,
          hireDate: _hireDate.text,
        );
      } else {
        await repo.updateEmployee(
          existing.id,
          firstName: _firstName.text,
          lastName: _lastName.text,
          employeeCode: _employeeCode.text,
          phone: _phone.text,
          departmentId: _departmentId,
          designationId: _designationId,
          hireDate: _hireDate.text,
        );
        ref.invalidate(employeeProvider(existing.id));
      }
      ref.invalidate(employeesProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Employee saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _EmployeeStatusSheet extends ConsumerStatefulWidget {
  const _EmployeeStatusSheet({required this.employee});

  final AdminEmployee employee;

  @override
  ConsumerState<_EmployeeStatusSheet> createState() =>
      _EmployeeStatusSheetState();
}

class _EmployeeStatusSheetState extends ConsumerState<_EmployeeStatusSheet> {
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.employee.status;
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
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Employee status'),
            items: [
              for (final status in _employeeStatuses)
                DropdownMenuItem(value: status, child: Text(status)),
            ],
            onChanged: (value) =>
                setState(() => _status = value ?? widget.employee.status),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
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
      await ref.read(adminRepositoryProvider).updateEmployeeStatus(
            widget.employee.id,
            status: _status,
          );
      ref.invalidate(employeesProvider);
      ref.invalidate(employeeProvider(widget.employee.id));
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Employee status updated.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ManagerSheet extends ConsumerStatefulWidget {
  const _ManagerSheet({required this.employee});

  final AdminEmployee employee;

  @override
  ConsumerState<_ManagerSheet> createState() => _ManagerSheetState();
}

class _ManagerSheetState extends ConsumerState<_ManagerSheet> {
  String? _managerId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _managerId = widget.employee.managerId;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Assign manager', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          employees.when(
            loading: () => const LoadingState(label: 'Loading managers...'),
            error: (error, _) => adminErrorView(
              error,
              () => ref.invalidate(employeesProvider),
            ),
            data: (items) {
              final options = items
                  .where((item) => item.id != widget.employee.id)
                  .toList(growable: false);
              return DropdownButtonFormField<String?>(
                initialValue: _managerId,
                decoration: const InputDecoration(labelText: 'Manager'),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('No manager'),
                  ),
                  for (final item in options)
                    DropdownMenuItem<String?>(
                      value: item.id,
                      child: Text(item.fullName),
                    ),
                ],
                onChanged: (value) => setState(() => _managerId = value),
              );
            },
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save manager'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(adminRepositoryProvider).updateEmployeeManager(
            widget.employee.id,
            managerId: _managerId,
          );
      ref.invalidate(employeesProvider);
      ref.invalidate(employeeProvider(widget.employee.id));
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Manager assignment updated.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

List<String> _roleOptions(AuthState auth) {
  if (auth is AuthAuthenticated &&
      auth.user.primaryRole == AppRole.companyAdmin) {
    return const ['EMPLOYEE', 'MANAGER', 'HR_ADMIN', 'COMPANY_ADMIN'];
  }
  return const ['EMPLOYEE', 'MANAGER', 'HR_ADMIN'];
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}

String _dateOnly(String? value) {
  if (value == null || value.isEmpty) return '';
  return value.length >= 10 ? value.substring(0, 10) : value;
}
