import 'package:equatable/equatable.dart';

/// Base failure class
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Server/API failure
class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.code});
}

/// Network connection failure
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Tidak ada koneksi internet. Periksa jaringan Anda.',
  });
}

/// Authentication failure
class AuthFailure extends Failure {
  const AuthFailure({
    super.message = 'Email atau password salah.',
    super.code,
  });
}

/// Cache/Storage failure
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'Gagal mengakses data lokal.',
  });
}

/// Unknown failure
class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'Terjadi kesalahan yang tidak diketahui.',
  });
}
