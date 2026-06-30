import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

class AdminBillingScreen extends ConsumerStatefulWidget {
  const AdminBillingScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  ConsumerState<AdminBillingScreen> createState() => _AdminBillingScreenState();
}

class _AdminBillingScreenState extends ConsumerState<AdminBillingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminPage(
      title: 'Billing',
      subtitle: 'Subscription and payment history.',
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                key: ValueKey('admin.billing.tab.subscription'),
                text: 'Subscription',
              ),
              Tab(
                key: ValueKey('admin.billing.tab.payments'),
                text: 'Payments',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _SubscriptionTab(),
                _PaymentRecordsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionTab extends ConsumerWidget {
  const _SubscriptionTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscription = ref.watch(adminSubscriptionProvider);

    return subscription.when(
      loading: () => const LoadingState(label: 'Loading subscription...'),
      error: (error, _) => adminErrorView(
        error,
        () => ref.invalidate(adminSubscriptionProvider),
      ),
      data: (item) {
        if (item == null) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminSubscriptionProvider),
            child: ListView(
              children: const [
                EmptyState(
                  icon: Icons.workspace_premium_outlined,
                  title: 'No subscription found',
                  message:
                      'Your current or latest subscription will appear here.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminSubscriptionProvider),
          child: ListView(
            children: [
              _SubscriptionCard(subscription: item),
            ],
          ),
        );
      },
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  const _SubscriptionCard({required this.subscription});

  final AdminCompanySubscription subscription;

  @override
  Widget build(BuildContext context) {
    final plan = subscription.plan;
    return Card(
      key: const ValueKey('admin.billing.subscription.card'),
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
                    plan?.name ?? 'Company subscription',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StatusPill(
                  label: subscription.status,
                  active: subscription.isCurrent,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (plan != null) ...[
              InfoRow(label: 'Plan type', value: plan.type),
              InfoRow(
                label: 'Price',
                value:
                    '${_money(plan.pricePerEmployee)} ${plan.currency} per employee',
              ),
              InfoRow(
                label: 'Plan active',
                value: plan.isActive ? 'Active' : 'Inactive',
              ),
            ],
            InfoRow(label: 'Started', value: _dateOnly(subscription.startsAt)),
            InfoRow(
              label: 'Ends',
              value: subscription.endsAt == null
                  ? 'No end date'
                  : _dateOnly(subscription.endsAt),
            ),
            InfoRow(label: 'Updated', value: _dateTime(subscription.updatedAt)),
          ],
        ),
      ),
    );
  }
}

class _PaymentRecordsTab extends ConsumerWidget {
  const _PaymentRecordsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(adminPaymentRecordsProvider);

    return payments.when(
      loading: () => const LoadingState(label: 'Loading payment history...'),
      error: (error, _) => adminErrorView(
        error,
        () => ref.invalidate(adminPaymentRecordsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(adminPaymentRecordsProvider),
            child: ListView(
              children: const [
                EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No payment records',
                  message: 'Manual payment records will appear here.',
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminPaymentRecordsProvider),
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final payment = items[index];
              return _PaymentRecordCard(payment: payment);
            },
          ),
        );
      },
    );
  }
}

class _PaymentRecordCard extends StatelessWidget {
  const _PaymentRecordCard({required this.payment});

  final AdminPaymentRecord payment;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: ValueKey('admin.billing.payment.${payment.id}'),
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
                    '${_money(payment.amount)} ${payment.currency}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StatusPill(
                  label: payment.status,
                  active: payment.status == 'PAID',
                ),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(
              label: 'Provider',
              value: payment.provider ?? 'Manual',
            ),
            InfoRow(label: 'Paid', value: _dateTime(payment.paidAt)),
            InfoRow(label: 'Created', value: _dateTime(payment.createdAt)),
            if (payment.subscription?.plan != null)
              InfoRow(
                label: 'Plan',
                value: payment.subscription!.plan!.name,
              ),
          ],
        ),
      ),
    );
  }
}

String _money(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

String _dateOnly(String? value) {
  if (value == null || value.isEmpty) return 'Not recorded';
  return value.length >= 10 ? value.substring(0, 10) : value;
}

String _dateTime(String? value) {
  if (value == null || value.isEmpty) return 'Not recorded';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return parsed.toLocal().toString().split('.').first;
}
