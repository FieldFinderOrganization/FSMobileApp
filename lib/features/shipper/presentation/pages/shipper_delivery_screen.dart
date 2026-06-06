import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/location_helper.dart' as loc;
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/tracking/route_path.dart';
import '../../../../core/tracking/tracking_websocket_service.dart';
import '../../../order/data/models/order_model.dart';
import '../../data/shipper_remote_data_source.dart';

/// Màn giao hàng của shipper: bật gửi GPS mỗi 10s, hiển thị vị trí + đích.
class ShipperDeliveryScreen extends StatefulWidget {
  final OrderModel order;
  const ShipperDeliveryScreen({super.key, required this.order});

  @override
  State<ShipperDeliveryScreen> createState() => _ShipperDeliveryScreenState();
}

class _ShipperDeliveryScreenState extends State<ShipperDeliveryScreen> {
  static const _interval = Duration(seconds: 10);
  static const _demoInterval = Duration(seconds: 2);
  static const _demoSpeedMps = 12.0; // ~43 km/h

  late final TrackingWebSocketService _ws;
  late final ShipperRemoteDataSource _ds;
  Timer? _timer;
  final MapController _mapController = MapController();

  LatLng? _me;
  bool _sending = false;
  bool _finishing = false;
  String _status = 'Đang khởi động…';

  // Demo tự di chuyển (bảo vệ khoá luận: máy đứng yên → không có GPS thật).
  bool _demoMode = false;
  Timer? _demoTimer;
  RoutePath? _demoPath;
  double _demoDist = 0;

  // Kho (chặng 1) — shipper tới kho lấy hàng trước khi giao khách.
  LatLng? _warehouse;
  String? _warehouseName;
  bool _picked = false; // đã lấy hàng tại kho → chuyển sang giao khách.

  LatLng? get _dest =>
      (widget.order.destLat != null && widget.order.destLng != null)
          ? LatLng(widget.order.destLat!, widget.order.destLng!)
          : null;

  /// Đích chặng hiện tại: chưa lấy hàng → kho; đã lấy → nhà khách.
  LatLng? get _target => _picked ? _dest : (_warehouse ?? _dest);

