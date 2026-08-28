import 'package:equatable/equatable.dart';

class Favorite extends Equatable {
  const Favorite({
    required this.id,
    required this.userId,
    required this.streamId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String streamId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, userId, streamId, createdAt];
}