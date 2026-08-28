import 'package:lullify_mobile/domain/entities/favorite.dart';

abstract class FavoriteRepository {
  Future<List<Favorite>> getMyFavorites();
  Future<void> addFavorite(String streamId);
  Future<void> removeFavorite(String streamId);
}