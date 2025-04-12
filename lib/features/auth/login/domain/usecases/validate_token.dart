import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class ValidateToken {
  final UserRepository repository;

  ValidateToken(this.repository);

  Future<Either<Failure, UserEntity>> call(TokenParams params) async {
    return await repository.validateTokenRepositoryAsync(params.token);
  }
}

class TokenParams extends Equatable {
  final String token;

  const TokenParams({required this.token});

  @override
  List<Object> get props => [token];
}