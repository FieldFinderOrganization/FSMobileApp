import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

class DioClient {
  late final Dio dio;
  final TokenStorage _tokenStorage;

  DioClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        handler.next(err);
        return;
      }

      try {
        final response = await dio.post(
          ApiConstants.refreshToken,
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': null}),
        );

        final newAccessToken = response.data['accessToken'] as String;
        final newRefreshToken = response.data['refreshToken'] as String;
        final userId = await _tokenStorage.getUserId() ?? '';
        final role = await _tokenStorage.getRole() ?? '';

        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          userId: userId,
          role: role,
        );

        // Retry request gốc với token mới
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);
        return;
      } catch (_) {
        await _tokenStorage.clearAll();
      }
    }
    handler.next(err);
  }
}
