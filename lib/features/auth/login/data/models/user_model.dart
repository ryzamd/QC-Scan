// lib/features/auth/login/data/models/user_model.dart
import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends UserEntity {
  const UserModel({
    required super.userId,
    required super.password,
    required super.department,
    required super.name,
    required super.token,
    required super.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  // Dummy data for testing purposes
  // This will be used only during development and testing
  static List<UserModel> dummyUsers = [
    const UserModel(
      userId: 'admin',
      password: 'admin123',
      department: 'QC Department',
      name: 'QC部门', // Chinese name
      token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhZG1pbiIsInJvbGUiOiJhZG1pbiJ9',
      role: 'admin',
    ),
    const UserModel(
      userId: 'user',
      password: 'user123',
      department: 'Warehouse Department',
      name: '仓库部门', // Chinese name
      token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJ1c2VyIiwicm9sZSI6InVzZXIifQ',
      role: 'user',
    ),
  ];
}