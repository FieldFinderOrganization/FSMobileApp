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
  Future<void> sendOtp(String email);
  Future<void> verifyOtp(String email, String code);
  Future<void> sendActivationEmail(String email);
  Future<void> resetPasswordWithOtp(String email, String newPassword);
  Future<void> sendResetPassword(String email);
}
