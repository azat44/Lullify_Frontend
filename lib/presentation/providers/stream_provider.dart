import 'dart:async';

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
    _startPolling();
  }

  final StreamRepository _repository;
  Timer? _pollTimer;

  static const _pollInterval = Duration(seconds: 5);

  // silent = polling : pas de Loading ni d'erreur, on garde l'affichage.
  Future<void> loadStreams({bool silent = false}) async {
    if (!silent) {
      state = const StreamListLoading();
    }
    try {
      final streams = await _repository.getActiveStreams();
      state = StreamListLoaded(streams);
    } catch (_) {
      if (!silent) {
        state = const StreamListError('Failed to load streams');
      }
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      _pollInterval,
      (_) => loadStreams(silent: true),
    );
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refresh() => loadStreams();

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final streamListProvider =
    StateNotifierProvider<StreamListNotifier, StreamListState>((ref) {
  return StreamListNotifier(ref.read(streamRepositoryProvider));
});

// Compteur live d'un stream, dérivé du polling ci-dessus.
final listenerCountProvider = Provider.family<int, String>((ref, streamId) {
  final state = ref.watch(streamListProvider);
  if (state is StreamListLoaded) {
    for (final s in state.streams) {
      if (s.id == streamId) return s.listenerCount;
    }
  }
  return 0;
});


final streamTitleProvider = Provider.family<String, String>((ref, streamId) {
  final state = ref.watch(streamListProvider);
  if (state is StreamListLoaded) {
    for (final s in state.streams) {
      if (s.id == streamId) return s.title;
    }
  }
  return 'Stream ${streamId.substring(0, streamId.length < 8 ? streamId.length : 8)}';
});