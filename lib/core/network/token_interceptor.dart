// lib/core/network/token_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../widgets/confirmation_dialog.dart';

class TokenInterceptor extends Interceptor {
  final AuthRepository authRepository;
  final GlobalKey<NavigatorState>? navigatorKey;

  TokenInterceptor({
    required this.authRepository,
    this.navigatorKey,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.path.contains('/auth/login')) {
      debugPrint('TokenInterceptor: Skipping token for login request to ${options.path}');
      return handler.next(options);
    }
    
    final token = await authRepository.getAccessTokenAsync();
    
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      debugPrint('TokenInterceptor: Added token to request for ${options.path}');
    } else {
      debugPrint('TokenInterceptor: No token available for request to ${options.path}');
    }
      
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('TokenInterceptor: Error ${err.response?.statusCode} for ${err.requestOptions.path}');
    
    if (err.response?.statusCode == 401) {
      debugPrint('TokenInterceptor: 401 Unauthorized error detected');
      
      await authRepository.logoutAsync();
      
      if (navigatorKey?.currentContext != null && navigatorKey!.currentContext!.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ConfirmationDialog.showAsync(
            context: navigatorKey!.currentContext!,
            title: 'SESSION EXPIRED',
            message: 'Your session has expired. Please log in again.',
            confirmText: 'OK',
            showCancelButton: false,
            onConfirm: () {
              Navigator.of(navigatorKey!.currentContext!).pop();
              Navigator.of(navigatorKey!.currentContext!).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
          );
        });
      }
    }
    
    handler.next(err);
  }
}