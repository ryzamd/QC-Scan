// lib/features/auth/login/domain/repositories/user_repository.dart
import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class UserRepository {
  /// Authenticates a user with the given credentials
  ///
  /// Returns [UserEntity] if successful, [Failure] otherwise
  Future<Either<Failure, UserEntity>> loginUserRepositoryAsync({
    required String userId,
    required String password,
    required String name,
    
  });
  
  /// Validates a JWT token
  ///
  /// Returns [UserEntity] if token is valid, [Failure] otherwise
  Future<Either<Failure, UserEntity>> validateTokenRepositoryAsync(String token);
}