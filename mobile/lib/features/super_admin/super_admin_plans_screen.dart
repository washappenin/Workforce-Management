import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'super_admin_models.dart';
import 'super_admin_repository.dart';
import 'widgets/super_admin_widgets.dart';

const _planTypes = ['BASIC', 'PREMIUM'];

class SuperAdminPlansScreen extends ConsumerWidget {
  const SuperAdminPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(superAdminPlansProvider);

    return SuperAdminPage(
      title: 'Plans',
      subtitle: 'Subscription plan records and status.',
      action: IconButton.filled(
        key: const ValueKey('superAdmin.newPlan'),
        tooltip: 'New plan',
        onPressed: () => showPlanSheet(context),
        icon: const Icon(Icons.add_card_outlined),
      ),
      child: plans.when(
        loading: () => const LoadingState(label: 'Loading plans...'),
        error: (error, _) => superAdminErrorView(
          error,
          () => ref.invalidate(superAdminPlansProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.workspace_premium_outlined,
              title: 'No plans',
              message: 'Create a plan before assigning subscriptions.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(superAdminPlansProvider),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final plan = items[index];
                return Card(
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
                                plan.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            StatusChip(
                              label: plan.isActive ? 'ACTIVE' : 'INACTIVE',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        InfoLine(label: 'Type', value: plan.type),
                        InfoLine(
                          label: 'Price',
                          value:
                              '${money(plan.pricePerEmployee, plan.currency)} per employee',
                        ),
                        InfoLine(
                            label: 'Updated', value: shortDate(plan.updatedAt)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                key:
                                    ValueKey('superAdmin.plan.edit.${plan.id}'),
                                onPressed: () =>
                                    showPlanSheet(context, existing: plan),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _togglePlanStatus(context, ref, plan),
                                icon: const Icon(
                                  Icons.published_with_changes_outlined,
                                ),
                                label: Text(
                                  plan.isActive ? 'Deactivate' : 'Activate',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Future<void> _togglePlanStatus(
    BuildContext context,
    WidgetRef ref,
    SuperAdminSubscriptionPlan plan,
  ) async {
    try {
      await ref.read(superAdminRepositoryProvider).updatePlanStatus(
            plan.id,
            isActive: !plan.isActive,
          );
      if (!context.mounted) return;
      ref.invalidate(superAdminPlansProvider);
      showSuperAdminSuccessSnack(context, 'Plan status updated.');
    } catch (error) {
      if (!context.mounted) return;
      showSuperAdminFailureSnack(context, error);
    }
  }
}

Future<void> showPlanSheet(
  BuildContext context, {
  SuperAdminSubscriptionPlan? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PlanFormSheet(existing: existing),
  );
}

class _PlanFormSheet extends ConsumerStatefulWidget {
  const _PlanFormSheet({this.existing});

  final SuperAdminSubscriptionPlan? existing;

  @override
  ConsumerState<_PlanFormSheet> createState() => _PlanFormSheetState();
}

class _PlanFormSheetState extends ConsumerState<_PlanFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _currency;
  late String _type;
  late bool _isActive;
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final plan = widget.existing;
    _name = TextEditingController(text: plan?.name ?? '');
    _price = TextEditingController(
      text: plan == null ? '' : plan.pricePerEmployee.toString(),
    );
    _currency = TextEditingController(text: plan?.currency ?? 'USD');
    _type = plan?.type ?? 'BASIC';
    _isActive = plan?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _currency.dispose();
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _editing ? 'Edit plan' : 'New plan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('superAdmin.planForm.name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Plan name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Plan type'),
                items: [
                  for (final type in _planTypes)
                    DropdownMenuItem(value: type, child: Text(type)),
                ],
                onChanged: (value) => setState(() => _type = value ?? 'BASIC'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price per employee',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null) return 'Enter a number';
                  if (parsed < 0) return 'Must be zero or more';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _currency,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(labelText: 'Currency'),
                validator: (value) =>
                    (value ?? '').trim().length == 3 ? null : 'Use 3 letters',
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isActive,
                title: const Text('Plan active'),
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                key: const ValueKey('superAdmin.planForm.save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save plan'),
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
      final repo = ref.read(superAdminRepositoryProvider);
      final existing = widget.existing;
      if (existing == null) {
        await repo.createPlan(
          name: _name.text,
          type: _type,
          pricePerEmployee: double.parse(_price.text),
          currency: _currency.text,
          isActive: _isActive,
        );
      } else {
        await repo.updatePlan(
          existing.id,
          name: _name.text,
          type: _type,
          pricePerEmployee: double.parse(_price.text),
          currency: _currency.text,
          isActive: _isActive,
        );
      }
      ref.invalidate(superAdminPlansProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuperAdminSuccessSnack(context, 'Plan saved.');
    } catch (error) {
      if (mounted) showSuperAdminFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}
