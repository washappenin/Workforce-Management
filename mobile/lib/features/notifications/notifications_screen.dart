import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/states.dart';
import '../employee/widgets/employee_widgets.dart';
import 'notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return EmployeePage(
      title: 'Notifications',
      subtitle: 'Your inbox',
      action: notifications.maybeWhen(
        data: (items) => OutlinedButton.icon(
          key: const ValueKey('notifications.markAllRead'),
          onPressed: items.any((item) => item.isUnread)
              ? () => _markAllRead(context, ref)
              : null,
          icon: const Icon(Icons.done_all),
          label: const Text('Read all'),
        ),
        orElse: () => IconButton.outlined(
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(notificationsProvider),
          icon: const Icon(Icons.refresh),
        ),
      ),
      child: notifications.when(
        loading: () => const LoadingState(label: 'Loading notifications...'),
        error: (error, _) => employeeErrorView(
          error,
          () => ref.invalidate(notificationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications',
              message: 'New announcements and workflow updates appear here.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              ref.invalidate(unreadCountProvider);
              await ref.read(notificationsProvider.future);
            },
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notification = items[index];
                return SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          StatusChip(
                            label: notification.isUnread ? 'UNREAD' : 'READ',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(notification.message),
                      const Divider(height: 24),
                      InfoLine(
                        label: 'Type',
                        value: titleCase(notification.type),
                      ),
                      InfoLine(
                        label: 'Created',
                        value: shortDateTime(notification.createdAt),
                      ),
                      if (notification.readAt != null)
                        InfoLine(
                          label: 'Read',
                          value: shortDateTime(notification.readAt),
                        ),
                      if (notification.isUnread) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          key: ValueKey(
                            'notifications.markRead.${notification.id}',
                          ),
                          onPressed: () =>
                              _markRead(context, ref, notification.id),
                          icon: const Icon(Icons.mark_email_read_outlined),
                          label: const Text('Mark read'),
                        ),
                      ],
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

  Future<void> _markRead(
    BuildContext context,
    WidgetRef ref,
    String notificationId,
  ) async {
    try {
      await ref.read(notificationsRepositoryProvider).markRead(notificationId);
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
      if (context.mounted) {
        showEmployeeSuccessSnack(context, 'Notification marked read.');
      }
    } catch (error) {
      if (context.mounted) showEmployeeFailureSnack(context, error);
    }
  }

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    try {
      final count =
          await ref.read(notificationsRepositoryProvider).markAllRead();
      ref.invalidate(notificationsProvider);
      ref.invalidate(unreadCountProvider);
      if (context.mounted) {
        showEmployeeSuccessSnack(context, '$count notifications marked read.');
      }
    } catch (error) {
      if (context.mounted) showEmployeeFailureSnack(context, error);
    }
  }
}
