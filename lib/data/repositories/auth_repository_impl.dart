import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lullify_mobile/core/constants.dart';
import 'package:lullify_mobile/data/datasources/auth_remote_datasource.dart';
import 'package:lullify_mobile/data/models/user_model.dart';
import 'package:lullify_mobile/domain/entities/user.dart';
import 'package:lullify_mobile/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required FlutterSecureStorage secureStorage,
  })  : _remote = remoteDataSource,
        _storage = secureStorage;

  final AuthRemoteDataSource _remote;
  final FlutterSecureStorage _storage;

  Future<void> _saveTokens(UserModel user) async {
    if (user.accessToken != null) {
      await _storage.write(
        key: AppConstants.accessTokenKey,
        value: user.accessToken,
      );
    }
    if (user.refreshToken != null) {
      await _storage.write(
        key: AppConstants.refreshTokenKey,
        value: user.refreshToken,
      );
    }
  }

  UserRole _parseRole(String role) {
    switch (role) {
      case 'broadcaster':
        return UserRole.broadcaster;
      case 'admin':
        return UserRole.admin;
      case 'user':
        return UserRole.user;
      default:
        return UserRole.anonymous;
    }
  }

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final user = await _remote.login(email: email, password: password);
    await _saveTokens(user);
    return user;
  }

  @override
  Future<User> register({
    required String email,
    required String username,
    required String password,
    bool wantBroadcaster = false,
  }) async {
    final user = await _remote.register(
      email: email,
      username: username,
      password: password,
      wantBroadcaster: wantBroadcaster,
    );
    await _saveTokens(user);
    return user;
  }

  @override
  Future<void> logout() async {
    await _remote.logout();
    await _storage.delete(key: AppConstants.accessTokenKey);
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await _storage.read(key: AppConstants.accessTokenKey);
    if (token == null) return null;

    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      String payload = parts[1];
      final mod = payload.length % 4;
      if (mod != 0) payload += '=' * (4 - mod);

      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;

      final sub = map['sub'] as String?;
      final role = map['role'] as String?;
      final exp = map['exp'] as int?;

      if (sub == null || role == null) return null;

      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (DateTime.now().isAfter(expiry)) {
          final refreshToken =
          await _storage.read(key: AppConstants.refreshTokenKey);
          if (refreshToken == null) return null;
          try {
            final refreshed =
            await _remote.refresh(refreshToken: refreshToken);
            await _saveTokens(refreshed);
            return refreshed;
          } catch (_) {
            await _storage.delete(key: AppConstants.accessTokenKey);
            await _storage.delete(key: AppConstants.refreshTokenKey);
            return null;
          }
        }
      }

      return User(
        id: sub,
        username: '',
        email: '',
        role: _parseRole(role),
      );
    } catch (_) {
      return null;
    }
  }
}