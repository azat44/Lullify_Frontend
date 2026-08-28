import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/network/dio_client.dart';
import 'package:lullify_mobile/data/datasources/favorite_remote_datasource.dart';
import 'package:lullify_mobile/data/repositories/favorite_repository_impl.dart';
import 'package:lullify_mobile/domain/entities/favorite.dart';
import 'package:lullify_mobile/domain/repositories/favorite_repository.dart';

final favoriteRemoteDataSourceProvider = Provider<FavoriteRemoteDataSource>(
      (ref) => FavoriteRemoteDataSource(dio: ref.read(dioProvider)),
);

final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepositoryImpl(
    remoteDataSource: ref.read(favoriteRemoteDataSourceProvider),
  );
});

sealed class FavoriteState {
  const FavoriteState();
}
class FavoriteInitial extends FavoriteState { const FavoriteInitial(); }
class FavoriteLoading extends FavoriteState { const FavoriteLoading(); }
class FavoriteLoaded  extends FavoriteState {
  const FavoriteLoaded(this.favorites);
  final List<Favorite> favorites;
}
class FavoriteError extends FavoriteState {
  const FavoriteError(this.message);
  final String message;
}

class FavoriteNotifier extends StateNotifier<FavoriteState> {
  FavoriteNotifier(this._repository) : super(const FavoriteInitial()) {
    load();
  }

  final FavoriteRepository _repository;

  Future<void> load() async {
    state = const FavoriteLoading();
    try {
      final favorites = await _repository.getMyFavorites();
      state = FavoriteLoaded(favorites);
    } catch (e) {
      state = const FavoriteError('Failed to load favorites');
    }
  }

  Future<void> refresh() => load();

  Future<void> toggle(String streamId) async {
    final current = state;
    final isCurrentlyFavorite = current is FavoriteLoaded &&
        current.favorites.any((f) => f.streamId == streamId);
    try {
      if (isCurrentlyFavorite) {
        await _repository.removeFavorite(streamId);
      } else {
        await _repository.addFavorite(streamId);
      }
      await load();
    } catch (e) {
      state = const FavoriteError('Failed to update favorite');
    }
  }

  bool isFavorite(String streamId) {
    final current = state;
    if (current is! FavoriteLoaded) return false;
    return current.favorites.any((f) => f.streamId == streamId);
  }
}

final favoriteProvider =
StateNotifierProvider<FavoriteNotifier, FavoriteState>((ref) {
  return FavoriteNotifier(ref.read(favoriteRepositoryProvider));
});