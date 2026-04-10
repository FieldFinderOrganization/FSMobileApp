import 'package:equatable/equatable.dart';

abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

class ForgotPasswordLoading extends ForgotPasswordState {
  const ForgotPasswordLoading();
}

/// OTP đã được gửi — chuyển sang ForgotOtpScreen
class ForgotOtpSent extends ForgotPasswordState {
  final String email;
  const ForgotOtpSent(this.email);

  @override
  List<Object?> get props => [email];
}

/// OTP đúng — chuyển sang NewPasswordScreen
class ForgotOtpVerified extends ForgotPasswordState {
  final String email;
  const ForgotOtpVerified(this.email);

  @override
  List<Object?> get props => [email];
}

/// Đặt lại mật khẩu thành công — quay về LoginScreen
class PasswordResetSuccess extends ForgotPasswordState {
  const PasswordResetSuccess();
}

/// OTP resent thành công (dùng để show snackbar)
class ForgotOtpResent extends ForgotPasswordState {
  const ForgotOtpResent();
}

class ForgotPasswordFailure extends ForgotPasswordState {
  final String message;
  const ForgotPasswordFailure(this.message);

  @override
  List<Object?> get props => [message];
}
