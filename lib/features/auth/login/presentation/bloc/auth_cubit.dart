import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../../../../../core/storage/token_storage.dart';
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

  Future<void> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    emit(const AuthLoading());
    try {
      final authToken = await _authRepository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
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
}
