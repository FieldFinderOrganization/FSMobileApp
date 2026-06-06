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
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // IPv4 override removed — Cloudflare connectionFactory bypass TLS với HTTPS.
    // OS-level resolution sẽ chọn IPv4/IPv6 theo network mobile (VN ISP thường IPv4).

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
    // Luôn để request đi tiếp dù đọc token lỗi — nếu throw ở đây mà không gọi
    // handler.next/reject thì dio treo request vĩnh viễn (xoay mãi, BE không nhận).
    try {
      final token = await _tokenStorage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
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

        // Chỉ auto-retry GET (idempotent). POST/PUT/PATCH/DELETE có thể đã được
        // server xử lý 1 phần (trừ stock, ghi đơn...) trước khi auth filter trả 401
        // → retry sẽ gây side-effect nhân đôi. Throw 401 lên FE để user retry thủ công.
        final method = err.requestOptions.method.toUpperCase();
        if (method != 'GET') {
          handler.next(err);
          return;
        }

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
