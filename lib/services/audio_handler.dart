import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class LullifyAudioHandler extends BaseAudioHandler with SeekHandler {
  LullifyAudioHandler() {
    _player = AudioPlayer();
    _listenToPlaybackEvents();
  }

  late final AudioPlayer _player;

  void _listenToPlaybackEvents() {
    _player.playbackEventStream.listen((event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.stop,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0],
        processingState: switch (_player.processingState) {
          ProcessingState.idle      => AudioProcessingState.idle,
          ProcessingState.loading   => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready     => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: 0,
      ));
    });
  }

  Future<void> playHls({
    required String url,
    required String title,
    required String artist,
  }) async {
    mediaItem.add(MediaItem(
      id: url,
      title: title,
      artist: artist,
      playable: true,
    ));

    await _player.setAudioSource(HlsAudioSource(Uri.parse(url)));
    await _player.play();
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  AudioPlayer get player => _player;

  @override
  Future<void> onTaskRemoved() async {
    await stop();
    await super.onTaskRemoved();
  }
}