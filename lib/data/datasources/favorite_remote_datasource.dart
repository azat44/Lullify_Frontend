import 'package:dio/dio.dart';
import 'package:lullify_mobile/data/models/favorite_model.dart';

class FavoriteRemoteDataSource {
  FavoriteRemoteDataSource({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<FavoriteModel>> getMyFavorites() async {
    final response = await _dio.get('/favorites');
    final data = response.data as Map<String, dynamic>;
    final entries = data['favorites'] as List<dynamic>? ?? const [];
    return entries
        .map((json) => FavoriteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> addFavorite(String streamId) async {
    await _dio.post('/favorites', data: {'stream_id': streamId});
  }

  Future<void> removeFavorite(String streamId) async {
    await _dio.delete('/favorites/$streamId');
  }
}