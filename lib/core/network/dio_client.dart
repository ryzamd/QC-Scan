// lib/core/network/dio_client.dart
import 'package:architecture_scan_app/core/network/token_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  late Dio dio;
  final Logger logger = Logger();
  TokenInterceptor? _tokenInterceptor;

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          // Don't throw errors here - let the interceptors handle them
          return true;
        },
      ),
    );

    // Add logging interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          try {
            logger.d(
              'REQUEST[${options.method}] => PATH: ${options.path}\n'
              'Headers: ${options.headers}\n'
              'Data: ${options.data}\n'
              'QueryParams: ${options.queryParameters}'
            );
            handler.next(options);
          } catch (e) {
            debugPrint('Dio interceptor error: $e');
            handler.reject(DioException(requestOptions: options, error: e));
          }
        },
        onResponse: (response, handler) {
          logger.d(
            'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}\n'
            'Data: ${response.data}',
          );
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          logger.e(
            'ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}\n'
            'Message: ${e.message}\n'
            'Data: ${e.response?.data}',
          );
          return handler.next(e);
        },
      ),
    );
  }

  // Set up token interceptor (called after repository is created)
  void setupTokenInterceptor(TokenInterceptor interceptor) {
    // Remove existing token interceptor if any
    if (_tokenInterceptor != null) {
      dio.interceptors.remove(_tokenInterceptor);
    }
    
    // Add the new token interceptor
    _tokenInterceptor = interceptor;
    dio.interceptors.add(_tokenInterceptor!);
    debugPrint('Token interceptor set up');
  }

  // Methods below kept for backward compatibility
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
    debugPrint('Set Auth Token: Bearer $token');
  }

  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
    debugPrint('Cleared Auth Token');
  }

  bool hasValidToken() {
    return dio.options.headers['Authorization'] != null;
  }
}