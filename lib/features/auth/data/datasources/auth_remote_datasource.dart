import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/user_entity.dart';
import '../models/user_model.dart';

/// Remote data source for authentication
/// Supports both real Supabase API and mock mode for development
class AuthRemoteDataSource {
  final DioClient dioClient;

  /// Set to true to use mock data instead of real API
  static const bool useMock = false;

  AuthRemoteDataSource({required this.dioClient});

  /// Login by querying the public users table
  Future<Map<String, dynamic>> login({
    required String kodeSekolah,
    required String email,
    required String password,
  }) async {
    if (useMock) {
      return _mockLogin(email: email, password: password, role: UserRole.murid);
    }

    try {
      // 1. Validasi Kode Sekolah dan ambil id_sekolah
      final schoolResponse = await dioClient.get(
        '/schools',
        queryParameters: {
          'id_sekolah': 'eq.$kodeSekolah',
          'select': 'id_sekolah',
        },
      );

      final List schoolData = schoolResponse.data is List ? schoolResponse.data : [];
      if (schoolData.isEmpty) {
        throw const AuthException(message: 'Kode sekolah tidak valid atau tidak terdaftar.');
      }
      final schoolId = schoolData.first['id_sekolah'];

      // 2. Query users table directly based on the provided schema
      final response = await dioClient.get(
        ApiConstants.usersTable,
        queryParameters: {
          'email': 'eq.$email',
          'password_hash': 'eq.$password',
          'id_sekolah': 'eq.$schoolId',
          'select': '*',
        },
      );

      final List data = response.data is List ? response.data : [];

      if (data.isEmpty) {
        throw const AuthException(message: 'Email atau password salah, atau Anda tidak terdaftar di sekolah ini.');
      }

      final user = data.first as Map<String, dynamic>;

      // Determine role safely
      final roleStr = (user['role']?.toString() ?? 'Siswa').toLowerCase();
      String mappedRole = 'murid'; // default match UserRole.murid.name
      if (roleStr.contains('guru')) mappedRole = 'guru';
      if (roleStr.contains('orang') || roleStr.contains('tua')) mappedRole = 'orangtua';

      // Simulate a JWT token since we're using a custom table instead of Supabase Auth
      return {
        'access_token': 'simulated_jwt_${user['id']}',
        'refresh_token': null,
        'user': {
          'id': user['id'],
          'email': user['email'],
          'name': user['nama_user'] ?? user['email'], // Field from DB
          'role': mappedRole,
          'avatar_url': user['foto_profile'],
          'id_sekolah': schoolId?.toString(),
          'created_at': user['created_at'],
        },
      };
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const NetworkException(
          message: 'Koneksi timeout. Coba lagi nanti.',
        );
      }
      throw ServerException(
        message: e.message ?? 'Gagal login.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Get current user (mock implementation since we simulate JWT)
  Future<UserModel> getUser(String accessToken) async {
    if (useMock) {
      return _mockGetUser(accessToken);
    }
    
    // In a real custom JWT scenario, we would verify the token.
    // For now, if they have a token, we rely on the repository's local cache
    throw const ServerException(message: 'Use local cache', statusCode: 400);
  }

  /// Logout from Supabase
  Future<void> logout(String accessToken) async {
    if (useMock) return;

    try {
      final authDio = dioClient.authDio;
      authDio.options.headers['Authorization'] = 'Bearer $accessToken';
      await authDio.post(ApiConstants.logoutEndpoint);
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Gagal logout.',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ═══════════════════════════════════════════════
  // ══ MOCK DATA (untuk development/simulasi) ═══
  // ═══════════════════════════════════════════════

  Future<Map<String, dynamic>> _mockLogin({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 1200));

    // Mock accounts
    final mockAccounts = {
      'murid@sekolah.com': {
        'password': 'password123',
        'role': 'murid',
        'name': 'Ahmad Fauzi',
        'id': 'usr_murid_001',
      },
      'orangtua@sekolah.com': {
        'password': 'password123',
        'role': 'orangtua',
        'name': 'Budi Santoso',
        'id': 'usr_orangtua_001',
      },
      'guru@sekolah.com': {
        'password': 'password123',
        'role': 'guru',
        'name': 'Ibu Sari Dewi',
        'id': 'usr_guru_001',
      },
    };

    final account = mockAccounts[email.toLowerCase()];

    if (account == null || account['password'] != password) {
      throw const AuthException(message: 'Email atau password salah.');
    }

    if (account['role'] != role.name) {
      throw AuthException(
        message:
            'Akun ini terdaftar sebagai ${account['role']}, bukan ${role.displayName}.',
      );
    }

    return {
      'access_token': 'mock_jwt_${account['id']}_${DateTime.now().millisecondsSinceEpoch}',
      'refresh_token': 'mock_refresh_${account['id']}',
      'token_type': 'bearer',
      'expires_in': 3600,
      'user': {
        'id': account['id'],
        'email': email,
        'name': account['name'],
        'role': account['role'],
        'avatar_url': null,
        'created_at': '2025-01-01T00:00:00Z',
      },
    };
  }

  UserModel _mockGetUser(String accessToken) {
    if (accessToken.contains('murid')) {
      return const UserModel(
        id: 'usr_murid_001',
        email: 'murid@sekolah.com',
        name: 'Ahmad Fauzi',
        role: UserRole.murid,
      );
    } else if (accessToken.contains('orangtua')) {
      return const UserModel(
        id: 'usr_orangtua_001',
        email: 'orangtua@sekolah.com',
        name: 'Budi Santoso',
        role: UserRole.orangtua,
      );
    } else {
      return const UserModel(
        id: 'usr_guru_001',
        email: 'guru@sekolah.com',
        name: 'Ibu Sari Dewi',
        role: UserRole.guru,
      );
    }
  }
}
