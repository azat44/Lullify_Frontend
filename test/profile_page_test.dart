import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullify_mobile/domain/entities/user.dart';
import 'package:lullify_mobile/domain/repositories/auth_repository.dart';
import 'package:lullify_mobile/presentation/pages/profile/profile_page.dart';
import 'package:lullify_mobile/presentation/providers/auth_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this._user);

  final User? _user;
  bool logoutCalled = false;

  @override
  Future<User?> getCurrentUser() async => _user;

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<User> login({required String email, required String password}) async =>
      throw UnimplementedError();

  @override
  Future<User> register({
    required String email,
    required String username,
    required String password,
    bool wantBroadcaster = false,
  }) async =>
      throw UnimplementedError();
}

User _user({UserRole role = UserRole.user}) => User(
      id: 'u1',
      email: 'azat@lullify.app',
      username: 'azat',
      role: role,
    );

Widget _wrap(AuthRepository repo) {
  return ProviderScope(
    overrides: [authRepositoryProvider.overrideWithValue(repo)],
    child: const MaterialApp(home: ProfilePage()),
  );
}

// Taller surface so the whole ListView renders without scrolling.
Future<void> _pumpProfile(WidgetTester tester, AuthRepository repo) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(_wrap(repo));
  await tester.pumpAndSettle();
}

void main() {
  group('session state', () {
    testWidgets('shows sign-in prompt when there is no session',
        (tester) async {
      await _pumpProfile(tester, _FakeAuthRepository(null));

      expect(find.text('Not logged in'), findsOneWidget);
      expect(
        find.text('Sign in to access your profile and settings'),
        findsOneWidget,
      );
    });

    testWidgets('shows account details when a session exists', (tester) async {
      await _pumpProfile(tester, _FakeAuthRepository(_user()));

      expect(find.text('azat@lullify.app'), findsOneWidget);
      expect(find.text('Listener'), findsOneWidget);
      // _SectionTitle uppercases its title before rendering.
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Not logged in'), findsNothing);
    });
  });

  group('admin access', () {
    testWidgets('hides the admin section for a regular user', (tester) async {
      await _pumpProfile(tester, _FakeAuthRepository(_user()));

      expect(find.text('ADMINISTRATION'), findsNothing);
      expect(find.text('Admin Panel'), findsNothing);
    });

    testWidgets('exposes the admin panel for an admin account', (tester) async {
      await _pumpProfile(
        tester,
        _FakeAuthRepository(_user(role: UserRole.admin)),
      );

      expect(find.text('ADMINISTRATION'), findsOneWidget);
      expect(find.text('Admin Panel'), findsOneWidget);
      expect(find.text('Admin'), findsOneWidget);
    });
  });

  group('username editing', () {
    testWidgets('keeps the form collapsed until the tile is tapped',
        (tester) async {
      await _pumpProfile(tester, _FakeAuthRepository(_user()));

      expect(find.text('NEW USERNAME'), findsNothing);

      await tester.tap(find.text('Username'));
      await tester.pumpAndSettle();

      expect(find.text('NEW USERNAME'), findsOneWidget);
    });

    testWidgets('rejects an empty username', (tester) async {
      await _pumpProfile(tester, _FakeAuthRepository(_user()));

      await tester.tap(find.text('Username'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, '');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('rejects a username shorter than 3 characters', (tester) async {
      await _pumpProfile(tester, _FakeAuthRepository(_user()));

      await tester.tap(find.text('Username'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).first, 'az');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('At least 3 characters'), findsOneWidget);
    });
  });

  group('password change', () {
    testWidgets('expands both password fields', (tester) async {
      await _pumpProfile(tester, _FakeAuthRepository(_user()));

      await tester.tap(find.text('Password'));
      await tester.pumpAndSettle();

      expect(find.text('CURRENT PASSWORD'), findsOneWidget);
      expect(find.text('NEW PASSWORD'), findsOneWidget);
    });

    testWidgets('rejects a new password shorter than 8 characters',
        (tester) async {
      await _pumpProfile(tester, _FakeAuthRepository(_user()));

      await tester.tap(find.text('Password'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'old-password');
      await tester.enterText(fields.at(1), 'short');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('At least 8 characters'), findsOneWidget);
    });

    testWidgets('requires the current password', (tester) async {
      await _pumpProfile(tester, _FakeAuthRepository(_user()));

      await tester.tap(find.text('Password'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '');
      await tester.enterText(fields.at(1), 'a-valid-password');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsOneWidget);
    });
  });

  group('sign out', () {
    testWidgets('calls the repository and falls back to the logged out state',
        (tester) async {
      final repo = _FakeAuthRepository(_user());
      await _pumpProfile(tester, repo);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
      await tester.pumpAndSettle();

      expect(repo.logoutCalled, isTrue);
      expect(find.text('Not logged in'), findsOneWidget);
    });
  });
}