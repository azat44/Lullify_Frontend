import 'package:lullify_mobile/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login({required String email, required String password});
  Future<User> register({required String email, required String username, required String password});
  Future<void> logout();
  Future<String?> refreshToken();
  Future<User?> getCurrentUser();
}
