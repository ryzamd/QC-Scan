import 'package:architecture_scan_app/core/constants/api_constants.dart';
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:architecture_scan_app/core/services/get_translate_key.dart';
import 'package:dio/dio.dart';
import '../models/user_model.dart';

abstract class LoginRemoteDataSource {
  Future<UserModel> loginUserRemoteDataAsync({
    required String userId,
    required String password,
    required String name,
  });
  
  Future<UserModel> validateTokenRemoteDataAsync(String token);
}

class LoginRemoteDataSourceImpl implements LoginRemoteDataSource {
  final Dio dio;

  LoginRemoteDataSourceImpl({required this.dio});

  @override
  Future<UserModel> loginUserRemoteDataAsync({
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
          throw AuthException(response.data['message'] ?? StringKey.invalidCredentialsMessage);
        }
      } else {
        throw AuthException(StringKey.invalidTokenMessage);
      }
    } on DioException catch (_) {
      throw NetWorkException(StringKey.serverErrorMessage);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw NetWorkException(StringKey.networkErrorMessage);
    }
  }
  
  @override
  Future<UserModel> validateTokenRemoteDataAsync(String token) async {
    throw UnimplementedError('Token validation not implemented');
  }
}