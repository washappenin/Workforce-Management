import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'manager_repository.dart';
import 'widgets/manager_widgets.dart';

class ManagerAttendanceScreen extends ConsumerWidget {
  const ManagerAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(managerAttendanceReportProvider);

    return ManagerPage(
      title: 'Attendance',
      subtitle: 'Direct-report clock activity',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(managerAttendanceReportProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: report.when(
        loading: () => const LoadingState(label: 'Loading team attendance...'),
        error: (error, _) => managerErrorView(
          error,
          () => ref.invalidate(managerAttendanceReportProvider),
        ),
        data: (summary) {
          if (summary.totalSessions == 0) {
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(managerAttendanceReportProvider),
              child: const ManagerEmptyList(
                icon: Icons.assignment_turned_in_outlined,
                title: 'No team attendance data',
                message:
                    'Clock sessions will appear after your team reports time.',
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(managerAttendanceReportProvider);
              await ref.read(managerAttendanceReportProvider.future);
            },
            child: ListView(
              children: [
                GridView.count(
                  crossAxisCount:
                      MediaQuery.sizeOf(context).width > 720 ? 3 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.18,
                  children: [
                    MetricTile(
                      label: 'Sessions',
                      value: '${summary.totalSessions}',
                      icon: Icons.fact_check_outlined,
                    ),
                    MetricTile(
                      label: 'Open',
                      value: '${summary.openSessions}',
                      icon: Icons.timelapse_outlined,
                    ),
                    MetricTile(
                      label: 'Closed',
                      value: '${summary.closedSessions}',
                      icon: Icons.done_all_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Clock-ins by day',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (summary.clockInsByDay.isEmpty)
                        Text(
                          'No daily clock-in buckets returned.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        )
                      else
                        for (final day in summary.clockInsByDay)
                          InfoLine(label: day.date, value: '${day.count}'),
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
