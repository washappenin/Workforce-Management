import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

class DesignationsScreen extends ConsumerWidget {
  const DesignationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designations = ref.watch(designationsProvider);
    final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
    final departmentNames = {
      for (final department in departments) department.id: department.name,
    };
    return AdminPage(
      title: 'Designations',
      subtitle: 'Role titles and optional department mapping.',
      action: IconButton.filled(
        tooltip: 'New designation',
        onPressed: () => _showDesignationSheet(context),
        icon: const Icon(Icons.add),
      ),
      child: designations.when(
        loading: () => const LoadingState(label: 'Loading designations...'),
        error: (error, _) =>
            adminErrorView(error, () => ref.invalidate(designationsProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.badge_outlined,
              title: 'No designations',
              message: 'Create job titles before assigning employee roles.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(designationsProvider);
              ref.invalidate(departmentsProvider);
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final designation = items[index];
                final departmentName =
                    departmentNames[designation.departmentId] ?? 'Unassigned';
                return Card(
                  child: ListTile(
                    onTap: () =>
                        context.go('/admin/designations/${designation.id}'),
                    title: Text(designation.title),
                    subtitle: Text(departmentName),
                    trailing: StatusPill(
                      label: designation.isActive ? 'ACTIVE' : 'INACTIVE',
                      active: designation.isActive,
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

class DesignationDetailScreen extends ConsumerWidget {
  const DesignationDetailScreen({super.key, required this.designationId});

  final String designationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final designation = ref.watch(designationProvider(designationId));
    final departments = ref.watch(departmentsProvider).valueOrNull ?? const [];
    final departmentNames = {
      for (final department in departments) department.id: department.name,
    };
    return AdminPage(
      title: 'Designation',
      subtitle: 'Designation profile and status.',
      child: designation.when(
        loading: () => const LoadingState(label: 'Loading designation...'),
        error: (error, _) => adminErrorView(
          error,
          () => ref.invalidate(designationProvider(designationId)),
        ),
        data: (item) {
          final departmentName =
              departmentNames[item.departmentId] ?? 'Unassigned';
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
                              item.title,
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
                      InfoRow(label: 'Department', value: departmentName),
                      InfoRow(label: 'Company', value: item.companyId),
                      InfoRow(label: 'Record', value: item.id),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showDesignationSheet(context, existing: item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit designation'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _toggleDesignationStatus(context, ref, item),
                icon: Icon(item.isActive
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline),
                label: Text(item.isActive ? 'Deactivate' : 'Activate'),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showDesignationSheet(
  BuildContext context, {
  AdminDesignation? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _DesignationFormSheet(existing: existing),
  );
}

Future<void> _toggleDesignationStatus(
  BuildContext context,
  WidgetRef ref,
  AdminDesignation designation,
) async {
  final nextActive = !designation.isActive;
  final confirmed = await confirmAction(
    context,
    title: nextActive ? 'Activate designation?' : 'Deactivate designation?',
    message: nextActive
        ? 'This designation can be used for employee assignments.'
        : 'Existing records remain intact, but the designation is marked inactive.',
    confirmLabel: nextActive ? 'Activate' : 'Deactivate',
  );
  if (!confirmed || !context.mounted) return;
  try {
    await ref.read(adminRepositoryProvider).updateDesignationStatus(
          designation.id,
          isActive: nextActive,
        );
    ref.invalidate(designationsProvider);
    ref.invalidate(designationProvider(designation.id));
    if (context.mounted) {
      showSuccessSnack(context, 'Designation status updated.');
    }
  } catch (error) {
    if (context.mounted) showFailureSnack(context, error);
  }
}

class _DesignationFormSheet extends ConsumerStatefulWidget {
  const _DesignationFormSheet({this.existing});

  final AdminDesignation? existing;

  @override
  ConsumerState<_DesignationFormSheet> createState() =>
      _DesignationFormSheetState();
}

class _DesignationFormSheetState extends ConsumerState<_DesignationFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  String? _departmentId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.existing?.title ?? '');
    _departmentId = widget.existing?.departmentId;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final departments = ref.watch(departmentsProvider);
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
                editing ? 'Edit designation' : 'New designation',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
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
                      child: Text('Unassigned'),
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
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save designation'),
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
        await repo.createDesignation(
          title: _title.text,
          departmentId: _departmentId,
        );
      } else {
        await repo.updateDesignation(
          existing.id,
          title: _title.text,
          departmentId: _departmentId,
        );
        ref.invalidate(designationProvider(existing.id));
      }
      ref.invalidate(designationsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuccessSnack(context, 'Designation saved.');
    } catch (error) {
      if (mounted) showFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
