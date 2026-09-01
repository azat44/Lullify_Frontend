import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullify_mobile/core/network/dio_client.dart';
import 'package:lullify_mobile/presentation/pages/profile/admin_page.dart';

// Intercepts requests before they hit the network and records what was sent.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter({
    this.users = const [],
    this.stats = const {},
    this.failOnGet = false,
  });

  final List<Map<String, dynamic>> users;
  final Map<String, dynamic> stats;
  final bool failOnGet;

  final List<String> requests = [];

  static const _jsonHeaders = {
    Headers.contentTypeHeader: [Headers.jsonContentType],
  };

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add('${options.method} ${options.path}');

    if (options.method == 'DELETE') {
      return ResponseBody.fromString('{}', 200, headers: _jsonHeaders);
    }
    if (failOnGet) {
      return ResponseBody.fromString(
        '{"error":"internal"}',
        500,
        headers: _jsonHeaders,
      );
    }
    if (options.path.contains('/admin/stats')) {
      return ResponseBody.fromString(
        jsonEncode(stats),
        200,
        headers: _jsonHeaders,
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'users': users}),
      200,
      headers: _jsonHeaders,
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> _userJson({
  String id = 'u1',
  String username = 'azat',
  String email = 'azat@lullify.app',
  String role = 'user',
}) =>
    {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'created_at': '2026-08-01T10:00:00Z',
    };

const _stats = {
  'total_users': 12,
  'admins': 1,
  'broadcasters': 3,
  'listeners': 8,
};

Widget _wrap(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'http://test.local'))
    ..httpClientAdapter = adapter;

  return ProviderScope(
    overrides: [dioProvider.overrideWithValue(dio)],
    child: const MaterialApp(home: AdminPage()),
  );
}

void main() {
  group('loading', () {
    testWidgets('shows a loader before the data arrives', (tester) async {
      await tester.pumpWidget(_wrap(_FakeAdapter()));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('renders stats and the user list', (tester) async {
      final adapter = _FakeAdapter(
        users: [
          _userJson(),
          _userJson(id: 'u2', username: 'sukeshi', email: 'suk@lullify.app'),
        ],
        stats: _stats,
      );

      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      expect(find.text('OVERVIEW'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);

      expect(find.text('USERS (2)'), findsOneWidget);
      expect(find.text('@azat'), findsOneWidget);
      expect(find.text('@sukeshi'), findsOneWidget);
      expect(find.text('azat@lullify.app'), findsOneWidget);
    });

    testWidgets('shows the error state with a retry button', (tester) async {
      await tester.pumpWidget(_wrap(_FakeAdapter(failOnGet: true)));
      await tester.pumpAndSettle();

      expect(find.text('Failed to load admin data'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });

    testWidgets('retry fires the API calls again', (tester) async {
      final adapter = _FakeAdapter(failOnGet: true);

      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      final callsBefore = adapter.requests.length;

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(adapter.requests.length, greaterThan(callsBefore));
    });
  });

  group('user deletion', () {
    testWidgets('asks for confirmation before deleting', (tester) async {
      final adapter = _FakeAdapter(users: [_userJson()], stats: _stats);

      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete user'), findsOneWidget);
      expect(
        find.text('Delete @azat? This action cannot be undone.'),
        findsOneWidget,
      );
    });

    testWidgets('cancel closes the dialog without calling the API',
        (tester) async {
      final adapter = _FakeAdapter(users: [_userJson()], stats: _stats);

      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(
        adapter.requests.any((r) => r.startsWith('DELETE')),
        isFalse,
        reason: 'no DELETE should be sent when the admin cancels',
      );
    });

    testWidgets('confirming sends the DELETE for the right user',
        (tester) async {
      final adapter = _FakeAdapter(
        users: [_userJson(id: 'u42', username: 'ghost')],
        stats: _stats,
      );

      await tester.pumpWidget(_wrap(adapter));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
        adapter.requests.any((r) => r == 'DELETE /admin/users/u42'),
        isTrue,
      );
    });
  });
}