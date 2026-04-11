import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final AuthRepository _authRepository;

  ForgotPasswordCubit({required AuthRepository authRepository})
    : _authRepository = authRepository,
      super(const ForgotPasswordInitial());

  /// Gửi OTP đến email để đặt lại mật khẩu
  Future<void> sendOtp(String email) async {
    emit(const ForgotPasswordLoading());
    try {
      await _authRepository.sendResetPassword(email);
      emit(ForgotOtpSent(email));
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Xác thực OTP
  Future<void> verifyOtp(String email, String code) async {
    emit(const ForgotPasswordLoading());
    try {
      await _authRepository.verifyOtp(email, code);
      emit(ForgotOtpVerified(email));
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Gửi lại OTP
  Future<void> resendOtp(String email) async {
    emit(const ForgotPasswordLoading());
    try {
      await _authRepository.sendOtp(email);
      emit(const ForgotOtpResent());
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Đặt lại mật khẩu sau khi OTP đã được xác thực
  Future<void> resetPassword(String email, String newPassword) async {
    emit(const ForgotPasswordLoading());
    try {
      await _authRepository.resetPasswordWithOtp(email, newPassword);
      emit(const PasswordResetSuccess());
    } catch (e) {
      emit(ForgotPasswordFailure(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
