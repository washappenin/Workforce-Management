import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/token_storage.dart';
import '../config/app_config.dart';
import '../errors/failures.dart';

const String kApiBaseUrl = AppConfig.apiBaseUrl;

/// Broadcast stream fired when the API returns 401 so the auth layer can
/// clear the session and the router can redirect to /login.
class AuthEvents {
  AuthEvents();
  final _ctl = StreamController<void>.broadcast();
  Stream<void> get onUnauthorized => _ctl.stream;
  void emitUnauthorized() => _ctl.add(null);
  void dispose() => _ctl.close();
}

final authEventsProvider = Provider<AuthEvents>((ref) {
  final ev = AuthEvents();
  ref.onDispose(ev.dispose);
  return ev;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  final events = ref.watch(authEventsProvider);
  return ApiClient(storage: storage, events: events);
});

class ApiClient {
  ApiClient({required TokenStorage storage, required AuthEvents events})
      : _storage = storage,
        _events = events {
    _dio = Dio(
      BaseOptions(
        baseUrl: kApiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
        responseType: ResponseType.json,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (options.extra['skipAuth'] != true) {
            final token = await _storage.read();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (err, handler) {
          if (err.response?.statusCode == 401) {
            _events.emitUnauthorized();
          }
          handler.next(err);
        },
      ),
    );
  }

  final TokenStorage _storage;
  final AuthEvents _events;
  late final Dio _dio;

  Future<T> get<T>(String path,
          {Map<String, Object?>? query, bool skipAuth = false}) =>
      _request<T>('GET', path, query: query, skipAuth: skipAuth);

  Future<T> post<T>(String path,
          {Object? body, Map<String, Object?>? query, bool skipAuth = false}) =>
      _request<T>('POST', path, body: body, query: query, skipAuth: skipAuth);

  Future<T> patch<T>(String path,
          {Object? body, Map<String, Object?>? query, bool skipAuth = false}) =>
      _request<T>('PATCH', path, body: body, query: query, skipAuth: skipAuth);

  Future<T> delete<T>(String path,
          {Object? body, Map<String, Object?>? query, bool skipAuth = false}) =>
      _request<T>('DELETE', path, body: body, query: query, skipAuth: skipAuth);

  Future<T> _request<T>(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    bool skipAuth = false,
  }) async {
    try {
      final res = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          extra: {'skipAuth': skipAuth},
          contentType: body != null ? 'application/json' : null,
        ),
      );
      final data = res.data;
      if (data is Map && data['data'] != null) {
        return data['data'] as T;
      }
      return data as T;
    } on DioException catch (e) {
      throw _mapDioError(e);
    } catch (_) {
      throw const UnknownFailure();
    }
  }

  AppFailure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ConnectionFailure();
    }
    final res = e.response;
    final status = res?.statusCode ?? 0;
    final body = res?.data;
    String message = 'Request failed.';
    Map<String, Object?>? details;
    if (body is Map && body['error'] is Map) {
      final err = body['error'] as Map;
      message = (err['message'] as String?) ?? message;
      if (err['details'] is Map) {
        details = Map<String, Object?>.from(err['details'] as Map);
      }
    }
    switch (status) {
      case 401:
        return UnauthenticatedFailure(message);
      case 403:
        return ForbiddenFailure(message);
      case 404:
        return NotFoundFailure(message);
      case 400:
      case 422:
        return ValidationFailure(message, details: details);
      case 429:
        return RateLimitedFailure(message);
      default:
        if (status >= 500) return ServerFailure(message);
        return UnknownFailure(message);
    }
  }
}
