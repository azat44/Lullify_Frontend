import 'package:lullify_mobile/domain/entities/stream.dart';

class StreamModel extends AudioStream {
  const StreamModel({
    required super.id,
    required super.ownerId,
    required super.title,
    required super.mountPoint,
    super.description,
    super.status,
    super.listenerCount,
    super.startedAt,
  });

  factory StreamModel.fromJson(Map<String, dynamic> json) {
    return StreamModel(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String?,
      mountPoint: json['mount_point'] as String,
      status: _parseStatus(json['status'] as String?),
      listenerCount: json['listener_count'] as int? ?? 0,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'] as String)
          : null,
    );
  }

  static StreamStatus _parseStatus(String? status) {
    switch (status) {
      case 'live':  return StreamStatus.live;
      case 'ended': return StreamStatus.ended;
      default:      return StreamStatus.offline;
    }
  }
}