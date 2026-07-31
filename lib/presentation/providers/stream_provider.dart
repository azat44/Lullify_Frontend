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
      // TODO: remplacer par _repository.getActiveStreams() quand le backend sera prêt
      await Future.delayed(const Duration(milliseconds: 800));
      final streams = _mockStreams();
      state = StreamListLoaded(streams);
    } catch (e) {
      state = const StreamListError('Failed to load streams');
    }
  }

  Future<void> refresh() => loadStreams();

  List<AudioStream> _mockStreams() {
    return [
      AudioStream(
        id: '1',
        ownerId: 'user-1',
        title: 'Chill Lofi Beats',
        description: 'Study & relax vibes',
        mountPoint: '/stream/chill',
        status: StreamStatus.live,
        listenerCount: 42,
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      AudioStream(
        id: '2',
        ownerId: 'user-2',
        title: 'Vaporwave Dreams',
        description: '80s aesthetic radio',
        mountPoint: '/stream/vapor',
        status: StreamStatus.live,
        listenerCount: 128,
        startedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      AudioStream(
        id: '3',
        ownerId: 'user-3',
        title: 'Late Night Study',
        description: 'Focus and deep work',
        mountPoint: '/stream/study',
        status: StreamStatus.offline,
      ),
    ];
  }
}

final streamListProvider =
    StateNotifierProvider<StreamListNotifier, StreamListState>((ref) {
  return StreamListNotifier(ref.read(streamRepositoryProvider));
});