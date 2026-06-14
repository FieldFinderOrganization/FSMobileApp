import 'package:url_launcher/url_launcher.dart';

/// Bọc url_launcher: mở Zalo/FB/Maps ưu tiên app ngoài, gọi điện, gửi email.
/// Trả false nếu không mở được (caller có thể hiện snackbar).
class LaunchHelper {
  /// Mở URL (Zalo, Facebook, web…). Ưu tiên app ngoài thay vì webview trong app.
  static Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    // Fallback: để OS tự chọn.
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }

  /// Gọi điện.
  static Future<bool> dialPhone(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    return _launch(uri);
  }

  /// Soạn email.
  static Future<bool> sendEmail(String email, {String? subject}) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: subject == null ? null : 'subject=${Uri.encodeComponent(subject)}',
    );
    return _launch(uri);
  }

  /// Mở Google Maps theo địa chỉ (không cần lat/lng).
  static Future<bool> openMaps(String address) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}';
    return openUrl(url);
  }

  static Future<bool> _launch(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        return launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
    return false;
  }
}
