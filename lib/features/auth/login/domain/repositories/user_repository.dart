import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {

  Future<Either<Failure, UserEntity>> loginUserRepositoryAsync({required String userId, required String password, required String name});
  
  Future<Either<Failure, UserEntity>> validateTokenRepositoryAsync(String token);
}