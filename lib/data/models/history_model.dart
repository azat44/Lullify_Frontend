import 'package:lullify_mobile/domain/entities/history_entry.dart';

class HistoryModel extends HistoryEntry {
  const HistoryModel({
    required super.id,
    required super.userId,
    required super.trackTitle,
    required super.artist,
    required super.playedAt,
    super.streamId,
  });

  // Contrat back (history_handler.go / historyToJSON) :
  // { id, user_id, track_title, artist, played_at (RFC3339), stream_id? }
  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      trackTitle: json['track_title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      playedAt: DateTime.parse(json['played_at'] as String),
      streamId: json['stream_id'] as String?,
    );
  }
}