import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/models.dart';
import '../../core/errors/failures.dart';

final notificationsRepositoryProvider =
    Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) return const [];

  final role = auth.user.primaryRole;
  if (role != AppRole.employee && role != AppRole.manager) {
    return const [];
  }

  return ref.watch(notificationsRepositoryProvider).listMine();
});

/// Returns the unread count, or null when the role has no inbox.
final unreadCountProvider = FutureProvider<int?>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) return null;

  // Only EMPLOYEE and MANAGER have a self notifications inbox per route map.
  final role = auth.user.primaryRole;
  if (role != AppRole.employee && role != AppRole.manager) {
    return null;
  }

  try {
    final api = ref.read(apiClientProvider);
    final data = await api
        .get<Map<String, Object?>>('/api/notifications/me/unread-count');
    final v = data['unreadCount'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return 0;
  } on AppFailure {
    return null;
  }
});

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.message,
    required this.createdAt,
    this.readAt,
  });

  final String id;
  final String type;
  final String status;
  final String title;
  final String message;
  final String createdAt;
  final String? readAt;

  bool get isUnread => status == 'UNREAD' && readAt == null;

  factory AppNotification.fromJson(Map<String, Object?> json) {
    return AppNotification(
      id: _string(json['id']),
      type: _string(json['type'], fallback: 'SYSTEM'),
      status: _string(json['status'], fallback: 'UNREAD'),
      title: _string(json['title'], fallback: 'Notification'),
      message: _string(json['message']),
      createdAt: _string(json['createdAt']),
      readAt: _optionalString(json['readAt']),
    );
  }
}

class NotificationsRepository {
  const NotificationsRepository(this._api);

  final ApiClient _api;

  Future<List<AppNotification>> listMine() async {
    final data = await _api.get<Map<String, Object?>>('/api/notifications/me');
    return _list(data, 'notifications')
        .map(AppNotification.fromJson)
        .toList(growable: false);
  }

  Future<AppNotification> markRead(String notificationId) async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/notifications/$notificationId/read',
    );
    return AppNotification.fromJson(_object(data, 'notification'));
  }

  Future<int> markAllRead() async {
    final data = await _api.patch<Map<String, Object?>>(
      '/api/notifications/read-all',
    );
    final updatedCount = data['updatedCount'];
    if (updatedCount is int) return updatedCount;
    if (updatedCount is num) return updatedCount.toInt();
    return 0;
  }
}

List<Map<String, Object?>> _list(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, Object?>.from(item))
      .toList(growable: false);
}

Map<String, Object?> _object(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is Map) return Map<String, Object?>.from(value);
  return data;
}

String _string(Object? value, {String fallback = ''}) {
  final text = _optionalString(value);
  return text == null || text.isEmpty ? fallback : text;
}

String? _optionalString(Object? value) {
  if (value == null) return null;
  final text = value.toString();
  return text.trim().isEmpty ? null : text;
}
