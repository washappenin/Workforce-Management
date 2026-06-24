import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'employee_repository.dart';
import 'widgets/employee_widgets.dart';

class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shifts = ref.watch(shiftAssignmentsProvider);

    return EmployeePage(
      title: 'My shifts',
      subtitle: 'Current and upcoming assignments',
      action: IconButton.outlined(
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(shiftAssignmentsProvider),
        icon: const Icon(Icons.refresh),
      ),
      child: shifts.when(
        loading: () => const LoadingState(label: 'Loading shifts...'),
        error: (error, _) => employeeErrorView(
          error,
          () => ref.invalidate(shiftAssignmentsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No shifts assigned',
              message: 'Assigned shifts will appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(shiftAssignmentsProvider);
              await ref.read(shiftAssignmentsProvider.future);
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final assignment = items[index];
                return SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              assignment.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          if (assignment.shift != null)
                            StatusChip(label: assignment.shift!.status),
                        ],
                      ),
                      const Divider(height: 24),
                      InfoLine(label: 'Time', value: assignment.timeRange),
                      InfoLine(
                        label: 'Starts',
                        value: shortDate(assignment.startsOn),
                      ),
                      InfoLine(
                        label: 'Ends',
                        value: shortDate(assignment.endsOn),
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
}
