import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/storage/token_storage.dart';
import '../../../domain/entities/auth_token_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';
import 'passkey_service.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final TokenStorage _tokenStorage;
  late final PasskeyService _passkeyService;

  AuthCubit({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
  }) : _authRepository = authRepository,
       _tokenStorage = tokenStorage,
       super(const AuthInitial()) {
    _passkeyService = PasskeyService(authRepository);
  }

  AuthTokenEntity? get _currentToken {
    final currentState = state;
    if (currentState is AuthSuccess) return currentState.authToken;
    if (currentState is AuthOtpVerified) return currentState.authToken;
    return null;
  }

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
      
      // Chế độ bảo mật cao: Gửi OTP ngay cả sau khi đăng nhập Social
      await _authRepository.sendOtp(authToken.user.email);
      emit(AuthOtpSent(pendingToken: authToken, email: authToken.user.email));
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
      
      // Chế độ bảo mật cao: Gửi OTP ngay cả sau khi đăng nhập Social
      await _authRepository.sendOtp(authToken.user.email);
      emit(AuthOtpSent(pendingToken: authToken, email: authToken.user.email));
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

  Future<void> signInWithPasskey(String email) async {
    emit(const AuthLoading());
    try {
      final authToken = await _passkeyService.loginWithPasskey(email);
      
      // Bỏ qua bước OTP vì passkey là xác thực mạnh (sinh trắc học)
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

  Future<void> registerPasskey() async {
    final previousState = state;
    final token = _currentToken;
    if (token == null) return;
    
    emit(const AuthLoading());
    try {
      await _passkeyService.registerPasskey(token.user.email);
      
      emit(const AuthPasskeyRegistered());
      emit(previousState);
    } catch (e) {
      emit(AuthPasskeyRegisterFailure(e.toString().replaceFirst('Exception: ', '')));
      emit(previousState);
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

    // Clear local chat history upon logout
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ai_chat_sessions');

    emit(const AuthInitial());
  }

  Future<void> updateProfile({
    String? name,
    String? phone,
    String? imagePath,
  }) async {
    final previousState = state;
    final token = _currentToken;
    if (token == null) return;

    emit(const AuthLoading());
    try {
      String? imageUrl;
      if (imagePath != null) {
        imageUrl = await _authRepository.uploadImage(imagePath);
      }

      final updatedUser = await _authRepository.updateProfile(
        userId: token.user.userId,
        name: name,
        email: token.user.email,
        phone: phone,
        status: token.user.status,
        imageUrl: imageUrl,
      );

      final newToken = token.copyWith(user: updatedUser);
      emit(AuthSuccess(newToken));
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
      emit(previousState);
    }
  }

  Future<void> verifyCurrentPassword(String currentPassword) async {
    final previousState = state;
    final token = _currentToken;
    if (token == null) return;

    emit(const AuthLoading());
    try {
      await _authRepository.verifyCurrentPassword(
        token.user.userId,
        currentPassword,
      );
      emit(const AuthChangePasswordVerifySuccess());
      emit(previousState);
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
      emit(previousState);
    }
  }

  Future<void> verifyChangePasswordOtp(String email, String code) async {
    final previousState = state;
    if (_currentToken == null) return;

    emit(const AuthLoading());
    try {
      await _authRepository.verifyOtp(email, code);
      emit(const AuthChangePasswordOtpVerified());
      emit(previousState);
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
      emit(previousState);
    }
  }

  Future<void> changePassword(String email, String newPassword) async {
    final previousState = state;
    if (_currentToken == null) return;

    emit(const AuthLoading());
    try {
      await _authRepository.changePassword(email, newPassword);
      emit(const AuthChangePasswordSuccess());
      emit(previousState);
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
      emit(previousState);
    }
  }

  Future<void> sendChangePasswordOtp(String email) async {
    final previousState = state;
    if (_currentToken == null) return;

    emit(const AuthLoading());
    try {
      await _authRepository.sendChangePasswordOtp(email);
      emit(previousState);
    } catch (e) {
      emit(AuthFailure(e.toString().replaceFirst('Exception: ', '')));
      emit(previousState);
    }
  }
}
