import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

// ── Player state ──────────────────────────────────────────────────────────────

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
class PlayerPaused  extends PlayerState {
  const PlayerPaused({
    required this.streamId,
    required this.streamTitle,
  });
  final String streamId;
  final String streamTitle;
}
class PlayerError   extends PlayerState {
  const PlayerError(this.message);
  final String message;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class PlayerNotifier extends StateNotifier<PlayerState> {
  PlayerNotifier() : super(const PlayerIdle()) {
    _player = AudioPlayer();
    _listenToPlayer();
  }

  late final AudioPlayer _player;
  String? _currentStreamId;
  String? _currentStreamTitle;

  void _listenToPlayer() {
    // Écoute les changements d'état du lecteur
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering) {
        if (mounted) {
          this.state = const PlayerLoading();
        }
      } else if (state.playing) {
        if (mounted) {
          this.state = PlayerPlaying(
            streamId: _currentStreamId ?? '',
            streamTitle: _currentStreamTitle ?? '',
            position: _player.position,
            volume: _player.volume,
          );
        }
      } else if (state.processingState == ProcessingState.ready && !state.playing) {
        if (mounted && _currentStreamId != null) {
          this.state = PlayerPaused(
            streamId: _currentStreamId!,
            streamTitle: _currentStreamTitle!,
          );
        }
      }
    });

    // Mise à jour de la progression
    _player.positionStream.listen((position) {
      if (mounted && this.state is PlayerPlaying) {
        final current = this.state as PlayerPlaying;
        this.state = PlayerPlaying(
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

      await _player.setAudioSource(
        HlsAudioSource(Uri.parse(hlsUrl)),
      );
      await _player.play();
    } catch (e) {
      state = PlayerError('Failed to load stream: $e');
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    _currentStreamId = null;
    _currentStreamTitle = null;
    state = const PlayerIdle();
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final playerProvider =
StateNotifierProvider<PlayerNotifier, PlayerState>((ref) {
  return PlayerNotifier();
});