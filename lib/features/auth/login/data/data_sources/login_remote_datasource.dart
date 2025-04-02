// lib/features/auth/login/data/data_sources/login_remote_datasource.dart
import 'package:architecture_scan_app/core/constants/api_constants.dart';
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class LoginRemoteDataSource {
  Future<UserModel> loginUser({
    required String userId,
    required String password,
    required String name,
  });
  
  Future<UserModel> validateToken(String token);
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final Dio dio;

  LoginRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> loginUser({
    required String userId,
    required String password,
    required String name,
  }) async {
    try {
      final response = await dio.post(
        ApiConstants.loginUrl,
        data: {
          'userID': userId,
          'password': password,
          'name': name,
        },
      );
      
      if (response.statusCode == 200) {
        if (response.data['message'] == '登錄成功') {
          return UserModel.fromJson(response.data);
        } else {
          throw AuthException(response.data['message'] ?? 'Invalid credentials');
        }
      } else {
        throw AuthException('Invalid credentials');
      }
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
  
  @override
  Future<UserModel> validateToken(String token) async {
    // Token validation is not specified in the API documentation
    // This could be implemented later when the endpoint is available
    throw UnimplementedError('Token validation not implemented');
  }
}