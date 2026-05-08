import '../repositories/auth_repository.dart';

/// Use case: Logout the current user
class LogoutUseCase {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  Future<void> call() {
    return repository.logout();
  }
}
