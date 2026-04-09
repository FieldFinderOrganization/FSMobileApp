import '../entities/auth_token_entity.dart';

abstract class AuthRepository {
  Future<AuthTokenEntity> loginWithGoogle(String idToken);
  Future<AuthTokenEntity> loginWithFacebook(String accessToken);
  Future<void> logout(String refreshToken);
}
