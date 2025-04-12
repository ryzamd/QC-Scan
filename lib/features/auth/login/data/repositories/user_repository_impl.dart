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
  Future<Either<Failure, UserEntity>> loginUserRepositoryAsync({
    required String userId,
    required String password,
    required String name,
  }) async {

    if (await networkInfo.isConnected) {
      try {

        final user = await remoteDataSource.loginUserRemoteDataAsync(
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

      return Left(ConnectionFailure('No internet connection. Please check your network settings and try again.'));
    }
  }
  
  @override
  Future<Either<Failure, UserEntity>> validateTokenRepositoryAsync(String token) async {

    if (await networkInfo.isConnected) {
      try {

        final user = await remoteDataSource.validateTokenRemoteDataAsync(token);
        
        return Right(user);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message));
      } on AuthException catch (e) {
        return Left(AuthFailure(e.message));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {

      return Left(ConnectionFailure('No internet connection. Please check your network settings and try again.'));
    }
  }
}