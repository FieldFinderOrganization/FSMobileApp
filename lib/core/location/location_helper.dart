import 'package:geolocator/geolocator.dart';

class LatLng {
  final double latitude;
  final double longitude;
  const LatLng(this.latitude, this.longitude);
}

class LocationHelper {
  /// Vị trí đầy đủ kèm speed (m/s), heading (độ), timestamp — cho tracking shipper.
  static Future<Position?> currentPositionFull({
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

      return await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Chỉ lat/lng — giữ cho các nơi gọi cũ (map picker, v.v.).
  static Future<LatLng?> currentPosition({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final pos = await currentPositionFull(timeout: timeout);
    return pos == null ? null : LatLng(pos.latitude, pos.longitude);
  }

  /// Trạng thái quyền hiện tại (để UI quyết định hiện nút "mở Cài đặt").
  static Future<LocationPermission> permissionStatus() =>
      Geolocator.checkPermission();

  /// Mở Cài đặt ứng dụng — dùng khi quyền bị từ chối vĩnh viễn.
  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Mở Cài đặt vị trí hệ thống — dùng khi GPS đang tắt.
  static Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}
