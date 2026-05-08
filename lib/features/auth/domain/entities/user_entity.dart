import 'package:equatable/equatable.dart';

/// User roles in the application
enum UserRole {
  murid,
  orangtua,
  guru;

  String get displayName {
    switch (this) {
      case UserRole.murid:
        return 'Siswa';
      case UserRole.orangtua:
        return 'Orang Tua';
      case UserRole.guru:
        return 'Guru';
    }
  }

  int get iconCodePoint {
    switch (this) {
      case UserRole.murid:
        return 0xe559; // Icons.school
      case UserRole.orangtua:
        return 0xe7ef; // Icons.people
      case UserRole.guru:
        return 0xe0c9; // Icons.assignment_ind
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'murid':
      case 'student':
        return UserRole.murid;
      case 'orangtua':
      case 'parent':
        return UserRole.orangtua;
      case 'guru':
      case 'teacher':
        return UserRole.guru;
      default:
        return UserRole.murid;
    }
  }
}

/// User entity — core domain object
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? avatarUrl;
  final String? idSekolah;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.idSekolah,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, name, role, avatarUrl, idSekolah, createdAt];
}
