// lib/features/auth/login/domain/entities/user_entity.dart
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId; // This is the username
  final String password;
  final String department; // Department for Taiwan
  final String name; // Department for Chinese
  final String token; // Bearer token
  final String role;

  const UserEntity({
    required this.userId,
    required this.password,
    required this.department,
    required this.name,
    required this.token,
    required this.role,
  });

  @override
  List<Object?> get props => [userId, password, department, name, token, role];
}