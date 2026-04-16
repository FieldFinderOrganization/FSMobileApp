import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/auth_token_model.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final Dio _dio;

  AuthRemoteDatasource(this._dio);

  Future<AuthTokenModel> loginWithGoogle(String idToken) async {
    final response = await _dio.post(
      ApiConstants.googleLogin,
      data: {'idToken': idToken},
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthTokenModel> loginWithFacebook(String accessToken) async {
    final response = await _dio.post(
      ApiConstants.facebookLogin,
      data: {'accessToken': accessToken},
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthTokenModel> loginWithEmail(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.emailLogin,
      data: {'email': email, 'password': password},
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AuthTokenModel> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      },
    );
    return AuthTokenModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post(ApiConstants.logout, data: {'refreshToken': refreshToken});
  }

  Future<void> sendOtp(String email) async {
    await _dio.post(ApiConstants.sendOtp, queryParameters: {'email': email});
  }

  Future<void> verifyOtp(String email, String code) async {
    await _dio.post(
      ApiConstants.verifyOtp,
      data: {'email': email, 'code': code},
    );
  }

  Future<void> sendActivationEmail(String email) async {
    await _dio.post(
      ApiConstants.sendActivationEmail,
      queryParameters: {'email': email},
    );
  }

  Future<void> resetPasswordWithOtp(String email, String newPassword) async {
    await _dio.post(
      ApiConstants.resetPasswordOtp,
      queryParameters: {'email': email, 'newPassword': newPassword},
    );
  }

  Future<void> sendResetPassword(String email) async {
    await _dio.post(
      ApiConstants.sendResetOtp,
      queryParameters: {'email': email},
    );
  }

  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? email,
    String? phone,
    String? status,
    String? imageUrl,
  }) async {
    final response = await _dio.put(
      ApiConstants.userUpdate(userId),
      data: {
        'name': ?name,
        'email': ?email,
        'phone': ?phone,
        'status': ?status,
        'imageUrl': ?imageUrl,
      },
    );
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> uploadToCloudinary(String filePath) async {
    final fileName = filePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
      'upload_preset':
          dotenv.env['NEXT_PUBLIC_CLOUDINARY_UPLOAD_PRESET'] ?? 'chat_preset',
    });

    // Sử dụng instance Dio mới để tránh bị can thiệp bởi interceptors (thêm Authorization header)
    final cloudDio = Dio();
    final response = await cloudDio.post(
      ApiConstants.cloudinaryUrl,
      data: formData,
    );

    return response.data['secure_url'] as String;
  }

  Future<void> verifyCurrentPassword(
    String userId,
    String currentPassword,
  ) async {
    await _dio.post(
      ApiConstants.verifyCurrentPassword,
      queryParameters: {'userId': userId, 'currentPassword': currentPassword},
    );
  }

  Future<void> sendChangePasswordOtp(String email) async {
    await _dio.post(
      ApiConstants.changePasswordOtp,
      queryParameters: {'email': email},
    );
  }

  Future<void> changePassword(String email, String newPassword) async {
    await _dio.post(
      ApiConstants.resetPasswordOtp,
      queryParameters: {'email': email, 'newPassword': newPassword},
    );
  }
}
