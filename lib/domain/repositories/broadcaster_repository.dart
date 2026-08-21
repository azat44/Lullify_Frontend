import 'dart:typed_data';

enum BroadcastStatus { offline, live, ended }

BroadcastStatus broadcastStatusFromString(String? s) {
  switch (s) {
    case 'live':
      return BroadcastStatus.live;
    case 'ended':
      return BroadcastStatus.ended;
    default:
      return BroadcastStatus.offline;
  }
}

class BroadcasterStream {
  const BroadcasterStream({
    required this.id,
    required this.title,
    required this.mountPoint,
    required this.status,
  });

  final String id;
  final String title;
  final String mountPoint;
  final BroadcastStatus status;

  bool get isLive => status == BroadcastStatus.live;

  BroadcasterStream copyWith({BroadcastStatus? status}) => BroadcasterStream(
        id: id,
        title: title,
        mountPoint: mountPoint,
        status: status ?? this.status,
      );
}

class BroadcasterPlaylist {
  const BroadcasterPlaylist({required this.id, required this.title});

  final String id;
  final String title;
}

/// Port du domaine : ce dont le dashboard a besoin, sans connaître Dio ni REST.
abstract class BroadcasterRepository {
  Future<BroadcasterStream> createStream({
    required String title,
    required String description,
    required String mountPoint,
  });

  Future<void> startStream(String streamId);

  Future<void> stopStream(String streamId);

  Future<List<BroadcasterPlaylist>> listMyPlaylists();

  Future<BroadcasterPlaylist> createPlaylist(String title);

  Future<void> uploadTrack({
    required String playlistId,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String title,
    required String artist,
    required String format,
    void Function(int sent, int total)? onProgress,
  });
}