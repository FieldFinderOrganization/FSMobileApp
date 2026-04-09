import '../../domain/entities/auth_token_entity.dart';
import 'user_model.dart';

class AuthTokenModel extends AuthTokenEntity {
  const AuthTokenModel({
    required super.accessToken,
    required super.refreshToken,
    required super.user,
  });

  factory AuthTokenModel.fromJson(Map<String, dynamic> json) {
    return AuthTokenModel(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
