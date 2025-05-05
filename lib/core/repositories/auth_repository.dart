import 'dart:convert';
import 'dart:math';
import 'package:architecture_scan_app/core/constants/api_constants.dart';
import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/core/network/dio_client.dart';
import 'package:architecture_scan_app/core/services/secure_storage_service.dart';
import 'package:architecture_scan_app/features/auth/login/data/models/user_model.dart';
import 'package:architecture_scan_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../services/get_translate_key.dart';

class AuthRepository {
  final SecureStorageService _secureStorage;
  final DioClient _dioClient;

  AuthRepository(this._secureStorage, this._dioClient);

  Future<Either<Failure, UserEntity>> loginUserAsync({required String userId, required String password, required String name}) async {
    final authDio = Dio()
      ..options.baseUrl = _dioClient.dio.options.baseUrl
      ..options.connectTimeout = _dioClient.dio.options.connectTimeout
      ..options.receiveTimeout = _dioClient.dio.options.receiveTimeout;

    try {
      final response = await authDio.post(
        ApiConstants.loginUrl,
        data: {
          'userID': userId,
          'password': password,
          'name': name,
        },
      );

      if (response.statusCode == 200) {
        if (response.data['message'] == '登錄成功') {
          final user = UserModel.fromJson(response.data);
          final token = response.data['token'];

          if (token == null || token.isEmpty) {
            return Left(AuthFailure('No token received from server'));
          }

          await _secureStorage.saveAccessTokenAsync(token);
          await _secureStorage.saveUserIdAsync(user.userId);
          await _secureStorage.saveUserDataAsync(jsonEncode(response.data['user']['users']));
          _dioClient.setAuthTokenAsync(token);

          return Right(user);

        } else {
          return Left(AuthFailure(response.data['message'] ?? StringKey.invalidCredentialsMessage));
        }
      } else {
        return Left(ServerFailure(StringKey.serverErrorMessage));
      }
    } on DioException catch (_) {
      return Left(ServerFailure(StringKey.networkErrorMessage));
    }
  }

  Future<bool> isTokenValidAsync() async {
    final token = await _secureStorage.getAccessTokenAsync();
    if (token == null || token.isEmpty) {
      return false;
    }

    final expiry = await _secureStorage.getTokenExpiryAsync();
    if (expiry != null) {
      return expiry.isAfter(DateTime.now());
    }
    
    return true;
  }

  Future<bool> logoutAsync() async {
    try {
      await _secureStorage.clearAllDataAsync();
      _dioClient.clearAuthTokenAsync();
      return true;
    } catch (e) {
      debugPrint('Error during logout: $e');
      return false;
    }
  }

  Future<String?> getAccessTokenAsync() async {
    return await _secureStorage.getAccessTokenAsync();
  }

  Future<bool> isLoggedInAsync() async {
    return await _secureStorage.hasTokenAsync() && await isTokenValidAsync();
  }

  Future<UserEntity?> getCurrentUserAsync() async {
    final userData = await _secureStorage.getUserDataAsync();
    if (userData != null) {
      try {
        return UserModel.fromJson(jsonDecode(userData));
      } catch (e) {
        debugPrint('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> debugTokenStateAsync() async {
    final token = await _secureStorage.getAccessTokenAsync();
    final userId = await _secureStorage.getUserIdAsync();
    
    debugPrint('=============== TOKEN DEBUG ===============');
    debugPrint('Has token in storage: ${token != null}');
    if (token != null) {
      debugPrint('Token length: ${token.length}');
      debugPrint('Token preview: ${token.substring(0, min(20, token.length))}...');
    }
    debugPrint('Has userId: ${userId != null}');
    debugPrint('Token in DioClient: ${_dioClient.hasValidTokenAsync()}');
    debugPrint('==========================================');
  }
}