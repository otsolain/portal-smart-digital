import '../../domain/entities/user_entity.dart';

/// User model — data layer representation with JSON serialization
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.role,
    super.avatarUrl,
    super.idSekolah,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ??
          json['user_metadata']?['name'] as String? ??
          json['email'] as String? ??
          '',
      role: UserRole.fromString(
        json['role'] as String? ??
            json['user_metadata']?['role'] as String? ??
            'murid',
      ),
      avatarUrl: json['avatar_url'] as String? ??
          json['user_metadata']?['avatar_url'] as String?,
      idSekolah: json['id_sekolah'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.name,
      'avatar_url': avatarUrl,
      'id_sekolah': idSekolah,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Create from Supabase auth response
  factory UserModel.fromAuthResponse(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? json;
    return UserModel.fromJson(user);
  }
}
