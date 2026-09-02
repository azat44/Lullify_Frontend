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
    return   null;
  }
}