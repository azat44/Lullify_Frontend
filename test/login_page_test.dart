import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:lullify_mobile/domain/entities/user.dart';
import 'package:lullify_mobile/domain/repositories/auth_repository.dart';
import 'package:lullify_mobile/presentation/pages/auth/login_page.dart';
import 'package:lullify_mobile/presentation/pages/auth/register_page.dart';
import 'package:lullify_mobile/presentation/providers/auth_provider.dart';

const _user = User(
  id: 'u1',
  email: 'azat@lullify.app',
  username: 'azat',
  role: UserRole.user,
);

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.failLogin = false, this.gate});

  final bool failLogin;
  final Completer<void>? gate;

  String? loginEmail;
  String? loginPassword;

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<User> login({required String email, required String password}) async {
    loginEmail = email;
    loginPassword = password;
    if (gate != null) await gate!.future;
    if (failLogin) throw Exception('invalid credentials');
    return _user;
  }

  @override
  Future<User> register({
    required String email,
    required String username,
    required String password,
  }) async =>
      _user;

  @override
  Future<void> logout() async {}
}

Widget _wrap(AuthRepository repo) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterPage()),
      GoRoute(
        path: '/',
        builder: (_, __) => const Scaffold(body: Center(child: Text('HOME'))),
      ),
    ],
  );

  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp.router(routerConfig: router),
  );
}

Future<void> _pumpLogin(WidgetTester tester, AuthRepository repo) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(_wrap(repo));
  await tester.pumpAndSettle();
}

void main() {
  group('rendering', () {
    testWidgets('shows the sign-in form', (tester) async {
      await _pumpLogin(tester, _FakeAuthRepository());

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Sign in'), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('rejects an empty form', (tester) async {
      final repo = _FakeAuthRepository();
      await _pumpLogin(tester, repo);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(repo.loginEmail, isNull);
    });

    testWidgets('rejects a malformed email', (tester) async {
      await _pumpLogin(tester, _FakeAuthRepository());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'not-an-email');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('rejects a password shorter than 8 characters',
        (tester) async {
      await _pumpLogin(tester, _FakeAuthRepository());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'azat@lullify.app');
      await tester.enterText(fields.at(1), 'short');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('At least 8 characters'), findsOneWidget);
    });
  });

  group('submission', () {
    testWidgets('trims the email and navigates home on success',
        (tester) async {
      final repo = _FakeAuthRepository();
      await _pumpLogin(tester, repo);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '  azat@lullify.app  ');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(repo.loginEmail, 'azat@lullify.app');
      expect(repo.loginPassword, 'password123');
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('shows an error and stays on the page when login fails',
        (tester) async {
      await _pumpLogin(tester, _FakeAuthRepository(failLogin: true));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'azat@lullify.app');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('HOME'), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 5));
    });

    testWidgets('disables the button while the request is in flight',
        (tester) async {
      final gate = Completer<void>();
      await _pumpLogin(tester, _FakeAuthRepository(gate: gate));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'azat@lullify.app');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('HOME'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('links to the sign-up page', (tester) async {
      await _pumpLogin(tester, _FakeAuthRepository());

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(find.text('Join the lo-fi community'), findsOneWidget);
    });
  });
}