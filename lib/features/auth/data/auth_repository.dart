import '../../../core/api_client.dart';
import '../../../core/secure_storage.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._secureStorage);

  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  Future<AppUser> register(String email, String password) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'email': email, 'password': password},
    );
    return _persistSession(response.data!);
  }

  Future<AppUser> login(String email, String password) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _persistSession(response.data!);
  }

  /// Restores the session from a token already in secure storage, or returns
  /// null if there is no token or it's no longer valid.
  Future<AppUser?> restoreSession() async {
    final token = await _secureStorage.readToken();
    if (token == null) return null;
    try {
      final response = await _apiClient.dio.get<Map<String, dynamic>>('/auth/me');
      return AppUser.fromJson(response.data!);
    } catch (_) {
      await _secureStorage.deleteToken();
      return null;
    }
  }

  Future<AppUser> loginWithGoogleIdToken(String idToken) async {
    final response = await _apiClient.dio.post<Map<String, dynamic>>('/auth/google', data: {'idToken': idToken});
    return _persistSession(response.data!);
  }

  Future<void> logout() => _secureStorage.deleteToken();

  Future<void> forgotPassword(String email) async {
    await _apiClient.dio.post('/auth/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({required String email, required String code, required String newPassword}) async {
    await _apiClient.dio.post(
      '/auth/reset-password',
      data: {'email': email, 'code': code, 'newPassword': newPassword},
    );
  }

  Future<AppUser> _persistSession(Map<String, dynamic> data) async {
    final token = data['accessToken'] as String;
    await _secureStorage.saveToken(token);
    return AppUser.fromJson(data['user'] as Map<String, dynamic>);
  }
}
