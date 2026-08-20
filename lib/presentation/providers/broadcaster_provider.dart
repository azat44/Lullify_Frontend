import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/network/dio_client.dart';
import 'package:lullify_mobile/data/datasources/broadcaster_remote_datasource.dart';
import 'package:lullify_mobile/data/repositories/broadcaster_repository_impl.dart';
import 'package:lullify_mobile/domain/repositories/broadcaster_repository.dart';

final broadcasterRepositoryProvider = Provider<BroadcasterRepository>((ref) {
  final dio = ref.read(dioProvider);
  return BroadcasterRepositoryImpl(BroadcasterRemoteDataSource(dio));
});

class BroadcasterState {
  const BroadcasterState({
    this.stream,
    this.playlists = const [],
    this.busy = false,
    this.uploadProgress,
    this.error,
    this.notice,
  });

  final BroadcasterStream? stream;
  final List<BroadcasterPlaylist> playlists;
  final bool busy;
  final double? uploadProgress;
  final String? error;
  final String? notice;

  bool get isLive => stream?.isLive ?? false;

  BroadcasterState copyWith({
    BroadcasterStream? stream,
    List<BroadcasterPlaylist>? playlists,
    bool? busy,
    double? uploadProgress,
    String? error,
    String? notice,
    bool clearUploadProgress = false,
    bool clearMessages = false,
  }) {
    return BroadcasterState(
      stream: stream ?? this.stream,
      playlists: playlists ?? this.playlists,
      busy: busy ?? this.busy,
      uploadProgress:
          clearUploadProgress ? null : (uploadProgress ?? this.uploadProgress),
      error: clearMessages ? null : (error ?? this.error),
      notice: clearMessages ? null : (notice ?? this.notice),
    );
  }
}

class BroadcasterNotifier extends StateNotifier<BroadcasterState> {
  BroadcasterNotifier(this._repo) : super(const BroadcasterState()) {
    loadPlaylists();
  }

  final BroadcasterRepository _repo;

  Future<void> loadPlaylists() async {
    try {
      final playlists = await _repo.listMyPlaylists();
      state = state.copyWith(playlists: playlists);
    } catch (_) {
      // Pas bloquant pour le dashboard : on laisse la liste vide.
    }
  }

  Future<void> createStream({
    required String title,
    required String description,
    required String mountPoint,
  }) async {
    state = state.copyWith(busy: true, clearMessages: true);
    try {
      final stream = await _repo.createStream(
        title: title,
        description: description,
        mountPoint: mountPoint,
      );
      state = state.copyWith(stream: stream, busy: false, notice: 'Stream créé');
    } catch (e) {
      state = state.copyWith(busy: false, error: _humanize(e));
    }
  }

  Future<void> toggleLive() async {
    final current = state.stream;
    if (current == null) return;

    state = state.copyWith(busy: true, clearMessages: true);
    try {
      if (current.isLive) {
        await _repo.stopStream(current.id);
        state = state.copyWith(
          stream: current.copyWith(status: BroadcastStatus.offline),
          busy: false,
          notice: 'Stream arrêté',
        );
      } else {
        await _repo.startStream(current.id);
        state = state.copyWith(
          stream: current.copyWith(status: BroadcastStatus.live),
          busy: false,
          notice: 'En direct 🔴',
        );
      }
    } catch (e) {
      state = state.copyWith(busy: false, error: _humanize(e));
    }
  }

  Future<BroadcasterPlaylist?> createPlaylist(String title) async {
    state = state.copyWith(busy: true, clearMessages: true);
    try {
      final playlist = await _repo.createPlaylist(title);
      state = state.copyWith(
        playlists: [...state.playlists, playlist],
        busy: false,
        notice: 'Playlist créée',
      );
      return playlist;
    } catch (e) {
      state = state.copyWith(busy: false, error: _humanize(e));
      return null;
    }
  }

  Future<void> uploadTrack({
    required String playlistId,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String title,
    required String artist,
    required String format,
  }) async {
    state = state.copyWith(busy: true, uploadProgress: 0, clearMessages: true);
    try {
      await _repo.uploadTrack(
        playlistId: playlistId,
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        title: title,
        artist: artist,
        format: format,
        onProgress: (sent, total) {
          if (total > 0) {
            state = state.copyWith(uploadProgress: sent / total);
          }
        },
      );
      state = state.copyWith(
        busy: false,
        clearUploadProgress: true,
        notice: 'Track uploadée ✓',
      );
    } catch (e) {
      state = state.copyWith(
        busy: false,
        clearUploadProgress: true,
        error: _humanize(e),
      );
    }
  }

  void consumeMessages() {
    state = state.copyWith(clearMessages: true);
  }

  String _humanize(Object e) {
    final msg = e.toString();
    if (msg.contains('409')) return 'Action impossible dans cet état';
    if (msg.contains('403')) return "Tu n'es pas le propriétaire de ce stream";
    if (msg.contains('401')) return 'Session expirée, reconnecte-toi';
    if (msg.contains('413')) return 'Fichier trop lourd';
    return 'Une erreur est survenue';
  }
}

final broadcasterProvider =
    StateNotifierProvider<BroadcasterNotifier, BroadcasterState>((ref) {
  return BroadcasterNotifier(ref.read(broadcasterRepositoryProvider));
});