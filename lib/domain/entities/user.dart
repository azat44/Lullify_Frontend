import 'package:equatable/equatable.dart';

enum UserRole { anonymous, user, broadcaster, admin }

class User extends Equatable {
  const User({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
    this.createdAt,
  });

  final String id;
  final String email;
  final String username;
  final UserRole role;
  final DateTime? createdAt;

  bool get isBroadcaster => role == UserRole.broadcaster || role == UserRole.admin;
  bool get isAdmin => role == UserRole.admin;

  @override
  List<Object?> get props => [id, email, username, role, createdAt];
}
