// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../constants/api_constants.dart';

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
          logger.d('REQUEST[${options.method}] => PATH: ${options.path}\n'
              'Headers: ${options.headers}\n'
              'Data: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          logger.d('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}\n'
              'Data: ${response.data}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          logger.e('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}\n'
              'Message: ${e.message}\n'
              'Data: ${e.response?.data}');
          return handler.next(e);
        },
      ),
    );
  }

  // Add token to request headers
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Clear token from request headers
  void clearAuthToken() {
    dio.options.headers.remove('Authorization');
  }
}