import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class UserLogin {
  final UserRepository repository;

  UserLogin(this.repository);


Future<Either<Failure, UserEntity>> call(LoginParams params) async {
  return await repository.loginUserRepositoryAsync(
    userId: params.userId,
    password: params.password,
    name: params.name,
  );
}
}

class LoginParams extends Equatable {
  final String userId;
  final String password;
  final String name;

  const LoginParams({
    required this.userId,
    required this.password,
    required this.name,
  });

  @override
  List<Object> get props => [userId, password, name];
}