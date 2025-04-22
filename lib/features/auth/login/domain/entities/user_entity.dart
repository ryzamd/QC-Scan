import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String password;
  final String department;
  final String name;
  final String token;

  const UserEntity({
    required this.userId,
    required this.password,
    required this.department,
    required this.name,
    required this.token,
  });

  @override
  List<Object?> get props => [userId, password, department, name, token];
}