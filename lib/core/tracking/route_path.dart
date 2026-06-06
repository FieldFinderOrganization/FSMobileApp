import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Polyline tuyến đường + tiện ích chiếu điểm GPS lên tuyến và lấy toạ độ/hướng
/// tại một khoảng cách dọc tuyến — để animate marker bám đường (snap-to-road).
///
/// Toán chiếu dùng xấp xỉ mặt phẳng mét quanh từng điểm (đủ chính xác ở cự ly đô thị).
class RoutePath {
  final List<LatLng> points;
  final List<double> _cum; // _cum[i] = mét từ đầu tuyến tới points[i]
  static const Distance _distance = Distance();

  RoutePath(this.points) : _cum = _cumulative(points);

  double get totalMeters => _cum.isEmpty ? 0 : _cum.last;
  bool get isEmpty => points.length < 2;

  static List<double> _cumulative(List<LatLng> pts) {
    final out = List<double>.filled(pts.length, 0);
    for (var i = 1; i < pts.length; i++) {
      out[i] = out[i - 1] + _distance.as(LengthUnit.Meter, pts[i - 1], pts[i]);
    }
    return out;
  }

  /// Đổi sang mặt phẳng mét (x đông, y bắc) quanh [ref].
  static Point<double> _toXY(LatLng p, LatLng ref) {
    final mPerLng = 111320.0 * cos(ref.latitude * pi / 180);
    return Point((p.longitude - ref.longitude) * mPerLng,
        (p.latitude - ref.latitude) * 110540.0);
  }

  /// Chiếu [p] lên tuyến → (along: mét dọc tuyến, dist: lệch vuông góc mét).
  ({double along, double dist}) project(LatLng p) {
    if (isEmpty) return (along: 0, dist: double.infinity);
    var bestAlong = 0.0;
    var bestDist = double.infinity;
    for (var i = 0; i < points.length - 1; i++) {
      final a = points[i], b = points[i + 1];
      final ab = _toXY(b, a);
      final ap = _toXY(p, a);
      final len2 = ab.x * ab.x + ab.y * ab.y;
      var t = len2 == 0 ? 0.0 : (ap.x * ab.x + ap.y * ab.y) / len2;
      t = t.clamp(0.0, 1.0);
      final foot = LatLng(a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t);
      final d = _distance.as(LengthUnit.Meter, p, foot);
      if (d < bestDist) {
        bestDist = d;
        bestAlong = _cum[i] + t * (_cum[i + 1] - _cum[i]);
      }
    }
    return (along: bestAlong, dist: bestDist);
  }

  /// Toạ độ tại [m] mét dọc tuyến (clamp về [0, total]).
  LatLng pointAt(double m) {
    if (points.isEmpty) return const LatLng(0, 0);
    if (isEmpty) return points.first;
    final mm = m.clamp(0.0, totalMeters);
    final i = _segmentIndex(mm);
    final segLen = _cum[i + 1] - _cum[i];
    final t = segLen == 0 ? 0.0 : (mm - _cum[i]) / segLen;
    final a = points[i], b = points[i + 1];
    return LatLng(a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t);
  }

  /// Hướng (độ, 0..360) của tuyến tại [m] mét dọc tuyến.
  double bearingAt(double m) {
    if (isEmpty) return 0;
    final i = _segmentIndex(m.clamp(0.0, totalMeters));
    return _bearing(points[i], points[i + 1]);
  }

  int _segmentIndex(double m) {
    for (var i = 0; i < _cum.length - 1; i++) {
      if (m <= _cum[i + 1]) return i;
    }
    return points.length - 2;
  }

  static double _bearing(LatLng a, LatLng b) {
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final lat1 = a.latitude * pi / 180, lat2 = b.latitude * pi / 180;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  /// Giải mã polyline encoded (precision 5, định dạng Google/OSRM `geometries=polyline`).
  static RoutePath decode(String encoded) {
    final pts = <LatLng>[];
    int index = 0, lat = 0, lng = 0;
    while (index < encoded.length) {
      int shift = 0, result = 0, b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      pts.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return RoutePath(pts);
  }
}
