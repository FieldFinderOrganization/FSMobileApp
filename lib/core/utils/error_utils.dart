import 'package:dio/dio.dart';

/// Trích thông điệp lỗi thân thiện (tiếng Việt) từ một exception bất kỳ.
///
/// Quy tắc:
/// - [DioException]: ưu tiên message do BE trả về (`response.data['message']`
///   hoặc `['error']`). Đây thường đã là tiếng Việt.
/// - Lỗi mạng / timeout: trả thông báo mất kết nối tiếng Việt.
/// - Mọi trường hợp còn lại: trả [fallback] — KHÔNG bao giờ ném chuỗi
///   `DioException [...]` hay stack trace thô ra cho người dùng.
String messageFromError(
  Object error, {
  String fallback = 'Đã có lỗi xảy ra, vui lòng thử lại.',
}) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final m = data['message'] ?? data['error'];
      if (m is String && m.trim().isNotEmpty) return m.trim();
    }
    // BE đôi khi trả text thuần (không phải JSON). Bỏ qua HTML (trang lỗi gateway).
    if (data is String &&
        data.trim().isNotEmpty &&
        !data.trimLeft().startsWith('<')) {
      return data.trim();
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối quá hạn, vui lòng kiểm tra mạng và thử lại.';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối máy chủ, vui lòng kiểm tra mạng.';
      default:
        return fallback;
    }
  }
  return fallback;
}
