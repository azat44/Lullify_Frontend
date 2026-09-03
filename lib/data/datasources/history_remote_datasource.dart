import 'package:dio/dio.dart';
import 'package:lullify_mobile/data/models/history_model.dart';


class HistoryRemoteDataSource {
  HistoryRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<HistoryModel>> getMyHistory() async {
    final response = await _dio.get('/history');
    final data = response.data as Map<String, dynamic>;
    final entries = data['history'] as List<dynamic>? ?? const [];
    return entries
        .map((json) => HistoryModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Enregistre le début d'écoute d'un stream. À appeler une fois quand la
  /// lecture démarre (le backend n'a pas besoin d'un ping en continu).
  Future<void> recordListen({
    required String trackTitle,
    required String artist,
    required String streamId,
  }) async {
    await _dio.post('/history', data: {
      'track_title': trackTitle,
      'artist': artist,
      'stream_id': streamId,
    });
  }
}