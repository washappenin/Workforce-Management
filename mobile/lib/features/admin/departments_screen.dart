import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentsProvider);
    return AdminPage(
      title: 'Departments',
      subtitle: 'Company teams and active operating groups.',
      action: IconButton.filled(
        tooltip: 'New department',
        onPressed: () => _showDepartmentSheet(context),
        icon: const Icon(Icons.add),
      ),
      child: departments.when(
        loading: () => const LoadingState(label: 'Loading departments...'),
        error: (error, _) =>
            adminErrorView(error, () => ref.invalidate(departmentsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.account_tree_outlined,
              title: 'No departments',
              message: 'Create a department before assigning employees.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(departmentsProvider),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final department = items[index];
                return Card(
                  child: ListTile(
                    onTap: () =>
                        context.go('/admin/departments/${department.id}'),
                    title: Text(department.name),
                    subtitle: Text(department.id),
                    trailing: StatusPill(
                      label: department.isActive ? 'ACTIVE' : 'INACTIVE',
                      active: department.isActive,
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

class DepartmentDetailScreen extends ConsumerWidget {
  const DepartmentDetailScreen({super.key, required this.departmentId});

  final String departmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final department = ref.watch(departmentProvider(departmentId));
    return AdminPage(
      title: 'Department',
      subtitle: 'Department profile and status.',
      child: department.when(
        loading: () => const LoadingState(label: 'Loading department...'),
        error: (error, _) => adminErrorView(
          error,
          () => ref.invalidate(departmentProvider(departmentId)),
        ),
        data: (item) => ListView(
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
                            item.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        StatusPill(
                          label: item.isActive ? 'ACTIVE' : 'INACTIVE',
                          active: item.isActive,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InfoRow(label: 'Company', value: item.companyId),
                    InfoRow(label: 'Record', value: item.id),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showDepartmentSheet(context, existing: item),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit department'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _toggleDepartmentStatus(context, ref, item),
              icon: Icon(item.isActive
                  ? Icons.pause_circle_outline
                  : Icons.play_circle_outline),
              label: Text(item.isActive ? 'Deactivate' : 'Activate'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showDepartmentSheet(
  BuildContext context, {
  AdminDepartment? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DepartmentFormSheet(existing: existing),
  );
}

Future<void> _toggleDepartmentStatus(
  BuildContext context,
  WidgetRef ref,
  AdminDepartment department,
) async {
  final nextActive = !department.isActive;
  final confirmed = await confirmAction(
    context,
    title: nextActive ? 'Activate department?' : 'Deactivate department?',
    message: nextActive
        ? 'This department can be used for new assignments.'
        : 'Existing records remain intact, but the department is marked inactive.',
    confirmLabel: nextActive ? 'Activate' : 'Deactivate',
  );
  if (!confirmed || !context.mounted) return;
  try {
    await ref.read(adminRepositoryProvider).updateDepartmentStatus(
          department.id,
          isActive: nextActive,
        );
    ref.invalidate(departmentsProvider);
    ref.invalidate(departmentProvider(department.id));
    if (context.mounted) {
      showSuccessSnack(context, 'Department status updated.');
    }
  } catch (error) {
    if (context.mounted) showFailureSnack(context, error);
  }
}

class _DepartmentFormSheet extends ConsumerStatefulWidget {
  const _DepartmentFormSheet({this.existing});

  final AdminDepartment? existing;

  @override
  ConsumerState<_DepartmentFormSheet> createState() =>
      _DepartmentFormSheetState();
}

class _DepartmentFormSheetState extends ConsumerState<_DepartmentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              editing ? 'Edit department' : 'New department',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(labelText: 'Department name'),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null,
              onFieldSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save department'),
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
        await repo.createDepartment(name: _name.text);
      } else {
        await repo.updateDepartment(existing.id, name: _name.text);
        ref.invalidate(departmentProvider(existing.id));
      }
      ref.invalidate(departmentsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Department saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
