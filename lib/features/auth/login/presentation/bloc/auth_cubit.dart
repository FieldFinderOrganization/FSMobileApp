import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../domain/entities/auth_token_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;

  AuthCubit({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
  }) : _authRepository = authRepository,
       _tokenStorage = tokenStorage,
       super(const AuthInitial());

  Future<void> signInWithGoogle() async {
    emit(const AuthLoading());
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: dotenv.env['WEB_CLIENT_ID'],
      );

      await googleSignIn.signOut(); // force hiện account picker
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // Người dùng huỷ đăng nhập
        emit(const AuthInitial());
        return;
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        emit(
          const AuthFailure(
            'Không lấy được Google ID Token. Vui lòng thử lại.',
          ),
        );
        return;
      }

      final authToken = await _authRepository.loginWithGoogle(idToken);
      await _tokenStorage.saveTokens(
        accessToken: authToken.accessToken,
        refreshToken: authToken.refreshToken,
        userId: authToken.user.userId,
        role: authToken.user.role,
      );
      emit(AuthSuccess(authToken));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> signInWithFacebook() async {
    emit(const AuthLoading());
    try {
      final result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.cancelled) {
        emit(const AuthInitial());
        return;
      }

      if (result.status != LoginStatus.success || result.accessToken == null) {
        emit(AuthFailure(result.message ?? 'Đăng nhập Facebook thất bại.'));
        return;
      }

      final accessToken = result.accessToken!.tokenString;
      final authToken = await _authRepository.loginWithFacebook(accessToken);
      await _tokenStorage.saveTokens(
        accessToken: authToken.accessToken,
        refreshToken: authToken.refreshToken,
        userId: authToken.user.userId,
        role: authToken.user.role,
      );
      emit(AuthSuccess(authToken));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    emit(const AuthLoading());
    try {
      final authToken = await _authRepository.loginWithEmail(email, password);
      // Gửi OTP trước khi vào app — chưa lưu token.
      await _authRepository.sendOtp(email);
      emit(AuthOtpSent(pendingToken: authToken, email: email));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      await _authRepository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      // Gửi email chào mừng (không phải OTP), rồi quay về màn đăng nhập.
      await _authRepository.sendActivationEmail(email);
      emit(const AuthRegisterSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String code,
    required AuthTokenEntity pendingToken,
  }) async {
    emit(const AuthLoading());
    try {
      await _authRepository.verifyOtp(email, code);
      await _tokenStorage.saveTokens(
        accessToken: pendingToken.accessToken,
        refreshToken: pendingToken.refreshToken,
        userId: pendingToken.user.userId,
        role: pendingToken.user.role,
      );
      emit(AuthOtpVerified(pendingToken));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> resendOtp(String email) async {
    emit(const AuthLoading());
    try {
      await _authRepository.sendOtp(email);
      emit(const AuthInitial()); // OtpScreen listens to AuthInitial to show "Đã gửi lại!" snackbar
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> logout() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _authRepository.logout(refreshToken);
      } catch (_) {
        // Vẫn clear local dù backend lỗi
      }
    }
    await _tokenStorage.clearAll();
    emit(const AuthInitial());
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? imagePath,
  }) async {
    final currentState = state;
    AuthTokenEntity? currentToken;

    if (currentState is AuthSuccess) {
      currentToken = currentState.authToken;
    } else if (currentState is AuthOtpVerified) {
      currentToken = currentState.authToken;
    }

    if (currentToken == null) return;

    emit(const AuthLoading());
    try {
      String? imageUrl;
      if (imagePath != null) {
        imageUrl = await _authRepository.uploadImage(imagePath);
      }

      final updatedUser = await _authRepository.updateProfile(
        userId: currentToken.user.userId,
        name: name,
        email: currentToken.user.email,
        phone: phone,
        status: currentToken.user.status,
        imageUrl: imageUrl,
      );

      final newToken = currentToken.copyWith(user: updatedUser);
      emit(AuthSuccess(newToken));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
      // Quay lại state cũ sau khi báo lỗi để user thấy data cũ
      emit(AuthSuccess(currentToken));
    }
  }
}
