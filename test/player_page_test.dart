import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lullify_mobile/domain/entities/favorite.dart';
import 'package:lullify_mobile/domain/entities/history_entry.dart';
import 'package:lullify_mobile/domain/entities/stream.dart';
import 'package:lullify_mobile/domain/repositories/favorite_repository.dart';
import 'package:lullify_mobile/domain/repositories/history_repository.dart';
import 'package:lullify_mobile/presentation/pages/player/player_page.dart';
import 'package:lullify_mobile/presentation/providers/favorite_provider.dart';
import 'package:lullify_mobile/presentation/providers/history_provider.dart';
import 'package:lullify_mobile/presentation/providers/player_provider.dart';
import 'package:lullify_mobile/presentation/providers/stream_provider.dart';
import 'package:lullify_mobile/presentation/widgets/listener_count.dart';
import 'package:lullify_mobile/presentation/widgets/live_badge.dart';
import 'package:lullify_mobile/services/audio_handler.dart';

// ── Fake handler : aucun appel à just_audio / audio_service ─────────
class _FakeAudioHandler implements LullifyAudioHandler {
  bool playHlsCalled = false;
  bool pauseCalled = false;
  bool playCalled = false;
  bool stopCalled = false;
  double? lastVolume;

  final AudioPlayer _fakePlayer = AudioPlayer();

  @override
  AudioPlayer get player => _fakePlayer;

  @override
  Future<void> playHls({
    required String url,
    required String title,
    required String artist,
  }) async {
    playHlsCalled = true;
  }

  @override
  Future<void> play() async => playCalled = true;

  @override
  Future<void> pause() async => pauseCalled = true;

  @override
  Future<void> stop() async => stopCalled = true;

  @override
  Future<void> setVolume(double volume) async => lastVolume = volume;

  // Membres BaseAudioHandler non utilisés par PlayerNotifier
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Faux repositories : évitent tout appel réseau/stockage réel ─────
// (favoriteProvider et historyRepositoryProvider sont désormais lus par
// PlayerPage ; sans override ils remonteraient jusqu'à dioProvider, qui a
// besoin d'un vrai FlutterSecureStorage indisponible en test.)
class _FakeFavoriteRepository implements FavoriteRepository {
  @override
  Future<List<Favorite>> getMyFavorites() async => const [];

  @override
  Future<void> addFavorite(String streamId) async {}

  @override
  Future<void> removeFavorite(String streamId) async {}
}

class _FakeHistoryRepository implements HistoryRepository {
  @override
  Future<List<HistoryEntry>> getMyHistory() async => const [];

  @override
  Future<void> recordListen({
    required String trackTitle,
    required String artist,
    required String streamId,
  }) async {}
}

// ── Helpers ─────────────────────────────────────────────────────────
AudioStream _stream({
  StreamStatus status = StreamStatus.live,
  String title = 'LofiNight',
  String? description = 'Chill beats to relax',
}) {
  return AudioStream(
    id: 'stream-1',
    ownerId: 'owner-1',
    title: title,
    description: description,
    mountPoint: 'lofinight',
    status: status,
  );
}

Widget _wrap({
  required AudioStream stream,
  required PlayerNotifier notifier,
  int listenerCount = 0,
}) {
  return ProviderScope(
    overrides: [
      playerProvider.overrideWith((ref) => notifier),
      listenerCountProvider(stream.id).overrideWithValue(listenerCount),
      favoriteProvider
          .overrideWith((ref) => FavoriteNotifier(_FakeFavoriteRepository())),
      historyRepositoryProvider.overrideWithValue(_FakeHistoryRepository()),
    ],
    child: MaterialApp(home: PlayerPage(stream: stream)),
  );
}

void main() {
  late _FakeAudioHandler fakeHandler;
  late PlayerNotifier notifier;

  setUp(() {
    fakeHandler = _FakeAudioHandler();
    notifier = PlayerNotifier(handler: fakeHandler);
  });

  testWidgets('affiche titre, description et listener count', (tester) async {
    await tester.pumpWidget(_wrap(
      stream: _stream(),
      notifier: notifier,
      listenerCount: 42,
    ));
    await tester.pump(); // laisse passer le postFrameCallback play()

    expect(find.text('LofiNight'), findsOneWidget);
    expect(find.text('Chill beats to relax'), findsOneWidget);
    expect(find.byType(ListenerCount), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('affiche le LiveBadge quand le stream est live', (tester) async {
    await tester.pumpWidget(_wrap(
      stream: _stream(status: StreamStatus.live),
      notifier: notifier,
    ));
    await tester.pump();

    expect(find.byType(LiveBadge), findsOneWidget);
  });

  testWidgets('déclenche la lecture HLS automatiquement à l\'ouverture',
      (tester) async {
    await tester.pumpWidget(_wrap(stream: _stream(), notifier: notifier));
    await tester.pump(); // exécute le addPostFrameCallback

    expect(fakeHandler.playHlsCalled, isTrue);
  });

  testWidgets('tap sur pause en Playing → handler.pause()', (tester) async {
    await tester.pumpWidget(_wrap(stream: _stream(), notifier: notifier));
    await tester.pump();

    // Force l'état Playing (le fake handler n'émet pas de playerStateStream réel)
    notifier.state = const PlayerPlaying(
      streamId: 'stream-1',
      streamTitle: 'LofiNight',
      position: Duration.zero,
      volume: 1.0,
    );
    await tester.pump();

    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pump();

    expect(fakeHandler.pauseCalled, isTrue);
  });

  testWidgets('tap sur play en Paused → handler.play()', (tester) async {
    await tester.pumpWidget(_wrap(stream: _stream(), notifier: notifier));
    await tester.pump();

    notifier.state = const PlayerPaused(
      streamId: 'stream-1',
      streamTitle: 'LofiNight',
    );
    await tester.pump();

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pump();

    expect(fakeHandler.playCalled, isTrue);
  });

  testWidgets('tap sur stop → handler.stop() et état Idle', (tester) async {
    await tester.pumpWidget(_wrap(stream: _stream(), notifier: notifier));
    await tester.pump();

    notifier.state = const PlayerPlaying(
      streamId: 'stream-1',
      streamTitle: 'LofiNight',
      position: Duration.zero,
      volume: 1.0,
    );
    await tester.pump();

    await tester.tap(find.byIcon(Icons.stop_rounded));
    await tester.pump();

    expect(fakeHandler.stopCalled, isTrue);
  });

  testWidgets('en Loading, affiche l\'icône hourglass', (tester) async {
    await tester.pumpWidget(_wrap(stream: _stream(), notifier: notifier));
    notifier.state = const PlayerLoading();
    await tester.pump();

    expect(find.byIcon(Icons.hourglass_empty_rounded), findsOneWidget);
  });
}