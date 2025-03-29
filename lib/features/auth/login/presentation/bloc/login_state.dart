// lib/features/auth/login/presentation/bloc/login_state.dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

abstract class LoginState extends Equatable {
  const LoginState();

  @override
  List<Object> get props => [];
}

/// Initial state when the app starts
class LoginInitial extends LoginState {}

/// State while checking for saved token
class TokenChecking extends LoginState {}

/// State while performing login
class LoginLoading extends LoginState {}

/// State when login is successful
class LoginSuccess extends LoginState {
  final UserEntity user;

  const LoginSuccess({required this.user});

  @override
  List<Object> get props => [user];
}

/// State when login fails
class LoginFailure extends LoginState {
  final String message;

  const LoginFailure({required this.message});

  @override
  List<Object> get props => [message];
}