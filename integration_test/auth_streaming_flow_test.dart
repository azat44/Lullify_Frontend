import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lullify_mobile/core/app.dart';
import 'package:lullify_mobile/domain/entities/favorite.dart';
import 'package:lullify_mobile/domain/entities/stream.dart';
import 'package:lullify_mobile/domain/entities/user.dart';
import 'package:lullify_mobile/domain/repositories/auth_repository.dart';
import 'package:lullify_mobile/domain/repositories/favorite_repository.dart';
import 'package:lullify_mobile/domain/repositories/stream_repository.dart';
import 'package:lullify_mobile/presentation/pages/player/player_page.dart';
import 'package:lullify_mobile/presentation/providers/auth_provider.dart';
import 'package:lullify_mobile/presentation/providers/favorite_provider.dart';
import 'package:lullify_mobile/presentation/providers/player_provider.dart';
import 'package:lullify_mobile/presentation/providers/stream_provider.dart';
import 'package:lullify_mobile/presentation/widgets/stream_card.dart';
import 'package:lullify_mobile/services/audio_handler.dart';

const _user = User(
  id: 'u1',
  email: 'azat@lullify.app',
  username: 'azat',
  role: UserRole.user,
);

final _liveStream = AudioStream(
  id: 'stream-1',
  ownerId: 'owner-1',
  title: 'LofiNight',
  description: 'Chill beats to relax',
  mountPoint: 'lofinight',
  status: StreamStatus.live,
  listenerCount: 12,
);

class _FakeAuthRepository implements AuthRepository {
  User? session;

  @override
  Future<User?> getCurrentUser() async => session;

  @override
  Future<User> login({required String email, required String password}) async {
    session = _user;
    return _user;
  }

  @override
  Future<User> register({
    required String email,
    required String username,
    required String password,
    bool wantBroadcaster = false,
  }) async {
    session = _user;
    return _user;
  }

  @override
  Future<void> logout() async => session = null;
}

class _FakeStreamRepository implements StreamRepository {
  @override
  Future<List<AudioStream>> getActiveStreams() async => [_liveStream];

  @override
  Future<AudioStream> getStream(String id) async => _liveStream;
}

class _FakeFavoriteRepository implements FavoriteRepository {
  @override
  Future<List<Favorite>> getMyFavorites() async => [];

  @override
  Future<void> addFavorite(String streamId) async {}

  @override
  Future<void> removeFavorite(String streamId) async {}
}

class _FakeAudioHandler implements LullifyAudioHandler {
  bool playHlsCalled = false;
  String? lastTitle;

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
    lastTitle = title;
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// The splash sprite and the live badge animate forever, so pumpAndSettle would
// never return. Frames are advanced by hand instead.
Future<void> _advance(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAuthRepository auth;
  late _FakeAudioHandler handler;

  Future<void> bootApp(WidgetTester tester) async {
    // The default macOS window is too short for the player layout.
    tester.view.physicalSize = const Size(1200, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    auth = _FakeAuthRepository();
    handler = _FakeAudioHandler();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          streamRepositoryProvider.overrideWithValue(_FakeStreamRepository()),
          favoriteRepositoryProvider
              .overrideWithValue(_FakeFavoriteRepository()),
          playerProvider
              .overrideWith((ref) => PlayerNotifier(handler: handler)),
        ],
        child: const LullifyApp(),
      ),
    );

    await _advance(tester);
  }

  Future<void> signIn(WidgetTester tester) async {
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'azat@lullify.app');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign in'));
    await _advance(tester);
  }

  testWidgets('splash leads to the login screen', (tester) async {
    await bootApp(tester);

    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('signing in lands on the stream list', (tester) async {
    await bootApp(tester);
    await signIn(tester);

    expect(find.text('Welcome back'), findsNothing);
    expect(find.byType(StreamCard), findsOneWidget);
    expect(find.text('LofiNight'), findsOneWidget);
  });

  testWidgets('opening a live stream starts HLS playback', (tester) async {
    await bootApp(tester);
    await signIn(tester);

    await tester.tap(find.byType(StreamCard));
    await _advance(tester);

    expect(find.byType(PlayerPage), findsOneWidget);
    expect(handler.playHlsCalled, isTrue);
    expect(handler.lastTitle, 'LofiNight');
  });

  testWidgets('signing out returns to the login screen', (tester) async {
    await bootApp(tester);
    await signIn(tester);

    await tester.tap(find.text('Profile'));
    await _advance(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await _advance(tester);

    expect(find.text('Welcome back'), findsOneWidget);
    expect(auth.session, isNull);
  });
}