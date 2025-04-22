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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    
    if (json['user'] != null && json['user']['users'] != null) {
      final users = json['user']['users'];
      final name = users['name'] ?? '';
      
      return UserModel(
        userId: users['userID'] ?? '',
        password: users['password'] ?? '',
        department: users['department'] ?? '',
        name: name,
        token: json['token'] ?? '',
      );
    }
    
    return _$UserModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}