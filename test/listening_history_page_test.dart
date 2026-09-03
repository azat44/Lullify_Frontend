import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullify_mobile/domain/entities/history_entry.dart';
import 'package:lullify_mobile/domain/repositories/history_repository.dart';
import 'package:lullify_mobile/presentation/pages/history/listening_history_page.dart';
import 'package:lullify_mobile/presentation/providers/history_provider.dart';
import 'package:lullify_mobile/presentation/widgets/history_tile.dart';

class _FakeHistoryRepository implements HistoryRepository {
  _FakeHistoryRepository(this._entries);
  final List<HistoryEntry> _entries;

  @override
  Future<List<HistoryEntry>> getMyHistory() async => _entries;

  @override
  Future<void> recordListen({
    required String trackTitle,
    required String artist,
    required String streamId,
  }) async {}
}

class _ThrowingHistoryRepository implements HistoryRepository {
  @override
  Future<List<HistoryEntry>> getMyHistory() async =>
      throw Exception('network down');

  @override
  Future<void> recordListen({
    required String trackTitle,
    required String artist,
    required String streamId,
  }) async {}
}

Widget _wrap(HistoryRepository repo) {
  return ProviderScope(
    overrides: [
      historyRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(home: ListeningHistoryPage()),
  );
}

void main() {
  testWidgets('renders entries grouped under a day header', (tester) async {
    final now = DateTime.now();
    final repo = _FakeHistoryRepository([
      HistoryEntry(
        id: '1',
        userId: 'u1',
        trackTitle: 'Midnight Drive',
        artist: 'Lofi Cat',
        playedAt: now,
      ),
      HistoryEntry(
        id: '2',
        userId: 'u1',
        trackTitle: 'Rainy Window',
        artist: 'Sleepy Fox',
        playedAt: now.subtract(const Duration(minutes: 30)),
      ),
    ]);

    await tester.pumpWidget(_wrap(repo));
    await tester.pumpAndSettle();

    expect(find.text('Midnight Drive'), findsOneWidget);
    expect(find.text('Rainy Window'), findsOneWidget);
    expect(find.text('Lofi Cat'), findsOneWidget);
    expect(find.text('TODAY'), findsOneWidget); // en-tête de section
    expect(find.byType(HistoryTile), findsNWidgets(2));
  });

  testWidgets('shows empty state when there is no history', (tester) async {
    await tester.pumpWidget(_wrap(_FakeHistoryRepository(const [])));
    await tester.pumpAndSettle();

    expect(find.text('No listening history yet'), findsOneWidget);
    expect(find.byType(HistoryTile), findsNothing);
  });

  testWidgets('shows error state with a retry button on failure',
      (tester) async {
    await tester.pumpWidget(_wrap(_ThrowingHistoryRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Failed to load listening history'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
  });
}