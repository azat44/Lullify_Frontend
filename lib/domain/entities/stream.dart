import 'package:equatable/equatable.dart';

enum StreamStatus { offline, live, ended }

class AudioStream extends Equatable {
  const AudioStream({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.mountPoint,
    this.description,
    this.status = StreamStatus.offline,
    this.listenerCount = 0,
    this.startedAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final StreamStatus status;
  final String mountPoint;
  final int listenerCount;
  final DateTime? startedAt;

  bool get isLive => status == StreamStatus.live;

  @override
  List<Object?> get props => [id, ownerId, title, description, status, mountPoint, listenerCount, startedAt];
}
