import 'package:json_annotation/json_annotation.dart';
import '../../../../../core/constants/enum.dart';
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
    UserRole userRole = UserRole.scanQc1;
    
    if (json['user'] != null && json['user']['users'] != null) {
      final users = json['user']['users'];
      final name = users['name'] ?? '';
      
      if (name == '品管質檢') {
        userRole = UserRole.scanQc1;
      } else if (name == '品管正式倉') {
        userRole = UserRole.scanQc2;
      }
      
      return UserModel(
        userId: users['userID'] ?? '',
        password: users['password'] ?? '',
        department: users['department'] ?? '',
        name: name,
        token: json['token'] ?? '',
        role: userRole,
      );
    }
    
    return _$UserModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}