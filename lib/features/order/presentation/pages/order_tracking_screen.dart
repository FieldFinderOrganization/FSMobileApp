import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/tracking/route_path.dart';
import '../../../../core/tracking/tracking_websocket_service.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../call/presentation/cubit/call_cubit.dart';
import '../../../chat/presentation/pages/user_chat_screen.dart';
import '../../../shipper/data/shipper_remote_data_source.dart';
import '../../data/models/order_model.dart';

/// Màn theo dõi shipper real-time cho User/Admin.
/// Lấy vị trí cuối (Redis) khi mở, rồi nhận tick live qua STOMP,
/// nội suy mượt vị trí marker shipper trong khoảng giữa các tick.
class OrderTrackingScreen extends StatefulWidget {
  final OrderModel order;
  const OrderTrackingScreen({super.key, required this.order});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  late final TrackingWebSocketService _ws;
  final MapController _mapController = MapController();

  late final AnimationController _anim;
  LatLng? _from;
  LatLng? _to;
  LatLng? _shipper;
  bool _connected = false;
  String _statusText = 'Đang kết nối…';

  // Hướng icon (độ) — nội suy mượt giữa các tick.
  double _bearing = 0;
  double _bearingFrom = 0;
  double _bearingTo = 0;
  int? _lastTs; // ts điểm trước, để tính nhịp animation theo thời gian thật.
  bool _follow = true; // camera bám shipper; tắt khi user tự pan.

  static const _minMoveMeters = 3.0; // < ngưỡng = coi như đứng yên (lọc nhiễu GPS).
  static const _minDurMs = 3000;
  static const _maxDurMs = 15000;
  // Lệch giữa "đầu" glyph icon và hướng Bắc=0 (tinh chỉnh nếu đổi asset).
  static const _iconHeadingOffsetDeg = 0.0;

  // Snap-to-road (Tier 2): tuyến đường vẽ sẵn + vị trí marker dọc tuyến.
  RoutePath? _routePath;
  bool _routeLoading = false;
  bool _segOnRoute = false; // segment hiện tại animate bám tuyến (true) hay thẳng.
  double _curDist = 0; // vị trí marker dọc tuyến (m).
  double _fromDist = 0;
  double _toDist = 0;
  static const _rerouteThresholdMeters = 40.0;

  // Đích giao (toạ độ user).
  LatLng? get _dest => (widget.order.destLat != null && widget.order.destLng != null)
      ? LatLng(widget.order.destLat!, widget.order.destLng!)
      : null;

