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
}