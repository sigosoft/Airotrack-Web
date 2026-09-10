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
          debugPrint(
            '==================== [DIO API REQUEST] ====================',
          );
          debugPrint('🌐 METHOD: ${options.method}');
          debugPrint('🌐 URI: ${options.uri}');
          debugPrint('🔑 TOKEN: ${_token ?? "NO TOKEN"}');
          debugPrint('📋 HEADERS: ${options.headers}');
          if (options.data != null) {
            debugPrint('📦 REQUEST DATA: ${options.data}');
          }
          debugPrint(
            '==========================================================',
          );
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            '==================== [DIO API RESPONSE] ====================',
          );
          debugPrint('✅ STATUS CODE: ${response.statusCode}');
          debugPrint('🌐 URI: ${response.requestOptions.uri}');
          debugPrint('📦 RESPONSE DATA: ${response.data}');
          debugPrint(
            '==========================================================',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          debugPrint(
            '==================== [DIO API ERROR] ====================',
          );
          debugPrint('❌ TYPE: ${e.type}');
          debugPrint('🌐 URI: ${e.requestOptions.uri}');
          debugPrint('⚠️ STATUS CODE: ${e.response?.statusCode}');
          debugPrint('💬 MESSAGE: ${e.message}');
          debugPrint('📦 ERROR PAYLOAD: ${e.response?.data}');
          debugPrint(
            '==========================================================',
          );
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  void updateToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    _token ??= await _loadToken();
    return _token;
  }

  Future<String?> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
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
