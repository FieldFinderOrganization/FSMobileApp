import 'package:geolocator/geolocator.dart';

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class LocationHelper {
  static Future<LatLng?> currentPosition({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Trạng thái quyền hiện tại (để UI quyết định hiện nút "mở Cài đặt").
  static Future<LocationPermission> permissionStatus() =>
      Geolocator.checkPermission();

  /// Mở Cài đặt ứng dụng — dùng khi quyền bị từ chối vĩnh viễn.
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Mở Cài đặt vị trí hệ thống — dùng khi GPS đang tắt.
  static Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
