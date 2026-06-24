import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'employee_repository.dart';
import 'widgets/employee_widgets.dart';

class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(attendanceSessionsProvider);

    return EmployeePage(
      title: 'Attendance',
      subtitle: 'Your clock session history',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(attendanceSessionsProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: sessions.when(
        loading: () => const LoadingState(label: 'Loading attendance...'),
        error: (error, _) => employeeErrorView(
          error,
          () => ref.invalidate(attendanceSessionsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.history_outlined,
              title: 'No attendance yet',
              message: 'Clock sessions will appear here after FE3 is enabled.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(attendanceSessionsProvider);
              await ref.read(attendanceSessionsProvider.future);
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final session = items[index];
                return SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shortDateTime(session.clockInAt),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StatusChip(label: session.status),
                        ],
                      ),
                      const Divider(height: 24),
                      InfoLine(
                        label: 'Clock in',
                        value: shortDateTime(session.clockInAt),
                      ),
                      InfoLine(
                        label: 'Clock out',
                        value: shortDateTime(session.clockOutAt),
                      ),
                      InfoLine(
                        label: 'Face in',
                        value: _verified(session.clockInFaceVerified),
                      ),
                      InfoLine(
                        label: 'Face out',
                        value: _verified(session.clockOutFaceVerified),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  String _verified(bool? value) {
    if (value == null) return 'Not recorded';
    return value ? 'Verified' : 'Not verified';
  }
}
