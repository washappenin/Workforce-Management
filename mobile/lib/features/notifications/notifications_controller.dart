import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/auth/models.dart';
import '../../core/errors/failures.dart';

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
