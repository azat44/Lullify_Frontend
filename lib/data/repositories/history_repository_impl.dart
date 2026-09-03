import 'package:lullify_mobile/data/datasources/history_remote_datasource.dart';
import 'package:lullify_mobile/domain/entities/history_entry.dart';
import 'package:lullify_mobile/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({required HistoryRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final HistoryRemoteDataSource _remote;

  @override
  Future<List<HistoryEntry>> getMyHistory() => _remote.getMyHistory();

  @override
  Future<void> recordListen({
    required String trackTitle,
    required String artist,
    required String streamId,
  }) =>
      _remote.recordListen(
        trackTitle: trackTitle,
        artist: artist,
        streamId: streamId,
      );
}