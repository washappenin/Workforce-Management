import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'super_admin_models.dart';
import 'super_admin_repository.dart';
import 'widgets/super_admin_widgets.dart';

const _paymentStatuses = ['PENDING', 'PAID', 'FAILED', 'REFUNDED', 'CANCELLED'];

class SuperAdminPaymentsScreen extends ConsumerWidget {
  const SuperAdminPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(superAdminPaymentRecordsProvider(null));

    return SuperAdminPage(
      title: 'Payments',
      subtitle: 'Manual payment records and provider references.',
      action: IconButton.filled(
        key: const ValueKey('superAdmin.newPayment'),
        tooltip: 'Record payment',
        onPressed: () => showPaymentSheet(context),
        icon: const Icon(Icons.receipt_long_outlined),
      ),
      child: payments.when(
        loading: () => const LoadingState(label: 'Loading payments...'),
        error: (error, _) => superAdminErrorView(
          error,
          () => ref.invalidate(superAdminPaymentRecordsProvider(null)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No payment records',
              message: 'Manual payment records will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(superAdminPaymentRecordsProvider(null));
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final payment = items[index];
                return _PaymentCard(payment: payment);
              },
            ),
          );
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});

  final SuperAdminPaymentRecord payment;

  @override
  Widget build(BuildContext context) {
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
                    money(payment.amount, payment.currency),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StatusChip(label: payment.status),
              ],
            ),
            const SizedBox(height: 10),
            InfoLine(
              label: 'Company',
              value: payment.company?.name ?? payment.companyId,
            ),
            InfoLine(label: 'Provider', value: payment.provider ?? 'Manual'),
            InfoLine(
              label: 'Reference',
              value: payment.providerReference ?? 'Not set',
            ),
            InfoLine(label: 'Paid', value: shortDate(payment.paidAt)),
            if (payment.subscription?.plan != null)
              InfoLine(
                label: 'Plan',
                value: payment.subscription!.plan!.name,
              ),
          ],
        ),
      ),
    );
  }
}

Future<void> showPaymentSheet(
  BuildContext context, {
  String? initialCompanyId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _PaymentFormSheet(initialCompanyId: initialCompanyId),
  );
}

class _PaymentFormSheet extends ConsumerStatefulWidget {
  const _PaymentFormSheet({this.initialCompanyId});

  final String? initialCompanyId;

  @override
  ConsumerState<_PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<_PaymentFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _currency;
  late final TextEditingController _provider;
  late final TextEditingController _providerReference;
  late final TextEditingController _paidAt;
  String? _companyId;
  String? _subscriptionId;
  String _status = 'PAID';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _companyId = widget.initialCompanyId;
    _amount = TextEditingController();
    _currency = TextEditingController(text: 'USD');
    _provider = TextEditingController(text: 'Manual');
    _providerReference = TextEditingController();
    _paidAt = TextEditingController(
      text: DateTime.now().toIso8601String().substring(0, 10),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _currency.dispose();
    _provider.dispose();
    _providerReference.dispose();
    _paidAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final companies = ref.watch(superAdminCompaniesProvider);
    final subscriptions = ref.watch(superAdminSubscriptionsProvider(null));

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
                'Record payment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              companies.when(
                loading: () =>
                    const LoadingState(label: 'Loading companies...'),
                error: (error, _) => superAdminErrorView(
                  error,
                  () => ref.invalidate(superAdminCompaniesProvider),
                ),
                data: (items) {
                  final selection = _selectionOrNull(
                    _companyId,
                    items.map((item) => item.id),
                  );
                  if (_companyId != selection) _companyId = selection;
                  return DropdownButtonFormField<String>(
                    key: const ValueKey('superAdmin.paymentForm.company'),
                    initialValue: selection,
                    decoration: const InputDecoration(labelText: 'Company'),
                    items: [
                      for (final company in items)
                        DropdownMenuItem(
                          value: company.id,
                          child: Text(company.name),
                        ),
                    ],
                    onChanged: (value) => setState(() {
                      _companyId = value;
                      _subscriptionId = null;
                    }),
                    validator: _required,
                  );
                },
              ),
              const SizedBox(height: 12),
              subscriptions.when(
                loading: () =>
                    const LoadingState(label: 'Loading subscriptions...'),
                error: (error, _) => superAdminErrorView(
                  error,
                  () => ref.invalidate(superAdminSubscriptionsProvider(null)),
                ),
                data: (items) {
                  final scoped = items
                      .where((item) => item.companyId == _companyId)
                      .toList(growable: false);
                  final selection = _selectionOrNull(
                    _subscriptionId,
                    scoped.map((item) => item.id),
                  );
                  if (_subscriptionId != selection) _subscriptionId = selection;
                  return DropdownButtonFormField<String?>(
                    key: const ValueKey('superAdmin.paymentForm.subscription'),
                    initialValue: selection,
                    decoration: const InputDecoration(
                      labelText: 'Subscription optional',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No subscription link'),
                      ),
                      for (final subscription in scoped)
                        DropdownMenuItem<String?>(
                          value: subscription.id,
                          child: Text(
                            '${subscription.plan?.name ?? subscription.planId} - ${subscription.status}',
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _subscriptionId = value),
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('superAdmin.paymentForm.amount'),
                controller: _amount,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount'),
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
              DropdownButtonFormField<String>(
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  for (final status in _paymentStatuses)
                    DropdownMenuItem(value: status, child: Text(status)),
                ],
                onChanged: (value) => setState(() => _status = value ?? 'PAID'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _provider,
                decoration: const InputDecoration(labelText: 'Provider'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _providerReference,
                decoration:
                    const InputDecoration(labelText: 'Provider reference'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _paidAt,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Paid at optional',
                  hintText: 'YYYY-MM-DD',
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                key: const ValueKey('superAdmin.paymentForm.save'),
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving...' : 'Record payment'),
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
      await ref.read(superAdminRepositoryProvider).createPaymentRecord(
            companyId: _companyId!,
            amount: double.parse(_amount.text),
            currency: _currency.text,
            status: _status,
            subscriptionId: _subscriptionId,
            provider: _provider.text,
            providerReference: _providerReference.text,
            paidAt: _paidAt.text,
          );
      ref.invalidate(superAdminPaymentRecordsProvider(null));
      if (_companyId != null) {
        ref.invalidate(superAdminPaymentRecordsProvider(_companyId));
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      showSuperAdminSuccessSnack(context, 'Payment recorded.');
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
