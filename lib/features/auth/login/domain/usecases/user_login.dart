// lib/features/auth/login/domain/usecases/user_login.dart
import 'package:architecture_scan_app/core/errors/failures.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class UserLogin {
  final UserRepository repository;

  UserLogin(this.repository);

  /// Execute the login use case with given parameters
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    return await repository.loginUser(
      userId: params.userId,
      password: params.password,
      department: params.department,
    );
  }
}

/// Parameters for the login use case
class LoginParams extends Equatable {
  final String userId;
  final String password;
  final String department;

  const LoginParams({
    required this.userId,
    required this.password,
    required this.department,
  });

  @override
  List<Object> get props => [userId, password, department];
}