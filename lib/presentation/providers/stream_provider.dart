import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/data/datasources/stream_remote_datasource.dart';
import 'package:lullify_mobile/data/repositories/stream_repository_impl.dart';
import 'package:lullify_mobile/domain/entities/stream.dart';
import 'package:lullify_mobile/domain/repositories/stream_repository.dart';

final streamRemoteDataSourceProvider = Provider<StreamRemoteDataSource>(
  (_) => StreamRemoteDataSource(),
);

final streamRepositoryProvider = Provider<StreamRepository>((ref) {
  return StreamRepositoryImpl(
    remoteDataSource: ref.read(streamRemoteDataSourceProvider),
  );
});

sealed class StreamListState {
  const StreamListState();
}
class StreamListInitial extends StreamListState { const StreamListInitial(); }
class StreamListLoading extends StreamListState { const StreamListLoading(); }
class StreamListLoaded  extends StreamListState {
  const StreamListLoaded(this.streams);
  final List<AudioStream> streams;
}
class StreamListError   extends StreamListState {
  const StreamListError(this.message);
  final String message;
}

class StreamListNotifier extends StateNotifier<StreamListState> {
  StreamListNotifier(this._repository) : super(const StreamListInitial()) {
    loadStreams();
  }

  final StreamRepository _repository;

  Future<void> loadStreams() async {
    state = const StreamListLoading();
    try {
      final streams = await _repository.getActiveStreams();
      state = StreamListLoaded(streams);
    } catch (e) {
      state = const StreamListError('Failed to load streams');
    }
  }

  Future<void> refresh() => loadStreams();
}

final streamListProvider =
    StateNotifierProvider<StreamListNotifier, StreamListState>((ref) {
  return StreamListNotifier(ref.read(streamRepositoryProvider));
});