import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/location_helper.dart' as loc;
import '../../../../core/network/dio_client.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/tracking/route_path.dart';
import '../../../../core/tracking/tracking_websocket_service.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../call/presentation/cubit/call_cubit.dart';
import '../../../chat/presentation/pages/user_chat_screen.dart';
import '../../../order/data/models/order_model.dart';
import '../../data/shipper_remote_data_source.dart';

/// Màn giao hàng của shipper: bật gửi GPS mỗi 10s, hiển thị vị trí + đích.
class ShipperDeliveryScreen extends StatefulWidget {
  final OrderModel order;
  const ShipperDeliveryScreen({super.key, required this.order});

  @override
  State<ShipperDeliveryScreen> createState() => _ShipperDeliveryScreenState();
}

class _ShipperDeliveryScreenState extends State<ShipperDeliveryScreen>
    with WidgetsBindingObserver {
  static const _interval = Duration(seconds: 10);
  static const _demoInterval = Duration(seconds: 2);
  static const _demoSpeedMps = 12.0; // ~43 km/h

  late final TrackingWebSocketService _ws;
  late final ShipperRemoteDataSource _ds;
  Timer? _timer;
  final MapController _mapController = MapController();

  LatLng? _me;
  // Vị trí shipper cho marker — cập nhật qua notifier để CHỈ marker rebuild,
  // không setState cả map (tile/polyline) mỗi tick → mượt, không giật.
  final ValueNotifier<LatLng?> _meVN = ValueNotifier<LatLng?>(null);
  bool _sending = false;
  bool _finishing = false;
  String _status = 'Đang khởi động…';

  // Camera bám shipper; tắt khi user tự pan để xem tuyến (giống màn customer).
  bool _follow = true;

  // Demo tự di chuyển (bảo vệ khoá luận: máy đứng yên → không có GPS thật).
  bool _demoMode = false;
  Timer? _demoTimer;
  RoutePath? _demoPath;
  double _demoDist = 0;
  // Lưu lại để persist/khôi phục bot khi thoát màn / chuyển nền.
  String? _demoGeometry; // polyline OSRM; null nếu fallback đường thẳng.
  LatLng? _demoStart;
  LatLng? _demoDest;

  String get _demoKey => 'demo_state_${widget.order.orderId}';

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
    WidgetsBinding.instance.addObserver(this);
    _ws = TrackingWebSocketService(tokenStorage: context.read<TokenStorage>());
    _ds = ShipperRemoteDataSource(dioClient: context.read<DioClient>());
    _loadWarehouse();
    // Khôi phục bot trước (nếu có) → set _demoMode=true để _start không bật GPS thật.
    _restoreDemo().then((_) {
      if (mounted) _start();
    });
  }

  Future<void> _start() async {
    // SHIPPING/DELIVERED = đã lấy hàng (chặng 2). Còn lại = chặng 1 (đến kho).
    // Đang restore demo → giữ _picked đã khôi phục, không ghi đè từ status.
    if (!_demoMode) {
      final s = widget.order.status.toUpperCase();
      _picked = s == 'SHIPPING' || s == 'DELIVERED';
    }
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
      _me = p;
      _meVN.value = p; // chỉ marker rebuild
      _ws.sendLocation(
        orderId: widget.order.orderId.toString(),
        lat: p.latitude,
        lng: p.longitude,
        speed: pos.speed,
        bearing: pos.heading,
        ts: pos.timestamp.millisecondsSinceEpoch,
      );
      if (_follow) _mapController.move(p, _mapController.camera.zoom);
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
      _clearDemo(); // tắt demo → xoá state đã lưu, không resume.
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
    String? geometry;
    try {
      final data = await _ds.getRoute(
        widget.order.orderId,
        fromLat: start.latitude,
        fromLng: start.longitude,
        toLat: dest.latitude,
        toLng: dest.longitude,
      );
      geometry = data?['geometry'] as String?;
      if (geometry != null && geometry.isNotEmpty) path = RoutePath.decode(geometry);
    } catch (_) {
      // OSRM tắt/lỗi → đi thẳng.
    }
    if (path == null || path.isEmpty) {
      path = RoutePath([start, dest]);
      geometry = null; // fallback đường thẳng → rebuild từ start/dest khi restore.
    }
    if (!mounted || !_demoMode) return;
    setState(() {
      _demoGeometry = geometry;
      _demoStart = start;
      _demoDest = dest;
      _demoPath = path;
      _demoDist = 0;
      _status = 'DEMO: shipper đang di chuyển…';
    });
    _persistDemo(); // lưu ngay khi bắt đầu chặng.
    _demoTick(); // gửi điểm đầu ngay.
    _demoTimer = Timer.periodic(_demoInterval, (_) => _demoTick());
  }

  void _demoTick() {
    final path = _demoPath;
    if (path == null || !_demoMode) return;
    final reached = _demoDist >= path.totalMeters;
    final m = reached ? path.totalMeters : _demoDist;
    final p = path.pointAt(m);
    _me = p;
    if (mounted) _meVN.value = p; // chỉ marker rebuild
    _ws.sendLocation(
      orderId: widget.order.orderId.toString(),
      lat: p.latitude,
      lng: p.longitude,
      speed: reached ? 0 : _demoSpeedMps,
      bearing: path.bearingAt(m),
      ts: DateTime.now().millisecondsSinceEpoch,
    );
    if (_follow) _mapController.move(p, _mapController.camera.zoom);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: ${messageFromError(e)}')));
    }
  }

  /// Đơn CASH: xác nhận đã thu tiền mặt trước khi đánh dấu giao xong.
  /// (BE tự ghi Payment=PAID khi DELIVERED+CASH.)
  Future<bool> _confirmCodIfNeeded() async {
    if (widget.order.paymentMethod.toUpperCase() != 'CASH') return true;
    final amount =
        NumberFormat('#,###', 'vi_VN').format(widget.order.totalAmount);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận thu COD'),
        content: Text('Bạn đã thu đủ $amountđ tiền mặt từ khách?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Chưa'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đã thu'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _openCustomerChat() {
    final me = context.read<AuthCubit>().state.currentUser?.userId;
    final customerId = widget.order.customerId;
    if (me == null || customerId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserChatScreen(
          currentUserId: me,
          otherUserId: customerId,
          otherUserName: widget.order.userName,
          headerSubtitle: 'Đơn #${widget.order.orderId}',
        ),
      ),
    );
  }

  Future<void> _markDelivered() async {
    if (!await _confirmCodIfNeeded()) return;
    if (!mounted) return;
    setState(() => _finishing = true);
    try {
      await _ds.updateStatus(widget.order.orderId, 'DELIVERED');
      _timer?.cancel();
      _demoTimer?.cancel();
      _clearDemo(); // giao xong → xoá state bot, không resume nữa.
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
        SnackBar(content: Text('Lỗi: ${messageFromError(e)}')),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Chuyển nền: timer bị OS treo → lưu mốc rồi huỷ, resume sẽ fast-forward.
      if (_demoMode) {
        _persistDemo();
        _demoTimer?.cancel();
      }
    } else if (state == AppLifecycleState.resumed) {
      if (_demoMode) _restoreDemo(); // tính thời gian đã trôi, chạy tiếp.
    }
  }

  // ─── Persist / restore bot ────────────────────────────────────────────────
  // Bot chỉ là sim client-side → State mất khi rời màn/chuyển nền. Lưu mốc
  // (tuyến + quãng đã đi + ts) vào SharedPreferences; mở lại fast-forward theo
  // thời gian đã trôi rồi chạy tiếp (không reset về đầu).

  Future<void> _persistDemo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_demoMode || _demoPath == null || _demoStart == null || _demoDest == null) {
        await prefs.remove(_demoKey);
        return;
      }
      await prefs.setString(
        _demoKey,
        jsonEncode({
          'demoMode': true,
          'picked': _picked,
          'demoDist': _demoDist,
          'speed': _demoSpeedMps,
          'savedTs': DateTime.now().millisecondsSinceEpoch,
          'routeGeometry': _demoGeometry,
          'startLat': _demoStart!.latitude,
          'startLng': _demoStart!.longitude,
          'destLat': _demoDest!.latitude,
          'destLng': _demoDest!.longitude,
        }),
      );
    } catch (_) {}
  }

  Future<void> _clearDemo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_demoKey);
    } catch (_) {}
  }

  Future<void> _restoreDemo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_demoKey);
      if (raw == null) return;
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['demoMode'] != true) return;

      final start = LatLng(
          (m['startLat'] as num).toDouble(), (m['startLng'] as num).toDouble());
      final dest = LatLng(
          (m['destLat'] as num).toDouble(), (m['destLng'] as num).toDouble());
      final geom = m['routeGeometry'] as String?;
      var path = (geom != null && geom.isNotEmpty)
          ? RoutePath.decode(geom)
          : RoutePath([start, dest]);
      if (path.isEmpty) path = RoutePath([start, dest]);

      final speed = (m['speed'] as num?)?.toDouble() ?? _demoSpeedMps;
      final savedTs =
          (m['savedTs'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
      final savedDist = (m['demoDist'] as num?)?.toDouble() ?? 0;
      final elapsed = (DateTime.now().millisecondsSinceEpoch - savedTs) / 1000.0;
      final dist = (savedDist + speed * elapsed).clamp(0.0, path.totalMeters);

      if (!mounted) return;
      _timer?.cancel(); // tắt GPS thật nếu lỡ bật.
      _demoTimer?.cancel();
      setState(() {
        _demoMode = true;
        _picked = m['picked'] == true;
        _demoGeometry = geom;
        _demoStart = start;
        _demoDest = dest;
        _demoPath = path;
        _demoDist = dist;
        _status = 'DEMO: shipper đang di chuyển…';
      });
      _demoTick(); // gửi vị trí hiện tại lên topic ngay cho customer thấy.
      _demoTimer = Timer.periodic(_demoInterval, (_) => _demoTick());
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_demoMode) _persistDemo(); // rời màn → lưu để mở lại chạy tiếp.
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _demoTimer?.cancel();
    _ws.disconnect();
    _meVN.dispose();
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
          if (widget.order.customerId != null) ...[
            IconButton(
              tooltip: 'Nhắn khách',
              onPressed: _openCustomerChat,
              icon: const Icon(Icons.chat_bubble_outline_rounded,
                  color: Color(0xFF1565C0)),
            ),
            IconButton(
              tooltip: 'Gọi khách',
              onPressed: () => context.read<CallCubit>().startCall(
                  widget.order.customerId!, widget.order.userName),
              icon:
                  const Icon(Icons.call_rounded, color: Color(0xFF1565C0)),
            ),
          ],
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
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                onPositionChanged: (camera, hasGesture) {
                  // User tự pan/zoom → ngừng bám để xem tuyến, hiện nút recenter.
                  if (hasGesture && _follow) setState(() => _follow = false);
                },
              ),
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
                // Đích chặng: tĩnh (đổi khi _picked qua setState) → layer riêng.
                if (target != null)
                  MarkerLayer(
                    markers: [
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
                    ],
                  ),
                // Shipper: chỉ layer này rebuild mỗi tick (qua _meVN), không kéo map.
                ValueListenableBuilder<LatLng?>(
                  valueListenable: _meVN,
                  builder: (context, me, _) {
                    if (me == null) return const SizedBox.shrink();
                    return MarkerLayer(
                      markers: [
                        Marker(
                          point: me,
                          width: 44,
                          height: 44,
                          child: const Icon(Icons.delivery_dining_rounded,
                              color: Color(0xFF1565C0), size: 40),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: (!_follow && _me != null)
          ? FloatingActionButton.small(
              onPressed: () {
                setState(() => _follow = true);
                _mapController.move(_me!, _mapController.camera.zoom);
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location_rounded,
                  color: Color(0xFF1565C0)),
            )
          : null,
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
