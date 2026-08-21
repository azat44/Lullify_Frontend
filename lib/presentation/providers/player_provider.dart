import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lullify_mobile/main.dart';

sealed class PlayerState {
  const PlayerState();
}
class PlayerIdle    extends PlayerState { const PlayerIdle(); }
class PlayerLoading extends PlayerState { const PlayerLoading(); }
class PlayerPlaying extends PlayerState {
  const PlayerPlaying({
    required this.streamId,
    required this.streamTitle,
    required this.position,
    required this.volume,
  });
  final String streamId;
  final String streamTitle;
  final Duration position;
  final double volume;
}
class PlayerPaused extends PlayerState {
  const PlayerPaused({
    required this.streamId,
    required this.streamTitle,
  });
  final String streamId;
  final String streamTitle;
}
class PlayerError extends PlayerState {
  const PlayerError(this.message);
  final String message;
}

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(const PlayerIdle()) {
    _listenToHandler();
  }

  String? _currentStreamId;
  String? _currentStreamTitle;

  void _listenToHandler() {
    audioHandler.player.playerStateStream.listen((ps) {
      if (!mounted) return;

      if (ps.processingState == ProcessingState.loading ||
          ps.processingState == ProcessingState.buffering) {
        state = const PlayerLoading();
      } else if (ps.playing) {
        state = PlayerPlaying(
          streamId: _currentStreamId ?? '',
          streamTitle: _currentStreamTitle ?? '',
          position: audioHandler.player.position,
          volume: audioHandler.player.volume,
        );
      } else if (ps.processingState == ProcessingState.ready && !ps.playing) {
        if (_currentStreamId != null) {
          state = PlayerPaused(
            streamId: _currentStreamId!,
            streamTitle: _currentStreamTitle!,
          );
        }
      }
    });

    // Mise à jour de la progression
    audioHandler.player.positionStream.listen((position) {
      if (!mounted) return;
      if (state is PlayerPlaying) {
        final current = state as PlayerPlaying;
        state = PlayerPlaying(
          streamId: current.streamId,
          streamTitle: current.streamTitle,
          position: position,
          volume: current.volume,
        );
      }
    });
  }

  Future<void> play({
    required String streamId,
    required String streamTitle,
    required String hlsUrl,
  }) async {
    try {
      state = const PlayerLoading();
      _currentStreamId = streamId;
      _currentStreamTitle = streamTitle;

      await audioHandler.playHls(
        url: hlsUrl,
        title: streamTitle,
        artist: 'Lullify Radio',
      );
    } catch (e) {
      state = PlayerError('Failed to load stream: $e');
    }
  }

  Future<void> pause() => audioHandler.pause();
  Future<void> resume() => audioHandler.play();

  Future<void> stop() async {
    await audioHandler.stop();
    _currentStreamId = null;
    _currentStreamTitle = null;
    state = const PlayerIdle();
  }

  Future<void> setVolume(double volume) async {
    await audioHandler.setVolume(volume);
    if (state is PlayerPlaying) {
      final current = state as PlayerPlaying;
      state = PlayerPlaying(
        streamId: current.streamId,
        streamTitle: current.streamTitle,
        position: current.position,
        volume: volume,
      );
    }
  }
}

final playerProvider =
StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});