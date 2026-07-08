import 'package:dio/dio.dart';
import 'package:lullify_mobile/core/constants.dart';
import 'package:lullify_mobile/data/models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource() : _dio = Dio(BaseOptions(
    baseUrl: AppConstants.apiBaseUrl,
    connectTimeout: AppConstants.apiTimeout,
    receiveTimeout: AppConstants.apiTimeout,
    headers: {'Content-Type': 'application/json'},
  ));

  final Dio _dio;

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(
      data['user'] as Map<String, dynamic>,
      accessToken: data['access_token'] as String?,
      refreshToken: data['refresh_token'] as String?,
    );
  }

  Future<UserModel> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final response = await _dio.post('/auth/register', data: {
      'email': email,
      'username': username,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(
      data['user'] as Map<String, dynamic>,
      accessToken: data['access_token'] as String?,
      refreshToken: data['refresh_token'] as String?,
    );
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<String?> refreshToken(String refreshToken) async {
    final response = await _dio.post('/auth/refresh', data: {
      'refresh_token': refreshToken,
    });
    final data = response.data as Map<String, dynamic>;
    return data['access_token'] as String?;
  }
}