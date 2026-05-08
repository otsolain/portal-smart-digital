import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Concrete implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final SecureStorageService storageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
  });

  @override
  Future<AuthResult> login({
    required String kodeSekolah,
    required String email,
    required String password,
  }) async {
    final response = await remoteDataSource.login(
      kodeSekolah: kodeSekolah,
      email: email,
      password: password,
    );

    final accessToken = response['access_token'] as String;
    final refreshToken = response['refresh_token'] as String?;
    final user = UserModel.fromAuthResponse(response);

    // Save tokens and user data to secure storage
    await storageService.saveAccessToken(accessToken);
    if (refreshToken != null) {
      await storageService.saveRefreshToken(refreshToken);
    }
    await storageService.saveUserId(user.id);
    await storageService.saveUserEmail(user.email);
    await storageService.saveUserName(user.name);
    await storageService.saveUserRole(user.role.name);
    if (user.idSekolah != null) {
      await storageService.saveIdSekolah(user.idSekolah!);
    }

    return AuthResult(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  @override
  Future<void> logout() async {
    final token = await storageService.getAccessToken();
    if (token != null) {
      try {
        await remoteDataSource.logout(token);
      } catch (_) {
        // Ignore logout API errors — clear local data regardless
      }
    }

    final rememberMe = await storageService.getRememberMe();
    if (rememberMe) {
      // Keep email and role for convenience, clear session
      await storageService.clearSession();
    } else {
      await storageService.clearAll();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await storageService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final token = await storageService.getAccessToken();
    if (token == null || token.isEmpty) return null;

    try {
      return await remoteDataSource.getUser(token);
    } catch (_) {
      // If we can't reach the server, build user from stored data
      final id = await storageService.getUserId();
      final email = await storageService.getUserEmail();
      final name = await storageService.getUserName();
      final roleStr = await storageService.getUserRole();
      final idSekolah = await storageService.getIdSekolah();

      if (id != null && email != null && name != null && roleStr != null) {
        return UserModel(
          id: id,
          email: email,
          name: name,
          role: UserRole.fromString(roleStr),
          idSekolah: idSekolah,
        );
      }
      return null;
    }
  }
}
