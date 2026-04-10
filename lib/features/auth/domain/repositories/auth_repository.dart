import '../entities/auth_token_entity.dart';

abstract class AuthRepository {
  Future<AuthTokenEntity> loginWithGoogle(String idToken);
  Future<AuthTokenEntity> loginWithFacebook(String accessToken);
  Future<AuthTokenEntity> loginWithEmail(String email, String password);
  Future<AuthTokenEntity> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<void> logout(String refreshToken);
}
