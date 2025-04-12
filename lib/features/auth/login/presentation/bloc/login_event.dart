import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginButtonPressed extends LoginEvent {
  final String userId;
  final String password;
  final String department;
  final String name;

  const LoginButtonPressed({
    required this.userId,
    required this.password,
    this.department = "",
    required this.name
  });

  @override
  List<Object> get props => [userId, password, department, name];
}

class DepartmentChanged extends LoginEvent {
  final String department;

  const DepartmentChanged({required this.department});

  @override
  List<Object> get props => [department];
}

class CheckToken extends LoginEvent {
  final String token;

  const CheckToken({required this.token});

  @override
  List<Object> get props => [token];
}