  Future<void> _loadWarehouse() async {
    try {
      final w = await _ds.getWarehouse();
      if (w == null || !mounted) return;
      final lat = (w['lat'] as num?)?.toDouble();
      final lng = (w['lng'] as num?)?.toDouble();
      if (lat == null || lng == null) return;
      setState(() {
        _warehouse = LatLng(lat, lng);
        _warehouseName = w['name'] as String?;
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _ws = TrackingWebSocketService(tokenStorage: context.read<TokenStorage>());
    _ds = ShipperRemoteDataSource(dioClient: context.read<DioClient>());
    _loadWarehouse();
    _start();
  }

  Future<void> _start() async {
    // SHIPPING/DELIVERED = đã lấy hàng (chặng 2). Còn lại = chặng 1 (đến kho).
    final s = widget.order.status.toUpperCase();
    _picked = s == 'SHIPPING' || s == 'DELIVERED';
    await _ws.connect(
      orderId: widget.order.orderId.toString(),
      onConnected: () {
        if (mounted) setState(() => _status = 'Đang gửi vị trí (10s/lần)');
        if (_demoMode) return; // demo đang chạy → không bật GPS thật.
        _sendOnce();
        _timer = Timer.periodic(_interval, (_) => _sendOnce());
      },
      onError: (e) {
        if (mounted) setState(() => _status = 'Mất kết nối, đang thử lại…');
      },
    );
  }

  Future<void> _sendOnce() async {
    if (_sending || _demoMode) return;
    _sending = true;
    try {
      final pos = await loc.LocationHelper.currentPositionFull();
      if (pos == null || !mounted) return;
      final p = LatLng(pos.latitude, pos.longitude);
      setState(() => _me = p);
      _ws.sendLocation(
        orderId: widget.order.orderId.toString(),
        lat: p.latitude,
        lng: p.longitude,
        speed: pos.speed,
        bearing: pos.heading,
        ts: pos.timestamp.millisecondsSinceEpoch,
      );
      _mapController.move(p, _mapController.camera.zoom);
    } finally {
      _sending = false;
    }
  }

  // ─── Demo: shipper tự di chuyển ───────────────────────────────────────────
  // Tắt GPS thật, "đi bộ" dọc tuyến (OSRM, fallback đường thẳng), gửi điểm mỗi
  // 2s qua đúng kênh sendLocation → user app thấy shipper chạy real-time.

  void _toggleDemo() {
    final target = _target;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có toạ độ đích chặng này — không demo được')),
      );
      return;
    }
    if (_demoMode) {
      _demoTimer?.cancel();
      setState(() {
        _demoMode = false;
        _demoPath = null;
        _status = 'Đang gửi vị trí (10s/lần)';
      });
      _sendOnce(); // bật lại GPS thật.
      _timer = Timer.periodic(_interval, (_) => _sendOnce());
    } else {
      _timer?.cancel(); // tắt GPS thật.
      setState(() {
        _demoMode = true;
        _status = 'DEMO: đang tải tuyến…';
      });
      _startDemo(target);
    }
  }

  Future<void> _startDemo(LatLng dest) async {
    final start = _me ?? _syntheticStart(dest);
    RoutePath? path;
    try {
      final data = await _ds.getRoute(
        widget.order.orderId,
        fromLat: start.latitude,
        fromLng: start.longitude,
        toLat: dest.latitude,
        toLng: dest.longitude,
      );
      final geometry = data?['geometry'] as String?;
      if (geometry != null && geometry.isNotEmpty) path = RoutePath.decode(geometry);
    } catch (_) {
      // OSRM tắt/lỗi → đi thẳng.
    }
    if (path == null || path.isEmpty) path = RoutePath([start, dest]);
    if (!mounted || !_demoMode) return;
    setState(() {
      _demoPath = path;
      _demoDist = 0;
      _status = 'DEMO: shipper đang di chuyển…';
    });
    _demoTick(); // gửi điểm đầu ngay.
    _demoTimer = Timer.periodic(_demoInterval, (_) => _demoTick());
  }

  void _demoTick() {
    final path = _demoPath;
    if (path == null || !_demoMode) return;
    final reached = _demoDist >= path.totalMeters;
    final m = reached ? path.totalMeters : _demoDist;
    final p = path.pointAt(m);
    if (mounted) setState(() => _me = p);
    _ws.sendLocation(
      orderId: widget.order.orderId.toString(),
      lat: p.latitude,
      lng: p.longitude,
      speed: reached ? 0 : _demoSpeedMps,
      bearing: path.bearingAt(m),
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    _mapController.move(p, _mapController.camera.zoom);
    if (reached) {
      _demoTimer?.cancel();
      if (mounted) {
        setState(() => _status = _picked
            ? 'DEMO: đã tới khách'
            : 'DEMO: đã tới kho — bấm "Đã lấy hàng"');
      }
      return;
    }
    _demoDist += _demoSpeedMps * _demoInterval.inMilliseconds / 1000;
  }

  /// Điểm xuất phát giả khi chưa có GPS (lệch ~2–3km so với đích).
  LatLng _syntheticStart(LatLng dest) =>
      LatLng(dest.latitude + 0.02, dest.longitude + 0.02);

  Future<void> _markPickedUp() async {
    setState(() => _finishing = true);
    try {
      await _ds.updateStatus(widget.order.orderId, 'SHIPPING');
      if (!mounted) return;
      setState(() {
        _picked = true;
        _finishing = false;
        _status =
            _demoMode ? 'DEMO: đang giao tới khách…' : 'Đã lấy hàng — đang giao';
      });
      // Demo: chạy tiếp chặng kho→khách.
      if (_demoMode) {
        _demoTimer?.cancel();
        final d = _dest;
        if (d != null) _startDemo(d);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _markDelivered() async {
    setState(() => _finishing = true);
    try {
      await _ds.updateStatus(widget.order.orderId, 'DELIVERED');
      _timer?.cancel();
      _ws.disconnect();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã giao hàng thành công')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _demoTimer?.cancel();
    _ws.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = _target;
    final center = _me ?? target ?? const LatLng(10.7769, 106.7009);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        title: Text('Giao đơn #${widget.order.orderId}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: _demoMode ? 'Dừng demo' : 'Demo tự di chuyển',
            onPressed: _toggleDemo,
            icon: Icon(
              _demoMode ? Icons.stop_circle_rounded : Icons.smart_toy_rounded,
              color: _demoMode ? AppColors.primaryRed : const Color(0xFF1565C0),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFE3F2FD),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed_rounded,
                    size: 18, color: Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Expanded(child: Text(_status, style: GoogleFonts.inter(fontSize: 13))),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(_picked ? Icons.home_rounded : Icons.warehouse_rounded,
                    size: 18,
                    color: _picked
                        ? AppColors.primaryRed
                        : const Color(0xFF1565C0)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _picked
                        ? (widget.order.deliveryAddress ?? 'Giao tới khách')
                        : 'Đến kho lấy hàng${_warehouseName != null ? ': $_warehouseName' : ''}',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: center, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fsmobileapp',
                  maxZoom: 19,
                ),
                if (_demoMode && _demoPath != null && !_demoPath!.isEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _demoPath!.points,
                        strokeWidth: 5,
                        color: const Color(0x991565C0),
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (target != null)
                      Marker(
                        point: target,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: Icon(
                          _picked
                              ? Icons.home_rounded
                              : Icons.warehouse_rounded,
                          color: _picked
                              ? AppColors.primaryRed
                              : const Color(0xFF1565C0),
                          size: 38,
                        ),
                      ),
                    if (_me != null)
                      Marker(
                        point: _me!,
                        width: 44,
                        height: 44,
                        child: const Icon(Icons.delivery_dining_rounded,
                            color: Color(0xFF1565C0), size: 40),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton.icon(
            onPressed:
                _finishing ? null : (_picked ? _markDelivered : _markPickedUp),
            icon: _finishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Icon(
                    _picked
                        ? Icons.check_circle_rounded
                        : Icons.inventory_2_rounded,
                    color: Colors.white),
            label: Text(_picked ? 'Đã giao hàng' : 'Đã lấy hàng tại kho',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _picked ? Colors.green : const Color(0xFF1565C0),
              minimumSize: const Size.fromHeight(50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ),
    );
  }
}
