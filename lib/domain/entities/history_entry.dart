import 'package:equatable/equatable.dart';

class HistoryEntry extends Equatable {
  const HistoryEntry({
    required this.id,
    required this.userId,
    required this.trackTitle,
    required this.artist,
    required this.playedAt,
    this.streamId,
  });

  final String id;
  final String userId;
  final String trackTitle;
  final String artist;
  final DateTime playedAt;
  final String? streamId;

  @override
  List<Object?> get props =>
      [id, userId, trackTitle, artist, playedAt, streamId];
}