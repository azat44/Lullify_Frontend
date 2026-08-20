import 'dart:typed_data';

import 'package:lullify_mobile/data/datasources/broadcaster_remote_datasource.dart';
import 'package:lullify_mobile/domain/repositories/broadcaster_repository.dart';

class BroadcasterRepositoryImpl implements BroadcasterRepository {
  BroadcasterRepositoryImpl(this._remote);

  final BroadcasterRemoteDataSource _remote;

  @override
  Future<BroadcasterStream> createStream({
    required String title,
    required String description,
    required String mountPoint,
  }) async {
    final json = await _remote.createStream(
      title: title,
      description: description,
      mountPoint: mountPoint,
    );
    return _streamFromJson(json);
  }

  @override
  Future<void> startStream(String streamId) => _remote.startStream(streamId);

  @override
  Future<void> stopStream(String streamId) => _remote.stopStream(streamId);

  @override
  Future<List<BroadcasterPlaylist>> listMyPlaylists() async {
    final list = await _remote.listMyPlaylists();
    return list.map(_playlistFromJson).toList();
  }

  @override
  Future<BroadcasterPlaylist> createPlaylist(String title) async {
    final json = await _remote.createPlaylist(title: title);
    return _playlistFromJson(json);
  }

  @override
  Future<void> uploadTrack({
    required String playlistId,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String title,
    required String artist,
    required String format,
    void Function(int sent, int total)? onProgress,
  }) {
    return _remote.uploadTrack(
      playlistId: playlistId,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      title: title,
      artist: artist,
      format: format,
      onProgress: onProgress,
    );
  }

  // ── mapping JSON → domaine ─────────────────────────────
  BroadcasterStream _streamFromJson(Map<String, dynamic> json) {
    return BroadcasterStream(
      id: json['id'] as String,
      title: json['title'] as String,
      mountPoint: json['mount_point'] as String? ?? '',
      status: broadcastStatusFromString(json['status'] as String?),
    );
  }

  BroadcasterPlaylist _playlistFromJson(Map<String, dynamic> json) {
    return BroadcasterPlaylist(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Sans titre',
    );
  }
}