import 'package:lullify_mobile/domain/entities/history_entry.dart';

abstract class HistoryRepository {
  Future<List<HistoryEntry>> getMyHistory();

  Future<void> recordListen({
    required String trackTitle,
    required String artist,
    required String streamId,
  });
}