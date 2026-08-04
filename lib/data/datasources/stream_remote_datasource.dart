import 'package:dio/dio.dart';
import 'package:lullify_mobile/core/constants.dart';
import 'package:lullify_mobile/data/models/stream_model.dart';

class StreamRemoteDataSource {
  StreamRemoteDataSource()
      : _dio = Dio(BaseOptions(
          baseUrl: AppConstants.apiBaseUrl,
          connectTimeout: AppConstants.apiTimeout,
          receiveTimeout: AppConstants.apiTimeout,
          headers: {'Content-Type': 'application/json'},
        ));

  final Dio _dio;

  Future<List<StreamModel>> getActiveStreams() async {
    final response = await _dio.get('/streams');
    final data = response.data as Map<String, dynamic>;
    final streams = data['streams'] as List<dynamic>;
    return streams
        .map((json) => StreamModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}