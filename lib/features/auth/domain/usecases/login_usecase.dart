import '../repositories/auth_repository.dart';

/// Use case: Login a user with email, password, and role
class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  Future<AuthResult> call({
    required String kodeSekolah,
    required String email,
    required String password,
  }) async {
    return repository.login(
      kodeSekolah: kodeSekolah,
      email: email,
      password: password,
    );
  }
}
