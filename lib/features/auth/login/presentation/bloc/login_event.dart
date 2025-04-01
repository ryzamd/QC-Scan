// lib/features/auth/login/presentation/bloc/login_event.dart
import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

/// Event triggered when the login button is pressed
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

/// Event triggered when the department selection changes
class DepartmentChanged extends LoginEvent {
  final String department;

  const DepartmentChanged({required this.department});

  @override
  List<Object> get props => [department];
}

/// Event triggered when the application starts to check saved token
class CheckToken extends LoginEvent {
  final String token;

  const CheckToken({required this.token});

  @override
  List<Object> get props => [token];
}