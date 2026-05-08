import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';
import '../constants/api_constants.dart';

/// Interceptor that automatically attaches JWT token to requests
/// and handles 401 Unauthorized responses
class AuthInterceptor extends Interceptor {
  final SecureStorageService storageService;

  AuthInterceptor({required this.storageService});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Get stored access token
    final token = await storageService.getAccessToken();

    if (token != null && token.isNotEmpty) {
      // Jika token adalah simulasi (bukan JWT asli dari Supabase Auth), 
      // gunakan anon key agar PostgREST tidak menolak request dengan 401.
      if (token.startsWith('simulated_jwt_') || token.startsWith('mock_jwt_')) {
        options.headers['Authorization'] = 'Bearer ${ApiConstants.supabaseAnonKey}';
      } else {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } else {
       options.headers['Authorization'] = 'Bearer ${ApiConstants.supabaseAnonKey}';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Token expired or invalid — clear stored tokens
      await storageService.deleteTokens();

      // TODO: Could implement token refresh logic here
      // For now, the router guard will redirect to login
    }

    handler.next(err);
  }
}
