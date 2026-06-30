import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'super_admin_models.dart';
import 'super_admin_repository.dart';
import 'widgets/super_admin_widgets.dart';

const _subscriptionStatuses = [
  'TRIALING',
  'ACTIVE',
  'PAST_DUE',
  'CANCELLED',
  'EXPIRED',
];

class SuperAdminSubscriptionsScreen extends ConsumerWidget {
  const SuperAdminSubscriptionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(superAdminSubscriptionsProvider(null));

    return SuperAdminPage(
      title: 'Subscriptions',
      subtitle: 'Company plan assignment and billing status.',
      action: IconButton.filled(
        key: const ValueKey('superAdmin.newSubscription'),
        tooltip: 'Assign plan',
        onPressed: () => showSubscriptionSheet(context),
        icon: const Icon(Icons.add_card_outlined),
      ),
      child: subscriptions.when(
        loading: () => const LoadingState(label: 'Loading subscriptions...'),
        error: (error, _) => superAdminErrorView(
          error,
          () => ref.invalidate(superAdminSubscriptionsProvider(null)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'No subscriptions',
              message: 'Assign a plan to a company to start billing records.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(superAdminSubscriptionsProvider(null));
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final subscription = items[index];
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
                                subscription.company?.name ??
                                    subscription.companyId,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            StatusChip(label: subscription.status),
                          ],
                        ),
                        const SizedBox(height: 10),
                        InfoLine(
                          label: 'Plan',
                          value: subscription.plan?.name ?? subscription.planId,
                        ),
                        InfoLine(
                          label: 'Started',
                          value: shortDate(subscription.startsAt),
                        ),
                        InfoLine(
                          label: 'Ends',
                          value: shortDate(subscription.endsAt),
                        ),
                        if (subscription.plan != null)
                          InfoLine(
                            label: 'Price',
                            value:
                                '${money(subscription.plan!.pricePerEmployee, subscription.plan!.currency)} per employee',
                          ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: ValueKey(
                            'superAdmin.subscription.status.${subscription.id}',
                          ),
                          onPressed: () => _showSubscriptionStatusSheet(
                            context,
                            subscription,
                          ),
                          icon: const Icon(
                            Icons.published_with_changes_outlined,
                          ),
                          label: const Text('Change status'),
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
}

Future<void> showSubscriptionSheet(
  BuildContext context, {
  String? initialCompanyId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SubscriptionFormSheet(initialCompanyId: initialCompanyId),
  );
}

Future<void> _showSubscriptionStatusSheet(
  BuildContext context,
  SuperAdminCompanySubscription subscription,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _SubscriptionStatusSheet(subscription: subscription),
  );
}

class _SubscriptionFormSheet extends ConsumerStatefulWidget {
  const _SubscriptionFormSheet({this.initialCompanyId});

  final String? initialCompanyId;

  @override
  ConsumerState<_SubscriptionFormSheet> createState() =>
      _SubscriptionFormSheetState();
}

class _SubscriptionFormSheetState
    extends ConsumerState<_SubscriptionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _startsAt;
  late final TextEditingController _endsAt;
  String? _companyId;
  String? _planId;
  String _status = 'ACTIVE';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _companyId = widget.initialCompanyId;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    _startsAt = TextEditingController(text: today);
    _endsAt = TextEditingController();
  }

