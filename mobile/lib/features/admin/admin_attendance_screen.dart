import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import 'admin_models.dart';
import 'admin_repository.dart';
import 'widgets/admin_widgets.dart';

class AdminAttendanceScreen extends ConsumerStatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  ConsumerState<AdminAttendanceScreen> createState() =>
      _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends ConsumerState<AdminAttendanceScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final attendance = ref.watch(adminAttendanceProvider(_status));
    return AdminPage(
      title: 'Attendance',
      subtitle: 'Company clock sessions and verification status.',
      action: IconButton.outlined(
        key: const ValueKey('admin.attendance.refresh'),
        tooltip: 'Refresh',
        onPressed: () => ref.invalidate(adminAttendanceProvider(_status)),
        icon: const Icon(Icons.refresh),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String?>(
            key: const ValueKey('admin.attendance.statusFilter'),
            initialValue: _status,
            decoration: const InputDecoration(labelText: 'Status filter'),
            items: const [
              DropdownMenuItem<String?>(
                value: null,
                child: Text('All sessions'),
              ),
              DropdownMenuItem(value: 'OPEN', child: Text('Open')),
              DropdownMenuItem(value: 'CLOSED', child: Text('Closed')),
              DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
            ],
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: attendance.when(
              loading: () =>
                  const LoadingState(label: 'Loading attendance logs...'),
              error: (error, _) => adminErrorView(
                error,
                () => ref.invalidate(adminAttendanceProvider(_status)),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.assignment_turned_in_outlined,
                    title: 'No attendance records',
                    message:
                        'Clock sessions will appear here after employees clock in.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(adminAttendanceProvider(_status)),
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _AttendanceCard(session: items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({required this.session});

  final AdminAttendanceSession session;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Session ${session.id}',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                StatusPill(label: session.status, active: session.isOpen),
              ],
            ),
            const SizedBox(height: 10),
            InfoRow(label: 'Employee', value: session.employeeId),
            InfoRow(label: 'Clock in', value: _dateTime(session.clockInAt)),
            InfoRow(label: 'Clock out', value: _dateTime(session.clockOutAt)),
            InfoRow(
              label: 'Face check',
              value: session.clockInFaceVerified ? 'Verified' : 'Not verified',
            ),
            InfoRow(
              label: 'In geofence',
              value: session.clockInGeofenceId ?? 'Not recorded',
            ),
            InfoRow(
              label: 'Out geofence',
              value: session.clockOutGeofenceId ?? 'Not recorded',
            ),
          ],
        ),
      ),
    );
  }
}

String _dateTime(String? value) {
  if (value == null || value.isEmpty) return 'Not recorded';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  return parsed.toLocal().toString().split('.').first;
}
