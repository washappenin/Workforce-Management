import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'super_admin_repository.dart';
import 'widgets/super_admin_widgets.dart';

class SuperAdminReportsScreen extends ConsumerWidget {
  const SuperAdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(superAdminReportsBundleProvider);

    return SuperAdminPage(
      title: 'Reports',
      subtitle: 'Platform dashboard and company rollups.',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(superAdminReportsBundleProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: reports.when(
        loading: () => const LoadingState(label: 'Loading reports...'),
        error: (error, _) => superAdminErrorView(
          error,
          () => ref.invalidate(superAdminReportsBundleProvider),
        ),
        data: (bundle) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(superAdminReportsBundleProvider);
              await ref.read(superAdminReportsBundleProvider.future);
            },
            child: ListView(
              children: [
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
                      value: '${bundle.dashboard.totalCompanies}',
                      icon: Icons.business_outlined,
                    ),
                    MetricTile(
                      label: 'Active companies',
                      value: '${bundle.dashboard.activeCompanies}',
                      icon: Icons.verified_outlined,
                    ),
                    MetricTile(
                      label: 'Users',
                      value: '${bundle.dashboard.totalUsers}',
                      icon: Icons.people_outline,
                    ),
                    MetricTile(
                      label: 'Subscriptions',
                      value: '${bundle.dashboard.totalSubscriptions}',
                      icon: Icons.workspace_premium_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Company rollups',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      if (bundle.rollups.isEmpty)
                        const Text('No company rollups available.')
                      else
                        for (final company in bundle.rollups) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(company.name),
                            subtitle: Text(
                              '${company.activeEmployeeCount} active employees of ${company.employeeCount}',
                            ),
                            trailing: StatusChip(
                              label:
                                  company.subscriptionStatus ?? company.status,
                            ),
                          ),
                        ],
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
