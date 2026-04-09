class ApiConstants {
  // Đổi thành IP thực khi test trên thiết bị thật
  // Android Emulator: 10.0.2.2 trỏ về localhost máy host
  static const String baseUrl = 'http://192.168.1.5:8080/api';

  static const String googleLogin = '/auth/google';
  static const String facebookLogin = '/auth/facebook';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
}
