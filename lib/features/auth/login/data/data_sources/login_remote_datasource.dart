// lib/features/auth/login/data/data_sources/login_remote_datasource.dart
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class LoginRemoteDataSource {
  /// Calls the login API endpoint to authenticate a user
  ///
  /// Throws [ServerException] for all server-related errors
  /// Throws [AuthException] for authentication errors
  Future<UserModel> loginUser({
    required String userId,
    required String password,
    required String department,
  });
  
  /// Validates a JWT token with the backend
  ///
  /// Throws [ServerException] for all server-related errors
  /// Throws [AuthException] if token is invalid
  Future<UserModel> validateToken(String token);
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final Dio dio;

  LoginRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> loginUser({
    required String userId,
    required String password,
    required String department,
  }) async {
    try {
      // Simulating API delay
      await Future.delayed(const Duration(seconds: 1));
      
      // In production, uncomment this code and remove the dummy data section
      /*
      final response = await dio.post(
        '/api/auth/login',
        data: {
          'userId': userId,
          'password': password,
          'department': department,
        },
      );
      
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw AuthException('Invalid credentials');
      }
      */
      
      // For testing, use dummy data
      // This section should be removed in production
      final user = UserModel.dummyUsers.firstWhere(
        (user) =>
            user.userId == userId &&
            user.password == password &&
            user.department == department,
        orElse: () => throw AuthException('Invalid credentials'),
      );
      
      return user;
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
    try {
      // Simulating API delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // In production, uncomment this code and remove the dummy data section
      /*
      final response = await dio.post(
        '/api/auth/validate-token',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      } else {
        throw AuthException('Invalid token');
      }
      */
      
      // For testing, use dummy data
      // This section should be removed in production
      final user = UserModel.dummyUsers.firstWhere(
        (user) => user.token == token,
        orElse: () => throw AuthException('Invalid token'),
      );
      
      return user;
    } on DioException catch (e) {
      throw ServerException(e.message ?? 'Server error occurred');
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}