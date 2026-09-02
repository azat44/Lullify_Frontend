import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lullify_mobile/main.dart';
import 'package:lullify_mobile/services/audio_handler.dart';
import 'package:flutter/foundation.dart';

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
  // Le handler est injecté pour permettre un fake dans les tests widget.
  PlayerNotifier({required LullifyAudioHandler handler})
      : _handler = handler,
        super(const PlayerIdle()) {
    _listenToHandler();
  }

  final LullifyAudioHandler _handler;

  String? _currentStreamId;
  String? _currentStreamTitle;

  void _listenToHandler() {
    _handler.player.playerStateStream.listen((ps) {
      if (!mounted) return;

      if (ps.processingState == ProcessingState.loading ||
          ps.processingState == ProcessingState.buffering) {
        state = const PlayerLoading();
      } else if (ps.playing) {
        state = PlayerPlaying(
          streamId: _currentStreamId ?? '',
          streamTitle: _currentStreamTitle ?? '',
          position: _handler.player.position,
          volume: _handler.player.volume,
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
    _handler.player.positionStream.listen((position) {
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

      await _handler.playHls(
        url: hlsUrl,
        title: streamTitle,
        artist: 'Lullify Radio',
      );
    } catch (e) {
      state = PlayerError('Failed to load stream: $e');
    }
  }

  Future<void> pause() => _handler.pause();
  Future<void> resume() => _handler.play();

  Future<void> stop() async {
    await _handler.stop();
    _currentStreamId = null;
    _currentStreamTitle = null;
    state = const PlayerIdle();
  }

  Future<void> setVolume(double volume) async {
    await _handler.setVolume(volume);
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

  /// Permet aux tests widget de simuler un état sans passer par just_audio.
  @visibleForTesting
  void debugSetState(PlayerState newState) => state = newState;
}

final playerProvider =
    StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier(handler: audioHandler);
});