import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'base_api_service.dart';
import 'package:logging/logging.dart';

class AuthService extends BaseApiService {
  final SharedPreferences _prefs;
  final _logger = Logger('AuthService');

  AuthService({
    required SharedPreferences prefs,
    String? baseUrl,
  })  : _prefs = prefs,
        super(baseUrl: baseUrl);

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await post(
        AppConfig.loginEndpoint,
        body: {
          'email': email,
          'password': password,
        },
        requiresAuth: false,
      );
      print('Login response: $response');
      await _saveTokens(response['access_token']);

      return response;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await post(
        AppConfig.registerEndpoint,
        body: {
          'email': email,
          'password': password,
          'name': name,
        },
        requiresAuth: false,
      );

      await _saveTokens(response['access_token']);

      return response;
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // await post(AppConfig.logoutEndpoint);
      await _clearTokens();
    } catch (e) {
      // Even if the API call fails, clear local tokens
      await _clearTokens();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = _prefs.getString(AppConfig.refreshTokenKey);
      if (refreshToken == null) {
        throw ApiException(
          statusCode: 401,
          message: AppConfig.authErrorMessage,
        );
      }

      final response = await post(
        AppConfig.refreshTokenEndpoint,
        body: {'refresh_token': refreshToken},
        requiresAuth: false,
      );

      await _saveTokens(
        response['access_token'],
      );

      return response;
    } catch (e) {
      await _clearTokens();
      rethrow;
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await post(
        '/auth/change-password',
        body: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required Map<String, dynamic> profileData,
  }) async {
    try {
      final response = await put(
        AppConfig.profileEndpoint,
        body: profileData,
      );

      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await get(AppConfig.profileEndpoint);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = _prefs.getString(AppConfig.authTokenKey);
    return token != null;
  }

  Future<void> _saveTokens(String accessToken) async {
    await _prefs.setString(AppConfig.authTokenKey, accessToken);
  }

  Future<void> _clearTokens() async {
    await _prefs.remove(AppConfig.authTokenKey);
    await _prefs.remove(AppConfig.refreshTokenKey);
  }

  String? getToken() {
    return _prefs.getString(AppConfig.authTokenKey);
  }
}
