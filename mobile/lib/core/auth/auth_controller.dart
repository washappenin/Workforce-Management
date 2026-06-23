import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../errors/failures.dart';
import 'models.dart';
import 'token_storage.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AuthUser user;
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.expired = false, this.message});
  final bool expired;
  final String? message;
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  final api = ref.watch(apiClientProvider);
  final storage = ref.watch(tokenStorageProvider);
  final events = ref.watch(authEventsProvider);
  final c = AuthController(api: api, storage: storage);
  final sub = events.onUnauthorized.listen((_) => c.handleUnauthorized());
  ref.onDispose(sub.cancel);
  // Hydrate on startup.
  c.hydrate();
  return c;
});

class AuthController extends StateNotifier<AuthState> {
  AuthController({required ApiClient api, required TokenStorage storage})
      : _api = api,
        _storage = storage,
        super(const AuthInitial());

  final ApiClient _api;
  final TokenStorage _storage;

  Future<void> hydrate() async {
    state = const AuthLoading();
    final token = await _storage.read();
    if (token == null || token.isEmpty) {
      state = const AuthUnauthenticated();
      return;
    }
    try {
      final data = await _api.get<Map<String, Object?>>('/api/auth/me');
      final user = AuthUser.fromJson(data['user'] as Map<String, Object?>);
      state = AuthAuthenticated(user);
    } on UnauthenticatedFailure {
      await _storage.clear();
      state = const AuthUnauthenticated(expired: true);
    } on AppFailure catch (e) {
      // Keep the token; surface as unauthenticated with message so login screen
      // can retry. We do NOT silently drop the session for connection errors.
      state = AuthUnauthenticated(message: e.message);
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AuthLoading();
    try {
      final data = await _api.post<Map<String, Object?>>(
        '/api/auth/login',
        body: {'email': email.trim().toLowerCase(), 'password': password},
        skipAuth: true,
      );
      final token = data['accessToken'] as String;
      await _storage.write(token);
      final user = AuthUser.fromJson(data['user'] as Map<String, Object?>);
      state = AuthAuthenticated(user);
    } on AppFailure catch (e) {
      state = AuthUnauthenticated(message: e.message);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _api.post<dynamic>('/api/auth/logout');
    } on AppFailure {
      // Continue even if logout fails server-side.
    }
    await _storage.clear();
    state = const AuthUnauthenticated();
  }

  Future<void> handleUnauthorized() async {
    if (state is AuthAuthenticated) {
      await _storage.clear();
      state = const AuthUnauthenticated(expired: true);
    }
  }
}
