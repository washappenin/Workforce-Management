import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/states.dart';
import 'super_admin_models.dart';
import 'super_admin_payments_screen.dart';
import 'super_admin_repository.dart';
import 'super_admin_subscriptions_screen.dart';
import 'widgets/super_admin_widgets.dart';

const _companyStatuses = ['ACTIVE', 'INACTIVE', 'SUSPENDED'];

class SuperAdminCompaniesScreen extends ConsumerStatefulWidget {
  const SuperAdminCompaniesScreen({super.key});

  @override
  ConsumerState<SuperAdminCompaniesScreen> createState() =>
      _SuperAdminCompaniesScreenState();
}

class _SuperAdminCompaniesScreenState
    extends ConsumerState<SuperAdminCompaniesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(superAdminCompaniesProvider);

    return SuperAdminPage(
      title: 'Companies',
      subtitle: 'Onboarding, profile, and lifecycle status.',
      action: IconButton.filled(
        key: const ValueKey('superAdmin.newCompany'),
        tooltip: 'New company',
        onPressed: () => _showCompanyFormSheet(context),
        icon: const Icon(Icons.add_business_outlined),
      ),
      child: companies.when(
        loading: () => const LoadingState(label: 'Loading companies...'),
        error: (error, _) => superAdminErrorView(
          error,
          () => ref.invalidate(superAdminCompaniesProvider),
        ),
        data: (items) {
          final term = _search.text.trim().toLowerCase();
          final filtered = term.isEmpty
              ? items
              : items.where((item) {
                  return [
                    item.name,
                    item.status,
                    item.contactEmail,
                    item.billingEmail,
                    item.country,
                  ].whereType<String>().join(' ').toLowerCase().contains(term);
                }).toList(growable: false);

          return Column(
            children: [
              TextField(
                controller: _search,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search companies',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty
                    ? const EmptyState(
                        icon: Icons.business_outlined,
                        title: 'No companies',
                        message: 'Create a company before assigning a plan.',
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(superAdminCompaniesProvider);
                        },
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final company = filtered[index];
                            return Card(
                              child: ListTile(
                                key: ValueKey(
                                  'superAdmin.company.${company.id}',
                                ),
                                onTap: () => context.go(
                                  '/super-admin/companies/${company.id}',
                                ),
                                title: Text(company.name),
                                subtitle: Text(
                                  company.contactEmail ??
                                      company.billingEmail ??
                                      company.country ??
                                      'No contact profile',
                                ),
                                trailing: StatusChip(
                                  label: company.status,
                                  color: statusColor(company.status),
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

class SuperAdminCompanyDetailScreen extends ConsumerWidget {
  const SuperAdminCompanyDetailScreen({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(superAdminCompanyProvider(companyId));
    final subscription = ref.watch(
      superAdminCompanySubscriptionProvider(companyId),
    );
    final payments = ref.watch(superAdminPaymentRecordsProvider(companyId));

    return SuperAdminPage(
      title: 'Company',
      subtitle: 'Profile, billing context, and payment history.',
      child: company.when(
        loading: () => const LoadingState(label: 'Loading company...'),
        error: (error, _) => superAdminErrorView(
          error,
          () => ref.invalidate(superAdminCompanyProvider(companyId)),
        ),
        data: (item) {
          return ListView(
            children: [
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        StatusChip(label: item.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InfoLine(
                      label: 'Contact',
                      value: item.contactEmail ?? 'Not set',
                    ),
                    InfoLine(
                      label: 'Billing',
                      value: item.billingEmail ?? 'Not set',
                    ),
                    InfoLine(
                      label: 'Phone',
                      value: item.contactPhone ?? 'Not set',
                    ),
                    InfoLine(
                      label: 'Country',
                      value: item.country ?? 'Not set',
                    ),
                    InfoLine(
                      label: 'Timezone',
                      value: item.timezone ?? 'Not set',
                    ),
                    InfoLine(
                        label: 'Created', value: shortDate(item.createdAt)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                key: const ValueKey('superAdmin.company.edit'),
                onPressed: () => _showCompanyFormSheet(context, existing: item),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit company'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                key: const ValueKey('superAdmin.company.status'),
                onPressed: () => _showCompanyStatusSheet(context, item),
                icon: const Icon(Icons.published_with_changes_outlined),
                label: const Text('Change status'),
              ),
              const SizedBox(height: 12),
              _CompanySubscriptionCard(
                companyId: companyId,
                subscription: subscription,
              ),
              const SizedBox(height: 12),
              _CompanyPaymentRecordsCard(
                  companyId: companyId, payments: payments),
            ],
          );
        },
      ),
    );
  }
}

class _CompanySubscriptionCard extends ConsumerWidget {
  const _CompanySubscriptionCard({
    required this.companyId,
    required this.subscription,
  });

  final String companyId;
  final AsyncValue<SuperAdminCompanySubscription?> subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      child: subscription.when(
        loading: () => const LoadingState(label: 'Loading subscription...'),
        error: (error, _) => superAdminErrorView(
          error,
          () =>
              ref.invalidate(superAdminCompanySubscriptionProvider(companyId)),
        ),
        data: (item) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Company subscription',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.outlined(
                    key: const ValueKey('superAdmin.company.assignPlan'),
                    tooltip: 'Assign plan',
                    onPressed: () => showSubscriptionSheet(
                      context,
                      initialCompanyId: companyId,
                    ),
                    icon: const Icon(Icons.add_card_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (item == null)
                const Text('No current or historical subscription.')
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(item.plan?.name ?? item.planId),
                    ),
                    StatusChip(label: item.status),
                  ],
                ),
                InfoLine(label: 'Started', value: shortDate(item.startsAt)),
                InfoLine(label: 'Ends', value: shortDate(item.endsAt)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _CompanyPaymentRecordsCard extends ConsumerWidget {
  const _CompanyPaymentRecordsCard({
    required this.companyId,
    required this.payments,
  });

  final String companyId;
  final AsyncValue<List<SuperAdminPaymentRecord>> payments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      child: payments.when(
        loading: () => const LoadingState(label: 'Loading payments...'),
        error: (error, _) => superAdminErrorView(
          error,
          () => ref.invalidate(superAdminPaymentRecordsProvider(companyId)),
        ),
        data: (items) {
          final recent = items.take(3).toList(growable: false);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Company payments',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton.outlined(
                    key: const ValueKey('superAdmin.company.recordPayment'),
                    tooltip: 'Record payment',
                    onPressed: () => showPaymentSheet(
                      context,
                      initialCompanyId: companyId,
                    ),
                    icon: const Icon(Icons.receipt_long_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const Text('No manual payment records for this company.')
              else
                for (final item in recent) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(money(item.amount, item.currency)),
                    subtitle: Text(item.provider ?? 'Manual'),
                    trailing: StatusChip(label: item.status),
                  ),
                ],
            ],
          );
        },
      ),
    );
  }
}

Future<void> _showCompanyFormSheet(
  BuildContext context, {
  SuperAdminCompany? existing,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CompanyFormSheet(existing: existing),
  );
}

Future<void> _showCompanyStatusSheet(
  BuildContext context,
  SuperAdminCompany company,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _CompanyStatusSheet(company: company),
  );
}

class _CompanyFormSheet extends ConsumerStatefulWidget {
  const _CompanyFormSheet({this.existing});

  final SuperAdminCompany? existing;

  @override
  ConsumerState<_CompanyFormSheet> createState() => _CompanyFormSheetState();
}

class _CompanyFormSheetState extends ConsumerState<_CompanyFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _contactEmail;
  late final TextEditingController _contactPhone;
  late final TextEditingController _billingEmail;
  late final TextEditingController _address;
  late final TextEditingController _country;
  late final TextEditingController _timezone;
  String _status = 'ACTIVE';
  bool _saving = false;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final company = widget.existing;
    _name = TextEditingController(text: company?.name ?? '');
    _contactEmail = TextEditingController(text: company?.contactEmail ?? '');
    _contactPhone = TextEditingController(text: company?.contactPhone ?? '');
    _billingEmail = TextEditingController(text: company?.billingEmail ?? '');
    _address = TextEditingController(text: company?.address ?? '');
    _country = TextEditingController(text: company?.country ?? '');
    _timezone = TextEditingController(text: company?.timezone ?? '');
    _status = company?.status ?? 'ACTIVE';
  }

  @override
  void dispose() {
    _name.dispose();
    _contactEmail.dispose();
    _contactPhone.dispose();
    _billingEmail.dispose();
    _address.dispose();
    _country.dispose();
    _timezone.dispose();
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
                _editing ? 'Edit company' : 'New company',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const ValueKey('superAdmin.companyForm.name'),
                controller: _name,
                decoration: const InputDecoration(labelText: 'Company name'),
                validator: _required,
              ),
              if (!_editing) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    for (final status in _companyStatuses)
                      DropdownMenuItem(value: status, child: Text(status)),
                  ],
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'ACTIVE'),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Contact email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _billingEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Billing email'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactPhone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact phone'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _country,
                decoration: const InputDecoration(labelText: 'Country'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timezone,
                decoration: const InputDecoration(labelText: 'Timezone'),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                key: const ValueKey('superAdmin.companyForm.save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Save company'),
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
        await repo.createCompany(
          name: _name.text,
          status: _status,
          contactEmail: _contactEmail.text,
          contactPhone: _contactPhone.text,
          billingEmail: _billingEmail.text,
          address: _address.text,
          country: _country.text,
          timezone: _timezone.text,
        );
      } else {
        await repo.updateCompany(
          existing.id,
          name: _name.text,
          contactEmail: _contactEmail.text,
          contactPhone: _contactPhone.text,
          billingEmail: _billingEmail.text,
          address: _address.text,
          country: _country.text,
          timezone: _timezone.text,
        );
        ref.invalidate(superAdminCompanyProvider(existing.id));
      }
      ref.invalidate(superAdminCompaniesProvider);
      ref.invalidate(superAdminDashboardProvider);
      ref.invalidate(superAdminCompanyRollupsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuperAdminSuccessSnack(context, 'Company saved.');
    } catch (error) {
      if (mounted) showSuperAdminFailureSnack(context, error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _CompanyStatusSheet extends ConsumerStatefulWidget {
  const _CompanyStatusSheet({required this.company});

  final SuperAdminCompany company;

  @override
  ConsumerState<_CompanyStatusSheet> createState() =>
      _CompanyStatusSheetState();
}

class _CompanyStatusSheetState extends ConsumerState<_CompanyStatusSheet> {
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.company.status;
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
            decoration: const InputDecoration(labelText: 'Company status'),
            items: [
              for (final status in _companyStatuses)
                DropdownMenuItem(value: status, child: Text(status)),
            ],
            onChanged: (value) =>
                setState(() => _status = value ?? widget.company.status),
          ),
          const SizedBox(height: 18),
          ElevatedButton(
            key: const ValueKey('superAdmin.companyStatus.save'),
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
      await ref.read(superAdminRepositoryProvider).updateCompanyStatus(
            widget.company.id,
            status: _status,
          );
      ref.invalidate(superAdminCompaniesProvider);
      ref.invalidate(superAdminCompanyProvider(widget.company.id));
      ref.invalidate(superAdminDashboardProvider);
      ref.invalidate(superAdminCompanyRollupsProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuperAdminSuccessSnack(context, 'Company status updated.');
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
