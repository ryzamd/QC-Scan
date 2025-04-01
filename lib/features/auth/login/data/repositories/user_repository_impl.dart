// lib/features/auth/login/data/repositories/user_repository_impl.dart
import 'package:architecture_scan_app/core/errors/exceptions.dart';
import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:architecture_scan_app/core/network/network_infor.dart';
import 'package:dartz/dartz.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../data_sources/login_remote_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final LoginRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, UserEntity>> loginUser({
    required String userId,
    required String password,
    required String name,
  }) async {
    // First check network connectivity
    if (await networkInfo.isConnected) {
      try {
        // Attempt to login with provided credentials
        final user = await remoteDataSource.loginUser(
          userId: userId,
          password: password,
          name: name,
        );
        
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // No internet connection
      return Left(ConnectionFailure('No internet connection. Please check your network settings and try again.'));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> validateToken(String token) async {
    // First check network connectivity
    if (await networkInfo.isConnected) {
      try {
        // Attempt to validate the token
        final user = await remoteDataSource.validateToken(token);
        
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      // No internet connection
      return Left(ConnectionFailure('No internet connection. Please check your network settings and try again.'));
    }
  }
}