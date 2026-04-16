import 'package:dio/dio.dart';
import '../../domain/entities/auth_token_entity.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;

  AuthRepositoryImpl(this._datasource);

  @override
  Future<AuthTokenEntity> loginWithGoogle(String idToken) async {
    try {
      return await _datasource.loginWithGoogle(idToken);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<AuthTokenEntity> loginWithFacebook(String accessToken) async {
    try {
      return await _datasource.loginWithFacebook(accessToken);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<AuthTokenEntity> loginWithEmail(String email, String password) async {
    try {
      return await _datasource.loginWithEmail(email, password);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<AuthTokenEntity> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      return await _datasource.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> logout(String refreshToken) async {
    try {
      await _datasource.logout(refreshToken);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> sendOtp(String email) async {
    try {
      await _datasource.sendOtp(email);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> verifyOtp(String email, String code) async {
    try {
      await _datasource.verifyOtp(email, code);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> sendActivationEmail(String email) async {
    try {
      await _datasource.sendActivationEmail(email);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> resetPasswordWithOtp(String email, String newPassword) async {
    try {
      await _datasource.resetPasswordWithOtp(email, newPassword);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> sendResetPassword(String email) async {
    try {
      await _datasource.sendResetPassword(email);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<UserEntity> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? status,
    String? imageUrl,
  }) async {
    try {
      return await _datasource.updateProfile(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
        status: status,
        imageUrl: imageUrl,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<String> uploadImage(String filePath) async {
    try {
      return await _datasource.uploadToCloudinary(filePath);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> verifyCurrentPassword(String userId, String currentPassword) async {
    try {
      await _datasource.verifyCurrentPassword(userId, currentPassword);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> sendChangePasswordOtp(String email) async {
    try {
      await _datasource.sendChangePasswordOtp(email);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<void> changePassword(String email, String newPassword) async {
    try {
      await _datasource.changePassword(email, newPassword);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode == 401) {
      return Exception('Phiên đăng nhập không hợp lệ. Vui lòng thử lại.');
    } else if (statusCode == 403) {
      final error = e.response?.data?['error'] as String?;
      final message = e.response?.data?['message'] as String?;
      final detail = message ?? error;
      if (detail != null && detail.isNotEmpty) {
        return Exception(detail);
      }
      return Exception('Truy cập bị từ chối. Vui lòng thử lại.');
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.');
    }
    final message = e.response?.data?['message'] as String?;
    return Exception(message ?? 'Thao tác thất bại. Vui lòng thử lại.');
  }
}
