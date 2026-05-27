import 'package:equatable/equatable.dart';

class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.ownerId,
    required this.title,
    this.isPublic = true,
    this.trackCount = 0,
    this.createdAt,
  });

  final String id;
  final String ownerId;
  final String title;
  final bool isPublic;
  final int trackCount;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, ownerId, title, isPublic, trackCount, createdAt];
}
