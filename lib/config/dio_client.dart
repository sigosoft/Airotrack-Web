import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late final Dio _dio;
  String? _token;

  factory DioClient() {
    return _instance;
  }

  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          _token ??= await _loadToken();
          if (_token != null && _token!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_token';
          }

          if (_shouldLog(options.path)) {
            final tag = _endpointTag(options.path);
            debugPrint('==================== [$tag CALL] ====================');
            debugPrint('${options.method.toUpperCase()} ${options.uri}');
            debugPrint('Headers: ${options.headers}');
            if (options.queryParameters.isNotEmpty) {
              debugPrint('Query Parameters: ${options.queryParameters}');
            }
            if (options.data != null) {
              debugPrint('Request Body: ${options.data}');
            }
            debugPrint('====================================================');
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          final path = response.requestOptions.path;
          if (_shouldLog(path)) {
            final tag = _endpointTag(path);
            debugPrint(
              '==================== [$tag RESPONSE] ====================',
            );
            debugPrint('URL: ${response.requestOptions.uri}');
            debugPrint('Status Code: ${response.statusCode}');
            try {
              debugPrint(
                'Response Body:\n${const JsonEncoder.withIndent('  ').convert(response.data)}',
              );
            } catch (_) {
              debugPrint('Response Body: ${response.data}');
            }
            debugPrint(
              '========================================================',
            );
          }
          handler.next(response);
        },
        onError: (DioException e, handler) {
          final path = e.requestOptions.path;
          if (_shouldLog(path)) {
            final tag = _endpointTag(path);
            debugPrint(
              '==================== [$tag ERROR] ====================',
            );
            debugPrint('URL: ${e.requestOptions.uri}');
            debugPrint('Status Code: ${e.response?.statusCode}');
            debugPrint('Headers: ${e.requestOptions.headers}');
            debugPrint('Error: ${e.message}');
            if (e.response?.data != null) {
              try {
                debugPrint(
                  'Error Data:\n${const JsonEncoder.withIndent('  ').convert(e.response?.data)}',
                );
              } catch (_) {
                debugPrint('Error Data: ${e.response?.data}');
              }
            }
            debugPrint(
              '======================================================',
            );
          }
          handler.next(e);
        },
      ),
    );
  }

  static bool _shouldLog(String path) {
    if (path.contains(ApiEndPoints.profile)) return true;
    if (path.contains(ApiEndPoints.dashboard)) return true;
    return false;
  }

  static String _endpointTag(String path) {
    if (path.contains(ApiEndPoints.profile)) return 'PROFILE';
    if (path.contains(ApiEndPoints.dashboard)) return 'DASHBOARD';
    return 'API';
  }

  Dio get dio => _dio;

  Future<void> updateToken(String token) async {
    _token = token;
    debugPrint('==================== [AUTH TOKEN] ====================');
    debugPrint('Token: $token');
    debugPrint('======================================================');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    _token ??= await _loadToken();
    return _token;
  }

  Future<String?> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      debugPrint('==================== [AUTH TOKEN] ====================');
      debugPrint('Token: $token');
      debugPrint('======================================================');
    }
    return token;
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> post(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: body,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> put(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: body,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response> delete(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: body,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
