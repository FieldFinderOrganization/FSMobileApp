class ApiConstants {
  // Đổi thành IP thực khi test trên thiết bị thật
  // Android Emulator: 10.0.2.2 trỏ về localhost máy host
  static const String baseUrl = 'http://192.168.1.5:8080/api';

  static const String googleLogin = '/auth/google';
  static const String facebookLogin = '/auth/facebook';
  static const String emailLogin = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String sendActivationEmail = '/auth/send-activation-email';
  static const String resetPasswordOtp = '/users/reset-password-otp';
  static const String sendResetOtp = '/users/forgot-password-otp';

  // Home screen endpoints
  static const String products = '/products';
  static const String topProducts = '/products/top-selling';
  static const String pitches = '/pitches';
  static const String categories = '/categories';
  static const String discounts = '/discounts';
}
