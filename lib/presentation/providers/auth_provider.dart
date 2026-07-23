import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/network/dio_client.dart';
import 'package:lullify_mobile/data/datasources/auth_remote_datasource.dart';
import 'package:lullify_mobile/data/repositories/auth_repository_impl.dart';
import 'package:lullify_mobile/domain/entities/user.dart';
import 'package:lullify_mobile/domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>(
  (ref) => AuthRemoteDataSource(dio: ref.read(dioProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remoteDataSource: ref.read(authRemoteDataSourceProvider),
    secureStorage: ref.read(secureStorageProvider),
  );
});

sealed class AuthState {
  const AuthState();
}
class AuthInitial   extends AuthState { const AuthInitial(); }
class AuthLoading   extends AuthState { const AuthLoading(); }
class AuthSuccess   extends AuthState {
  const AuthSuccess(this.user);
  final User user;
}
class AuthError     extends AuthState {
  const AuthError(this.message);
  final String message;
}
class AuthLoggedOut extends AuthState { const AuthLoggedOut(); }

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repository) : super(const AuthInitial()) {
    _checkExistingSession();
  }

  final AuthRepository _repository;

  Future<void> _checkExistingSession() async {
    final user = await _repository.getCurrentUser();
    if (user != null) {
      state = AuthSuccess(user);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.login(email: email, password: password);
      state = AuthSuccess(user);
    } catch (e) {
      state = AuthError(_parseError(e));
    }
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final user = await _repository.register(
        email: email,
        username: username,
        password: password,
      );
      state = AuthSuccess(user);
    } catch (e) {
      state = AuthError(_parseError(e));
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } finally {
      state = const AuthLoggedOut();
    }
  }

  void sessionExpired() {
    state = const AuthLoggedOut();
  }

  String _parseError(Object e) {
    return 'Something went wrong. Please try again.';
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

final authRouterNotifierProvider = Provider<AuthNotifier>((ref) {
  return ref.watch(authProvider.notifier);
});