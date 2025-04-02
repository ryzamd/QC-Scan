// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';
import 'package:flutter/foundation.dart';

class DioClient {
  late Dio dio;
  final Logger logger = Logger();

  DioClient() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
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
              'Data: ${options.data}',
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

  // Add token to request headers
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
    debugPrint('Set Auth Token: Bearer $token');
  }

  // Clear token from request headers
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
    debugPrint('Cleared Auth Token');
  }

  // Thêm method để kiểm tra token
  bool hasValidToken() {
    return dio.options.headers['Authorization'] != null;
  }
}
