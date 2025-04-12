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
          return true;
        },
      ),
    );

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

  Future<void> setupTokenInterceptorAsync(TokenInterceptor interceptor) async {

    if (_tokenInterceptor != null) {
      dio.interceptors.remove(_tokenInterceptor);
    }
    
    _tokenInterceptor = interceptor;
    dio.interceptors.add(_tokenInterceptor!);
    debugPrint('Token interceptor set up');
  }

  Future<void> setAuthTokenAsync(String token) async {
    dio.options.headers['Authorization'] = 'Bearer $token';
    debugPrint('Set Auth Token: Bearer $token');
  }

  Future<void> clearAuthTokenAsync() async {
    dio.options.headers.remove('Authorization');
    debugPrint('Cleared Auth Token');
  }

  Future<bool> hasValidTokenAsync() async {
    return dio.options.headers['Authorization'] != null;
  }
}