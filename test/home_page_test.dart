import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lullify_mobile/domain/entities/favorite.dart';
import 'package:lullify_mobile/domain/entities/stream.dart';
import 'package:lullify_mobile/domain/repositories/favorite_repository.dart';
import 'package:lullify_mobile/domain/repositories/stream_repository.dart';
import 'package:lullify_mobile/presentation/pages/home/home_page.dart';
import 'package:lullify_mobile/presentation/providers/favorite_provider.dart';
import 'package:lullify_mobile/presentation/providers/stream_provider.dart';
import 'package:lullify_mobile/presentation/widgets/stream_card.dart';

class _FakeStreamRepository implements StreamRepository {
  _FakeStreamRepository({
    this.streams = const [],
    this.fail = false,
    this.gate,
  });

  final List<AudioStream> streams;
  final bool fail;
  final Completer<void>? gate;

  int calls = 0;

  @override
  Future<List<AudioStream>> getActiveStreams() async {
    calls++;
    if (gate != null) await gate!.future;
    if (fail) throw Exception('network down');
    return streams;
  }

  @override
  Future<AudioStream> getStream(String id) async => streams.first;
}

class _FakeFavoriteRepository implements FavoriteRepository {
  String? addedStreamId;
  String? removedStreamId;

  @override
  Future<List<Favorite>> getMyFavorites() async => [];

  @override
  Future<void> addFavorite(String streamId) async => addedStreamId = streamId;

  @override
  Future<void> removeFavorite(String streamId) async =>
      removedStreamId = streamId;
}

AudioStream _stream({
  String id = 'stream-1',
  String title = 'LofiNight',
  String? description = 'Chill beats to relax',
  StreamStatus status = StreamStatus.live,
  int listenerCount = 12,
}) {
  return AudioStream(
    id: id,
    ownerId: 'owner-1',
    title: title,
    description: description,
    mountPoint: 'lofinight',
    status: status,
    listenerCount: listenerCount,
  );
}

// The notifier polls every 5s; polling is stopped so no timer outlives a test.
StreamListNotifier _notifier(StreamRepository repo) {
  final notifier = StreamListNotifier(repo)..stopPolling();
  addTearDown(notifier.stopPolling);
  return notifier;
}

Widget _wrap(StreamListNotifier notifier, FavoriteRepository favorites) {
  return ProviderScope(
    overrides: [
      favoriteRepositoryProvider.overrideWithValue(favorites),
      streamListProvider.overrideWith((ref) => notifier),
    ],
    child: const MaterialApp(home: HomePage()),
  );
}

// LiveBadge and the loading skeleton animate forever, so pumpAndSettle would
// never return here.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('loading', () {
    testWidgets('shows skeleton cards while the request is in flight',
        (tester) async {
      final gate = Completer<void>();
      final repo = _FakeStreamRepository(gate: gate);

      await tester.pumpWidget(_wrap(_notifier(repo), _FakeFavoriteRepository()));
      await tester.pump();

      expect(find.byType(StreamCardSkeleton), findsNWidgets(4));
      expect(find.byType(StreamCard), findsNothing);

      gate.complete();
      await _settle(tester);
    });
  });

  group('loaded', () {
    testWidgets('renders one card per stream', (tester) async {
      final repo = _FakeStreamRepository(streams: [
        _stream(),
        _stream(id: 'stream-2', title: 'RainyDesk', description: 'Rain loops'),
      ]);

      await tester.pumpWidget(_wrap(_notifier(repo), _FakeFavoriteRepository()));
      await _settle(tester);

      expect(find.byType(StreamCard), findsNWidgets(2));
      expect(find.text('LofiNight'), findsOneWidget);
      expect(find.text('RainyDesk'), findsOneWidget);
      expect(find.text('Chill beats to relax'), findsOneWidget);
    });

    testWidgets('only live streams are tappable', (tester) async {
      final repo = _FakeStreamRepository(streams: [
        _stream(),
        _stream(
          id: 'stream-2',
          title: 'Offline show',
          status: StreamStatus.offline,
        ),
      ]);

      await tester.pumpWidget(_wrap(_notifier(repo), _FakeFavoriteRepository()));
      await _settle(tester);

      final cards = find.byType(StreamCard);
      expect(tester.widget<StreamCard>(cards.at(0)).onTap, isNotNull);
      expect(tester.widget<StreamCard>(cards.at(1)).onTap, isNull);
    });

    testWidgets('shows the empty state when nothing is live', (tester) async {
      final repo = _FakeStreamRepository(streams: const []);

      await tester.pumpWidget(_wrap(_notifier(repo), _FakeFavoriteRepository()));
      await _settle(tester);

      expect(find.text('No live streams'), findsOneWidget);
      expect(find.text('Pull to refresh'), findsOneWidget);
      expect(find.byType(StreamCard), findsNothing);
    });
  });

  group('error', () {
    testWidgets('shows the error state with a retry button', (tester) async {
      final repo = _FakeStreamRepository(fail: true);

      await tester.pumpWidget(_wrap(_notifier(repo), _FakeFavoriteRepository()));
      await _settle(tester);

      expect(find.text('Failed to load streams'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);
    });

    testWidgets('retry asks the repository again', (tester) async {
      final repo = _FakeStreamRepository(fail: true);

      await tester.pumpWidget(_wrap(_notifier(repo), _FakeFavoriteRepository()));
      await _settle(tester);

      final callsBefore = repo.calls;

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await _settle(tester);

      expect(repo.calls, greaterThan(callsBefore));
    });
  });

  group('favorites', () {
    testWidgets('tapping the heart adds the stream to favorites',
        (tester) async {
      final repo = _FakeStreamRepository(streams: [_stream()]);
      final favorites = _FakeFavoriteRepository();

      await tester.pumpWidget(_wrap(_notifier(repo), favorites));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await _settle(tester);

      expect(favorites.addedStreamId, 'stream-1');
    });
  });
}