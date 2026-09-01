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
  _FakeAuthRepository({this.failRegister = false});

  final bool failRegister;

  String? registerEmail;
  String? registerUsername;
  String? registerPassword;

  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<User> login({required String email, required String password}) async =>
      _user;

  @override
  Future<User> register({
    required String email,
    required String username,
    required String password,
    bool wantBroadcaster = false,
  }) async {
    registerEmail = email;
    registerUsername = username;
    registerPassword = password;
    if (failRegister) throw Exception('email already taken');
    return _user;
  }

  @override
  Future<void> logout() async {}
}

late GoRouter _router;

Widget _wrap(AuthRepository repo) {
  _router = GoRouter(
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
    child: MaterialApp.router(routerConfig: _router),
  );
}

// Pushed on top of login so the "sign in" link has somewhere to pop back to.
Future<void> _pumpRegister(WidgetTester tester, AuthRepository repo) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(_wrap(repo));
  await tester.pumpAndSettle();

  _router.push('/register');
  await tester.pumpAndSettle();
}

void main() {
  group('rendering', () {
    testWidgets('shows the sign-up form', (tester) async {
      await _pumpRegister(tester, _FakeAuthRepository());

      expect(find.text('Join the lo-fi community'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('USERNAME'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('CONFIRM PASSWORD'), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('rejects an empty form', (tester) async {
      final repo = _FakeAuthRepository();
      await _pumpRegister(tester, repo);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(repo.registerEmail, isNull);
    });

    testWidgets('rejects a username shorter than 3 characters',
        (tester) async {
      await _pumpRegister(tester, _FakeAuthRepository());

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'azat@lullify.app');
      await tester.enterText(fields.at(1), 'az');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('At least 3 characters'), findsOneWidget);
    });

    testWidgets('rejects a confirmation that does not match', (tester) async {
      final repo = _FakeAuthRepository();
      await _pumpRegister(tester, repo);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'azat@lullify.app');
      await tester.enterText(fields.at(1), 'azat');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password124');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(repo.registerEmail, isNull);
    });
  });

  group('submission', () {
    testWidgets('trims the input and navigates home on success',
        (tester) async {
      final repo = _FakeAuthRepository();
      await _pumpRegister(tester, repo);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '  azat@lullify.app  ');
      await tester.enterText(fields.at(1), '  azat  ');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(repo.registerEmail, 'azat@lullify.app');
      expect(repo.registerUsername, 'azat');
      expect(repo.registerPassword, 'password123');
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('shows an error and stays on the page when register fails',
        (tester) async {
      await _pumpRegister(tester, _FakeAuthRepository(failRegister: true));

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'azat@lullify.app');
      await tester.enterText(fields.at(1), 'azat');
      await tester.enterText(fields.at(2), 'password123');
      await tester.enterText(fields.at(3), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('HOME'), findsNothing);

      await tester.pumpAndSettle(const Duration(seconds: 5));
    });
  });

  group('navigation', () {
    testWidgets('goes back to sign in', (tester) async {
      await _pumpRegister(tester, _FakeAuthRepository());

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
    });
  });
}