import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.userId,
    required super.name,
    required super.email,
    super.phone,
    required super.role,
    required super.status,
    super.imageUrl,
    required super.hasPassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: json['role'] as String,
      status: json['status'] as String,
      imageUrl: json['imageUrl'] as String?,
      hasPassword: json['hasPassword'] as bool? ?? true,
    );
  }
}
