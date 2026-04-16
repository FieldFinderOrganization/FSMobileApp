import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String? imageUrl;
  final bool hasPassword;

  const UserEntity({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.imageUrl,
    this.hasPassword = true,
  });

  @override
  List<Object?> get props => [userId, name, email, phone, role, status, imageUrl, hasPassword];

  UserEntity copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? status,
    String? imageUrl,
    bool? hasPassword,
  }) {
    return UserEntity(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      hasPassword: hasPassword ?? this.hasPassword,
    );
  }
}

