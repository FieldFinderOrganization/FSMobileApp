import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/auth_token_model.dart';

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

  Future<void> logout(String refreshToken) async {
    await _dio.post(
      ApiConstants.logout,
      data: {'refreshToken': refreshToken},
    );
  }
}
