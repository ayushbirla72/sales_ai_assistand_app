import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:salse_ai_assistant/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class BaseApiService {
  final String baseUrl;
  final http.Client _client;

  BaseApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? AppConfig.baseUrl,
        _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = true}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final prefs = await SharedPreferences.getInstance();
      final authService = AuthService(prefs: prefs);
      final accessToken = authService.getToken();
      // TODO: Get token from secure storage
      final token = accessToken;
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );

      final response = await _client
          .get(
            uri,
            headers: await _getHeaders(requiresAuth: requiresAuth),
          )
          .timeout(
            Duration(milliseconds: AppConfig.apiTimeout),
          );

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .post(
            uri,
            headers: await _getHeaders(requiresAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(
            Duration(milliseconds: AppConfig.apiTimeout),
          );
      print('Post response: ${response.body}');

      return _handleResponse(response);
    } catch (e) {
      print('Post error: $e');
      _handleError(e);
    }
  }

  Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .put(
            uri,
            headers: await _getHeaders(requiresAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(
            Duration(milliseconds: AppConfig.apiTimeout),
          );

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  Future<dynamic> delete(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await _client
          .delete(
            uri,
            headers: await _getHeaders(requiresAuth: requiresAuth),
            body: jsonEncode(body),
          )
          .timeout(
            Duration(milliseconds: AppConfig.apiTimeout),
          );

      return _handleResponse(response);
    } catch (e) {
      _handleError(e);
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body == 'null') return null;
      return jsonDecode(response.body);
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: _getErrorMessage(response),
      );
    }
  }

  String _getErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      return body['detail'] ?? AppConfig.serverErrorMessage;
    } catch (e) {
      return AppConfig.serverErrorMessage;
    }
  }

  void _handleError(dynamic error) {
    print('Error: $error');
    if (error is ApiException) {
      throw error;
    } else if (error is http.ClientException) {
      throw ApiException(
        statusCode: 0,
        message: AppConfig.networkErrorMessage,
      );
    } else {
      throw ApiException(
        statusCode: 0,
        message: error.isNotEmpty ? error : AppConfig.serverErrorMessage,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({
    required this.statusCode,
    required this.message,
  });

  @override
  String toString() => 'ApiException: [$statusCode] $message';
}
