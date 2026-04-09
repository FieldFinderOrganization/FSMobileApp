import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final String? imageUrl;

  const UserEntity({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [userId, name, email, phone, role, status, imageUrl];
}
