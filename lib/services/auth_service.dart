import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'base_api_service.dart';
import 'package:logging/logging.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService extends BaseApiService {
  final SharedPreferences _prefs;
  final _logger = Logger('AuthService');
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/calendar.readonly',
      "https://www.googleapis.com/auth/calendar.events.readonly",
      "https://www.googleapis.com/auth/calendar.events"
    ],
    serverClientId:
        '907265289147-15moogodguhegvpv5f1du2saees8f7ad.apps.googleusercontent.com',
  );

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

  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      print('Google sign-in start');
      final account = await _googleSignIn.signIn();
      final email = account?.email;
      final password = "12345678";
      print('Google sign-in account: $account');
      if (account == null) return null;
      final auth = await account.authentication;
      print('Google sign-in auth: $auth.');
      final accessToken = auth.accessToken;
      final refreshToken = "xyz";

      print('Google sign-in accessToken: $accessToken');
      final idToken = auth.idToken;
      print('Google sign-in idToken: $idToken');
      if (idToken == null) return null;
      // Send the ID token to backend and get app token
      print('Google sign-in idToken: $idToken');
      final response = await googleLoginWithToken(
          idToken, accessToken!, email!, password, refreshToken!);
      if (response != null && response['access_token'] != null) {
        await _saveTokens(response['access_token']);
      }
      return response;
    } catch (e) {
      _logger.severe('Google sign-in error: $e');
      print('Google sign-in error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> googleLoginWithToken(
      String idToken,
      String accessToken,
      String email,
      String password,
      String refreshToken) async {
    try {
      final response = await post(
        AppConfig.googleLoginEndpoint,
        body: {
          'id_token': idToken,
          'email': email,
          'password': password,
          'google_access_token': accessToken,
          'google_refresh_token': refreshToken,
        },
        requiresAuth: false,
      );
      return response;
    } catch (e) {
      _logger.severe('Google login API error: $e');
      return null;
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }
}