  @override
  void initState() {
    super.initState();
    _ws = TrackingWebSocketService(
      tokenStorage: context.read<TokenStorage>(),
    );
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        if (_from == null || _to == null) return;
        final t = _anim.value;
        // KHÔNG setState mỗi frame — sẽ rebuild cả FlutterMap (tile+polyline) 60fps → giật.
        // Chỉ cập nhật field; marker tự vẽ lại qua AnimatedBuilder(_anim) ở build (rebuild
        // mỗi mình marker). Camera bám theo (nhẹ, không rebuild Scaffold).
        if (_segOnRoute && _routePath != null) {
          _curDist = _fromDist + (_toDist - _fromDist) * t;
          _shipper = _routePath!.pointAt(_curDist);
        } else {
          _shipper = _lerp(_from!, _to!, t);
        }
        _bearing = _lerpAngle(_bearingFrom, _bearingTo, t);
        if (_follow && _shipper != null) {
          _mapController.move(_shipper!, _mapController.camera.zoom);
        }
      });

    _loadLastThenConnect();
  }

  LatLng _lerp(LatLng a, LatLng b, double t) => LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

  /// Hướng (độ, 0..360) từ a tới b — dùng khi payload không kèm bearing.
  double _bearingBetween(LatLng a, LatLng b) {
    final dLon = (b.longitude - a.longitude) * pi / 180;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final y = sin(dLon) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  /// Nội suy góc theo đường ngắn nhất (xử lý wrap 359°→1°).
  double _lerpAngle(double a, double b, double t) {
    final diff = (b - a + 540) % 360 - 180;
    return (a + diff * t) % 360;
  }

  Future<void> _loadLastThenConnect() async {
    // 1. Vị trí cuối từ Redis (hiện ngay nếu còn trong 60s).
    try {
      final ds = ShipperRemoteDataSource(dioClient: context.read<DioClient>());
      final last = await ds.getLastLocation(widget.order.orderId);
      if (last != null && mounted) {
        final p = LatLng(
          (last['lat'] as num).toDouble(),
          (last['lng'] as num).toDouble(),
        );
        setState(() => _shipper = p);
        _fetchRoute(p);
      }
    } catch (_) {}

    // 2. Kết nối nhận tick live.
    await _ws.connect(
      orderId: widget.order.orderId.toString(),
      onConnected: () {
        if (mounted) {
          setState(() {
            _connected = true;
            _statusText = 'Đang theo dõi shipper';
          });
        }
      },
      onError: (e) {
        if (mounted) setState(() => _statusText = 'Mất kết nối, đang thử lại…');
      },
      onPoint: (point) {
        final next = LatLng(point.lat, point.lng);
        if (!mounted) return;

        final prev = _shipper ?? next;
        final movedMeters = const Distance().as(LengthUnit.Meter, prev, next);

        // Nhịp animation theo ts thật (fallback 10s), clamp để mượt & không lố.
        final dtMs = (_lastTs != null && point.ts > _lastTs!)
            ? point.ts - _lastTs!
            : 10000;
        _lastTs = point.ts;

        // Lần đầu có vị trí → tải tuyến để snap-to-road.
        if (_routePath == null && !_routeLoading) _fetchRoute(next);

        // Đứng yên / nhiễu GPS: ghim vị trí, không animate cho khỏi rung.
        if (movedMeters < _minMoveMeters) {
          _anim.stop();
          setState(() {
            _from = next;
            _to = next;
            _shipper = next;
            _segOnRoute = false;
          });
          if (_routePath != null) _curDist = _routePath!.project(next).along;
          if (_follow) _mapController.move(next, _mapController.camera.zoom);
          return;
        }

        // Bám tuyến nếu điểm còn gần polyline; lệch xa → reroute + tạm đi thẳng.
        var onRoute = false;
        var targetDist = _toDist;
        double targetBearing;
        if (_routePath != null) {
          final proj = _routePath!.project(next);
          if (proj.dist <= _rerouteThresholdMeters) {
            onRoute = true;
            targetDist = proj.along;
            targetBearing = _routePath!.bearingAt(targetDist);
          } else {
            targetBearing = _bearingBetween(prev, next);
            if (!_routeLoading) _fetchRoute(next);
          }
        } else {
          targetBearing = _bearingBetween(prev, next);
        }
        if (!onRoute && point.bearing >= 0) targetBearing = point.bearing;

        setState(() {
          _from = prev;
          _to = next;
          _segOnRoute = onRoute;
          if (onRoute) {
            _fromDist = _curDist;
            _toDist = targetDist;
          }
          _bearingFrom = _bearing;
          _bearingTo = targetBearing;
        });
        _anim.duration =
            Duration(milliseconds: dtMs.clamp(_minDurMs, _maxDurMs).toInt());
        _anim.forward(from: 0);
      },
    );
  }

  /// Tải tuyến shipper→đích từ OSRM (qua BE), build RoutePath để snap marker.
  /// Lỗi/204 (OSRM tắt) → giữ nguyên fallback nội suy đường thẳng.
  Future<void> _fetchRoute(LatLng from) async {
    final dest = _dest;
    if (dest == null || _routeLoading) return;
    _routeLoading = true;
    try {
      final ds = ShipperRemoteDataSource(dioClient: context.read<DioClient>());
      final data = await ds.getRoute(
        widget.order.orderId,
        fromLat: from.latitude,
        fromLng: from.longitude,
        toLat: dest.latitude,
        toLng: dest.longitude,
      );
      if (!mounted || data == null) return;
      final geometry = data['geometry'] as String?;
      if (geometry == null || geometry.isEmpty) return;
      final path = RoutePath.decode(geometry);
      if (path.isEmpty) return;
      final along = path.project(_shipper ?? from).along;
      setState(() {
        _routePath = path;
        _curDist = along;
        _fromDist = along;
        _toDist = along;
      });
    } catch (_) {
      // OSRM lỗi → fallback đường thẳng.
    } finally {
      _routeLoading = false;
    }
  }

  @override
  void dispose() {
    _ws.disconnect();
    _anim.dispose();
    super.dispose();
  }

  /// Nút liên hệ shipper (chat + gọi) — chỉ khi đơn đã có shipper.
  /// Đơn đã giao/huỷ → chat read-only, ẩn nút gọi.
  List<Widget>? _buildShipperContactActions() {
    final o = widget.order;
    final shipperId = o.shipperId;
    if (shipperId == null) return null;
    final me = context.read<AuthCubit>().state.currentUser?.userId;
    if (me == null) return null;
    final status = o.status.toUpperCase();
    final readOnly = status == 'DELIVERED' || status == 'CANCELED';
    final shipperName = o.shipperName ?? 'Shipper';
    return [
      IconButton(
        tooltip: 'Nhắn shipper',
        icon: const Icon(Icons.chat_bubble_outline_rounded,
            color: AppColors.primaryRed),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserChatScreen(
              currentUserId: me,
              otherUserId: shipperId,
              otherUserName: shipperName,
              readOnly: readOnly,
              headerSubtitle: 'Đơn #${o.orderId}',
            ),
          ),
        ),
      ),
      if (!readOnly)
        IconButton(
          tooltip: 'Gọi shipper',
          icon: const Icon(Icons.call_rounded, color: AppColors.primaryRed),
          onPressed: () =>
              context.read<CallCubit>().startCall(shipperId, shipperName),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final dest = _dest;
    final center = _shipper ?? dest ?? const LatLng(10.7769, 106.7009);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        title: Text(
          'Theo dõi đơn #${widget.order.orderId}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: _buildShipperContactActions(),
      ),
      body: SafeArea(
        top: false,
        child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: _connected ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
            child: Row(
              children: [
                Icon(
                  _connected ? Icons.gps_fixed_rounded : Icons.sync_rounded,
                  size: 18,
                  color: _connected ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(_statusText, style: GoogleFonts.inter(fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                onPositionChanged: (camera, hasGesture) {
                  // User tự pan → ngừng bám để khỏi giành quyền điều khiển camera.
                  if (hasGesture && _follow) setState(() => _follow = false);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fsmobileapp',
                  maxZoom: 19,
                ),
                if (_routePath != null && !_routePath!.isEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _routePath!.points,
                        strokeWidth: 5,
                        color: const Color(0x991565C0),
                      ),
                    ],
                  ),
                // Đích: tĩnh → layer riêng, không rebuild theo animation.
                if (dest != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: dest,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: const Icon(Icons.home_rounded,
                            color: AppColors.primaryRed, size: 38),
                      ),
                    ],
                  ),
                // Shipper: chỉ layer này rebuild mỗi frame (đọc field _shipper/_bearing
                // do listener cập nhật) → mượt, không kéo theo tile/polyline.
                AnimatedBuilder(
                  animation: _anim,
                  builder: (context, _) {
                    final p = _shipper;
                    if (p == null) return const SizedBox.shrink();
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: p,
                          width: 44,
                          height: 44,
                          // Mũi tên hướng quay theo bearing (rotate side-view scooter
                          // trông sai; đổi asset top-down rồi chỉnh _iconHeadingOffsetDeg).
                          child: Transform.rotate(
                            angle: (_bearing + _iconHeadingOffsetDeg) * pi / 180,
                            child: const Icon(Icons.navigation_rounded,
                                color: Color(0xFF1565C0), size: 40),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          if (_shipper == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Text(
                'Chưa có vị trí shipper. Sẽ hiện khi shipper bắt đầu giao.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
              ),
            ),
        ],
      ),
      ),
      floatingActionButton: (!_follow && _shipper != null)
          ? FloatingActionButton.small(
              onPressed: () {
                setState(() => _follow = true);
                _mapController.move(_shipper!, _mapController.camera.zoom);
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location_rounded,
                  color: Color(0xFF1565C0)),
            )
          : null,
    );
  }
}
