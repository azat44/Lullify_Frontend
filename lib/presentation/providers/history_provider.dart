import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lullify_mobile/core/network/dio_client.dart';
import 'package:lullify_mobile/data/datasources/history_remote_datasource.dart';
import 'package:lullify_mobile/data/repositories/history_repository_impl.dart';
import 'package:lullify_mobile/domain/entities/history_entry.dart';
import 'package:lullify_mobile/domain/repositories/history_repository.dart';

final historyRemoteDataSourceProvider = Provider<HistoryRemoteDataSource>(
  // dioProvider = Dio partagé avec AuthInterceptor (Bearer + refresh 401).
  (ref) => HistoryRemoteDataSource(dio: ref.read(dioProvider)),
);

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(
    remoteDataSource: ref.read(historyRemoteDataSourceProvider),
  );
});

// ── État ─────────────────────────────────────────────────
sealed class HistoryState {
  const HistoryState();
}
class HistoryInitial extends HistoryState { const HistoryInitial(); }
class HistoryLoading extends HistoryState { const HistoryLoading(); }
class HistoryLoaded  extends HistoryState {
  const HistoryLoaded(this.entries);
  final List<HistoryEntry> entries;
}
class HistoryError   extends HistoryState {
  const HistoryError(this.message);
  final String message;
}

class HistoryNotifier extends StateNotifier<HistoryState> {
  HistoryNotifier(this._repository) : super(const HistoryInitial()) {
    load();
  }

  final HistoryRepository _repository;

  Future<void> load() async {
    state = const HistoryLoading();
    try {
      final entries = await _repository.getMyHistory();
      state = HistoryLoaded(entries);
    } catch (e) {
      state = const HistoryError('Failed to load listening history');
    }
  }

  Future<void> refresh() => load();
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, HistoryState>((ref) {
  return HistoryNotifier(ref.read(historyRepositoryProvider));
});