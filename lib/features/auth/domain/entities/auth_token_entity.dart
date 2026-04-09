import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class AuthTokenEntity extends Equatable {
  final String accessToken;
  final String refreshToken;
  final UserEntity user;

  const AuthTokenEntity({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  @override
  List<Object?> get props => [accessToken, refreshToken, user];
}
