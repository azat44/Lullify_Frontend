import 'package:lullify_mobile/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.email,
    required super.username,
    required super.role,
    super.createdAt,
    this.accessToken,
    this.refreshToken,
  });

  final String? accessToken;
  final String? refreshToken;

  factory UserModel.fromJson(Map<String, dynamic> json, {
    String? accessToken,
    String? refreshToken,
  }) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      role: _parseRole(json['role'] as String?),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  static UserRole _parseRole(String? role) {
    switch (role) {
      case 'broadcaster': return UserRole.broadcaster;
      case 'admin':       return UserRole.admin;
      case 'user':        return UserRole.user;
      default:            return UserRole.anonymous;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'username': username,
    'role': role.name,
    'created_at': createdAt?.toIso8601String(),
  };
}