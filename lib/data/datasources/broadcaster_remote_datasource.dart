import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Appels réseau de l'espace diffuseur.
///
/// On lui injecte le Dio *partagé* (dioProvider, avec l'AuthInterceptor) : les
/// routes start / stop / upload exigent le Bearer token, un Dio nu ne suffit pas.
class BroadcasterRemoteDataSource {
  BroadcasterRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> createStream({
    required String title,
    required String description,
    required String mountPoint,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/streams',
      data: {
        'title': title,
        'description': description,
        'mount_point': mountPoint,
      },
    );
    return (res.data!['stream'] as Map<String, dynamic>);
  }

  Future<void> startStream(String streamId) async {
    await _dio.post('/streams/$streamId/start');
  }

  Future<void> stopStream(String streamId) async {
    await _dio.post('/streams/$streamId/stop');
  }

  Future<List<Map<String, dynamic>>> listMyPlaylists() async {
    final res = await _dio.get<Map<String, dynamic>>('/playlists');
    final list = (res.data?['playlists'] as List<dynamic>?) ?? const [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createPlaylist({
    required String title,
    String description = '',
    bool isPublic = false,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/playlists',
      data: {
        'title': title,
        'description': description,
        'is_public': isPublic,
      },
    );
    return res.data!;
  }

  /// [onProgress] suit les octets envoyés pour la barre de progression d'upload.
  Future<void> uploadTrack({
    required String playlistId,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String title,
    required String artist,
    required String format,
    void Function(int sent, int total)? onProgress,
  }) async {
    // Web : pas de path → on envoie les bytes. Mobile/desktop : le path suffit.
    final MultipartFile multipart;
    if (fileBytes != null) {
      multipart = MultipartFile.fromBytes(fileBytes, filename: fileName);
    } else if (filePath != null) {
      multipart = await MultipartFile.fromFile(filePath, filename: fileName);
    } else {
      throw ArgumentError('Aucun fichier fourni (ni bytes ni path)');
    }

    final form = FormData.fromMap({
      'title': title,
      'artist': artist,
      'format': format,
      'file': multipart,
    });

    await _dio.post(
      '/playlists/$playlistId/tracks',
      data: form,
      onSendProgress: onProgress,
    );
  }
}