  @override
  void dispose() {
    _startsAt.dispose();
    _endsAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(superAdminCompaniesProvider);
    final plans = ref.watch(superAdminPlansProvider);

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
              Text('Assign subscription',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              companies.when(
                loading: () =>
                    const LoadingState(label: 'Loading companies...'),
                error: (error, _) => superAdminErrorView(
                  error,
                  () => ref.invalidate(superAdminCompaniesProvider),
                ),
                data: (items) {
                  final active = items
                      .where((company) => company.status == 'ACTIVE')
                      .toList(growable: false);
                  final selection = _selectionOrNull(
                    _companyId,
                    active.map((item) => item.id),
                  );
                  if (_companyId != selection) _companyId = selection;
                  return DropdownButtonFormField<String>(
                    key: const ValueKey('superAdmin.subscriptionForm.company'),
                    initialValue: selection,
                    decoration: const InputDecoration(labelText: 'Company'),
                    items: [
                      for (final company in active)
                        DropdownMenuItem(
                          value: company.id,
                          child: Text(company.name),
                        ),
                    ],
                    onChanged: (value) => setState(() => _companyId = value),
                    validator: _required,
                  );
                },
              ),
              const SizedBox(height: 12),
              plans.when(
                loading: () => const LoadingState(label: 'Loading plans...'),
                error: (error, _) => superAdminErrorView(
                  error,
                  () => ref.invalidate(superAdminPlansProvider),
                ),
                data: (items) {
                  final active = items
                      .where((plan) => plan.isActive)
                      .toList(growable: false);
                  final selection = _selectionOrNull(
                    _planId,
                    active.map((item) => item.id),
                  );
                  if (_planId != selection) _planId = selection;
                  return DropdownButtonFormField<String>(
                    key: const ValueKey('superAdmin.subscriptionForm.plan'),
                    initialValue: selection,
                    decoration: const InputDecoration(labelText: 'Plan'),
                    items: [
                      for (final plan in active)
                        DropdownMenuItem(
                          value: plan.id,
                          child: Text('${plan.name} - ${plan.type}'),
                        ),
                    ],
                    onChanged: (value) => setState(() => _planId = value),
                    validator: _required,
                  );
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final status in _subscriptionStatuses)
                    DropdownMenuItem(value: status, child: Text(status)),
                ],
                onChanged: (value) =>
                    setState(() => _status = value ?? 'ACTIVE'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startsAt,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Starts at',
                  hintText: 'YYYY-MM-DD',
                ),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _endsAt,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Ends at optional',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                key: const ValueKey('superAdmin.subscriptionForm.save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Assign subscription'),
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
      await ref.read(superAdminRepositoryProvider).createCompanySubscription(
            companyId: _companyId!,
            planId: _planId!,
            startsAt: _startsAt.text,
            endsAt: _endsAt.text,
            status: _status,
          );
      ref.invalidate(superAdminSubscriptionsProvider(null));
      ref.invalidate(superAdminCompanySubscriptionProvider(_companyId!));
      ref.invalidate(superAdminDashboardProvider);
      ref.invalidate(superAdminCompanyRollupsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuperAdminSuccessSnack(context, 'Subscription assigned.');
    } catch (error) {
      if (mounted) showSuperAdminFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SubscriptionStatusSheet extends ConsumerStatefulWidget {
  const _SubscriptionStatusSheet({required this.subscription});

  final SuperAdminCompanySubscription subscription;

  @override
  ConsumerState<_SubscriptionStatusSheet> createState() =>
      _SubscriptionStatusSheetState();
}

class _SubscriptionStatusSheetState
    extends ConsumerState<_SubscriptionStatusSheet> {
  late String _status;
  late final TextEditingController _endsAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.subscription.status;
    _endsAt =
        TextEditingController(text: shortDate(widget.subscription.endsAt));
  }

  @override
  void dispose() {
    _endsAt.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Change status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Subscription status'),
            items: [
              for (final status in _subscriptionStatuses)
                DropdownMenuItem(value: status, child: Text(status)),
            ],
            onChanged: (value) =>
                setState(() => _status = value ?? widget.subscription.status),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _endsAt,
            keyboardType: TextInputType.datetime,
            decoration: const InputDecoration(
              labelText: 'Ends at optional',
              hintText: 'YYYY-MM-DD',
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            key: const ValueKey('superAdmin.subscriptionStatus.save'),
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
      await ref.read(superAdminRepositoryProvider).updateSubscriptionStatus(
            widget.subscription.id,
            status: _status,
            endsAt: _endsAt.text,
          );
      ref.invalidate(superAdminSubscriptionsProvider(null));
      ref.invalidate(
        superAdminCompanySubscriptionProvider(widget.subscription.companyId),
      );
      ref.invalidate(superAdminCompanyRollupsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuperAdminSuccessSnack(context, 'Subscription status updated.');
    } catch (error) {
      if (mounted) showSuperAdminFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

String? _selectionOrNull(String? value, Iterable<String> options) {
  if (value == null || value.isEmpty) return null;
  return options.contains(value) ? value : null;
}

String? _required(String? value) {
  return value == null || value.trim().isEmpty ? 'Required' : null;
}
