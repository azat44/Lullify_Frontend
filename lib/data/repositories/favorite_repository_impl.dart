import 'package:lullify_mobile/data/datasources/favorite_remote_datasource.dart';
import 'package:lullify_mobile/domain/entities/favorite.dart';
import 'package:lullify_mobile/domain/repositories/favorite_repository.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  FavoriteRepositoryImpl({required FavoriteRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final FavoriteRemoteDataSource _remote;

  @override
  Future<List<Favorite>> getMyFavorites() => _remote.getMyFavorites();

  @override
  Future<void> addFavorite(String streamId) => _remote.addFavorite(streamId);

  @override
  Future<void> removeFavorite(String streamId) => _remote.removeFavorite(streamId);
}