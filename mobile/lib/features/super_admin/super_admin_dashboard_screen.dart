import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/widgets/states.dart';
import 'super_admin_repository.dart';
import 'widgets/super_admin_widgets.dart';

class SuperAdminDashboardScreen extends ConsumerWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(superAdminDashboardProvider);

    return SuperAdminPage(
      title: 'Platform',
      subtitle: 'Companies, billing, and reports',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(superAdminDashboardProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: dashboard.when(
        loading: () => const LoadingState(label: 'Loading platform...'),
        error: (error, _) => superAdminErrorView(
          error,
          () => ref.invalidate(superAdminDashboardProvider),
        ),
        data: (summary) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(superAdminDashboardProvider);
              await ref.read(superAdminDashboardProvider.future);
            },
            child: ListView(
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform command',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${summary.activeCompanies} active companies of ${summary.totalCompanies}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Divider(height: 28),
                      InfoLine(
                        label: 'Users',
                        value:
                            '${summary.activeUsers} active of ${summary.totalUsers}',
                      ),
                      InfoLine(
                        label: 'Billing',
                        value:
                            '${summary.totalSubscriptions} subscriptions tracked',
                      ),
                      InfoLine(
                        label: 'Recent',
                        value:
                            '${summary.recentCompanyCount} companies in 30 days',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width > 720 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15,
                  children: [
                    MetricTile(
                      label: 'Companies',
                      value: '${summary.totalCompanies}',
                      icon: Icons.business_outlined,
                    ),
                    MetricTile(
                      label: 'Active users',
                      value: '${summary.activeUsers}',
                      icon: Icons.verified_user_outlined,
                    ),
                    MetricTile(
                      label: 'Subscriptions',
                      value: '${summary.totalSubscriptions}',
                      icon: Icons.workspace_premium_outlined,
                    ),
                    MetricTile(
                      label: 'Recent companies',
                      value: '${summary.recentCompanyCount}',
                      icon: Icons.trending_up_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Platform workflows',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      SuperAdminActionRow(
                        key: const ValueKey(
                          'superAdmin.hub./super-admin/companies',
                        ),
                        icon: Icons.business_outlined,
                        title: 'Companies',
                        subtitle: 'Onboard companies and manage status',
                        onTap: () => context.go('/super-admin/companies'),
                      ),
                      SuperAdminActionRow(
                        key: const ValueKey(
                          'superAdmin.hub./super-admin/plans',
                        ),
                        icon: Icons.workspace_premium_outlined,
                        title: 'Plans',
                        subtitle: 'Create and maintain subscription plans',
                        onTap: () => context.go('/super-admin/plans'),
                      ),
                      SuperAdminActionRow(
                        key: const ValueKey(
                          'superAdmin.hub./super-admin/subscriptions',
                        ),
                        icon: Icons.fact_check_outlined,
                        title: 'Subscriptions',
                        subtitle: 'Assign plans and update billing status',
                        onTap: () => context.go('/super-admin/subscriptions'),
                      ),
                      SuperAdminActionRow(
                        key: const ValueKey(
                          'superAdmin.hub./super-admin/payment-records',
                        ),
                        icon: Icons.receipt_long_outlined,
                        title: 'Manual payments',
                        subtitle: 'Record and review payment history',
                        onTap: () => context.go('/super-admin/payment-records'),
                      ),
                      SuperAdminActionRow(
                        key: const ValueKey(
                          'superAdmin.hub./super-admin/reports',
                        ),
                        icon: Icons.bar_chart_outlined,
                        title: 'Reports',
                        subtitle: 'Platform dashboard and company rollups',
                        onTap: () => context.go('/super-admin/reports'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
