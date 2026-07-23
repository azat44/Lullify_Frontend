// lib/core/network/dio_client.dart

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lullify_mobile/core/constants.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (_) => const FlutterSecureStorage(),
);

// Surchargé dans main.dart pour brancher la déconnexion sur l'AuthNotifier.
final onSessionExpiredProvider = Provider<void Function()>(
  (_) => () {},
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.apiTimeout,
    receiveTimeout: AppConstants.apiTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(AuthInterceptor(
    dio: dio,
    storage: ref.read(secureStorageProvider),
    onSessionExpired: () => ref.read(onSessionExpiredProvider)(),
  ));

  return dio;
});

/// Injecte le Bearer token, et sur 401 tente un refresh puis rejoue
/// la requête. Si le refresh échoue, purge la session.
class AuthInterceptor extends QueuedInterceptorsWrapper {
  AuthInterceptor({
    required Dio dio,
    required FlutterSecureStorage storage,
    required this.onSessionExpired,
  })  : _dio = dio,
        _storage = storage;

  final Dio _dio;
  final FlutterSecureStorage _storage;
  final void Function() onSessionExpired;

  // Client sans intercepteur : un 401 sur /auth/refresh ne doit pas
  // redéclencher un refresh (boucle infinie).
  late final Dio _refreshDio = Dio(BaseOptions(
    baseUrl: _dio.options.baseUrl,
    connectTimeout: _dio.options.connectTimeout,
    receiveTimeout: _dio.options.receiveTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  // Mutualise le refresh entre requêtes concurrentes : un seul appel
  // /auth/refresh part, les autres attendent son résultat.
  Completer<String?>? _refreshCompleter;

  static const _publicPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_publicPaths.contains(options.path)) {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final isAuthCall = _publicPaths.contains(err.requestOptions.path);
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    // Un 401 sur /auth/login = mauvais identifiants, pas un token expiré.
    if (!isUnauthorized || isAuthCall || alreadyRetried) {
      handler.next(err);
      return;
    }

    final newToken = await _refreshToken();
    if (newToken == null) {
      await _clearSession();
      handler.next(err);
      return;
    }

    try {
      final retried = await _retry(err.requestOptions, newToken);
      handler.resolve(retried);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _refreshToken() async {
    final pending = _refreshCompleter;
    if (pending != null) return pending.future;

    final completer = Completer<String?>();
    _refreshCompleter = completer;

    try {
      final refreshToken =
          await _storage.read(key: AppConstants.refreshTokenKey);
      if (refreshToken == null) {
        completer.complete(null);
        return completer.future;
      }

      final response = await _refreshDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final data = response.data;
      final newAccess = data?['access_token'] as String?;
      final newRefresh = data?['refresh_token'] as String?;

      if (newAccess == null) {
        completer.complete(null);
        return completer.future;
      }

      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: newAccess,
      );
      if (newRefresh != null) {
        await _storage.write(
          key: AppConstants.refreshTokenKey,
          value: newRefresh,
        );
      }

      completer.complete(newAccess);
    } on DioException {
      completer.complete(null);
    } finally {
      _refreshCompleter = null;
    }

    return completer.future;
  }

  Future<Response<dynamic>> _retry(RequestOptions options, String token) {
    options.headers['Authorization'] = 'Bearer $token';
    options.extra['retried'] = true;
    return _dio.fetch(options);
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
    onSessionExpired();
  }
}