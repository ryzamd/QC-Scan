// lib/features/auth/login/domain/usecases/validate_token.dart
import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class ValidateToken {
  final UserRepository repository;

  ValidateToken(this.repository);

  /// Execute the token validation use case with given parameters
  Future<Either<Failure, UserEntity>> call(TokenParams params) async {
    return await repository.validateToken(params.token);
  }
}

/// Parameters for the token validation use case
class TokenParams extends Equatable {
  final String token;

  const TokenParams({required this.token});

  @override
  List<Object> get props => [token];
}