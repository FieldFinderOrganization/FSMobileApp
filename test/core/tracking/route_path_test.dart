import 'package:fsmobileapp/core/tracking/route_path.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  const dist = Distance();

  group('decode', () {
    test('giải mã polyline chuẩn (Google/OSRM precision-5)', () {
      // Vector chuẩn của thuật toán encoded polyline.
      final path = RoutePath.decode('_p~iF~ps|U_ulLnnqC_mqNvxq`@');
      expect(path.points.length, 3);
      expect(path.points[0].latitude, closeTo(38.5, 1e-5));
      expect(path.points[0].longitude, closeTo(-120.2, 1e-5));
      expect(path.points[1].latitude, closeTo(40.7, 1e-5));
      expect(path.points[1].longitude, closeTo(-120.95, 1e-5));
      expect(path.points[2].latitude, closeTo(43.252, 1e-5));
      expect(path.points[2].longitude, closeTo(-126.453, 1e-5));
    });

    test('chuỗi rỗng → tuyến rỗng', () {
      final path = RoutePath.decode('');
      expect(path.points, isEmpty);
      expect(path.isEmpty, isTrue);
    });
  });

  group('totalMeters & cumulative', () {
    test('tổng chiều dài = khoảng cách 2 đầu khi các điểm thẳng hàng', () {
      final a = const LatLng(0, 0);
      final b = const LatLng(0.01, 0);
      final c = const LatLng(0.02, 0);
      final path = RoutePath([a, b, c]);
      final direct = dist.as(LengthUnit.Meter, a, c);
      expect(path.totalMeters, closeTo(direct, 1.0));
      expect(path.totalMeters, greaterThan(2000)); // ~2224 m
    });
  });

  group('pointAt', () {
    final a = const LatLng(0, 0);
    final b = const LatLng(0.02, 0); // bắc 0.02°
    final path = RoutePath([a, b]);

    test('đầu/cuối tuyến', () {
      expect(path.pointAt(0).latitude, closeTo(0, 1e-9));
      expect(path.pointAt(path.totalMeters).latitude, closeTo(0.02, 1e-6));
    });

    test('giữa tuyến', () {
      final mid = path.pointAt(path.totalMeters / 2);
      expect(mid.latitude, closeTo(0.01, 1e-6));
      expect(mid.longitude, closeTo(0, 1e-9));
    });

    test('clamp ngoài biên về 2 đầu', () {
      expect(path.pointAt(-100).latitude, closeTo(0, 1e-9));
      expect(path.pointAt(path.totalMeters + 5000).latitude, closeTo(0.02, 1e-6));
    });
  });

  group('bearingAt', () {
    test('hướng Bắc ≈ 0°', () {
      final path = RoutePath([const LatLng(0, 0), const LatLng(0.02, 0)]);
      expect(path.bearingAt(path.totalMeters / 2), closeTo(0, 1.0));
    });

    test('hướng Đông ≈ 90°', () {
      final path = RoutePath([const LatLng(0, 0), const LatLng(0, 0.02)]);
      expect(path.bearingAt(path.totalMeters / 2), closeTo(90, 1.0));
    });
  });

  group('project', () {
    final a = const LatLng(0, 0);
    final b = const LatLng(0.02, 0);
    final path = RoutePath([a, b]);

    test('điểm nằm trên tuyến → lệch ≈ 0, along ≈ giữa', () {
      final p = path.project(const LatLng(0.01, 0));
      expect(p.dist, closeTo(0, 1.0));
      expect(p.along, closeTo(path.totalMeters / 2, 2.0));
    });

    test('điểm lệch sang bên → dist = khoảng vuông góc, along giữ nguyên', () {
      final off = const LatLng(0.01, 0.001); // lệch đông ~111 m
      final p = path.project(off);
      expect(p.dist, closeTo(111.3, 3.0));
      expect(p.along, closeTo(path.totalMeters / 2, 3.0));
    });

    test('điểm trước điểm đầu → along ≈ 0', () {
      final p = path.project(const LatLng(-0.01, 0));
      expect(p.along, closeTo(0, 1.0));
    });

    test('điểm sau điểm cuối → along ≈ total', () {
      final p = path.project(const LatLng(0.03, 0));
      expect(p.along, closeTo(path.totalMeters, 1.0));
    });
  });

  group('edge cases', () {
    test('tuyến rỗng', () {
      final empty = RoutePath([]);
      expect(empty.isEmpty, isTrue);
      expect(empty.totalMeters, 0);
      final p = empty.project(const LatLng(1, 1));
      expect(p.along, 0);
      expect(p.dist, double.infinity);
    });

    test('1 điểm → coi như rỗng, pointAt trả chính nó', () {
      final single = RoutePath([const LatLng(5, 5)]);
      expect(single.isEmpty, isTrue);
      expect(single.totalMeters, 0);
      expect(single.pointAt(123).latitude, 5);
      expect(single.pointAt(123).longitude, 5);
    });
  });
}
