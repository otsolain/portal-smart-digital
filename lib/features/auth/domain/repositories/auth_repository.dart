import '../entities/user_entity.dart';

/// Auth repository interface — domain layer contract
abstract class AuthRepository {
  /// Login with email, password, and selected role
  Future<AuthResult> login({
    required String kodeSekolah,
    required String email,
    required String password,
  });

  /// Logout current user
  Future<void> logout();

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated();

  /// Get current authenticated user
  Future<UserEntity?> getCurrentUser();
}

/// Result object for auth operations
class AuthResult {
  final UserEntity user;
  final String accessToken;
  final String? refreshToken;

  const AuthResult({
    required this.user,
    required this.accessToken,
    this.refreshToken,
  });
}
