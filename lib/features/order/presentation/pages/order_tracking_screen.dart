import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../../../../core/tracking/tracking_websocket_service.dart';
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
        if (_from != null && _to != null) {
          setState(() => _shipper = _lerp(_from!, _to!, _anim.value));
        }
      });

    _loadLastThenConnect();
  }

  LatLng _lerp(LatLng a, LatLng b, double t) => LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );

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
        setState(() {
          _from = _shipper ?? next;
          _to = next;
        });
        _anim.forward(from: 0);
        _mapController.move(next, _mapController.camera.zoom);
      },
    );
  }

  @override
  void dispose() {
    _ws.disconnect();
    _anim.dispose();
    super.dispose();
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
      ),
      body: Column(
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
              options: MapOptions(initialCenter: center, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.fsmobileapp',
                  maxZoom: 19,
                ),
                MarkerLayer(
                  markers: [
                    if (dest != null)
                      Marker(
                        point: dest,
                        width: 44,
                        height: 44,
                        alignment: Alignment.topCenter,
                        child: const Icon(Icons.home_rounded,
                            color: AppColors.primaryRed, size: 38),
                      ),
                    if (_shipper != null)
                      Marker(
                        point: _shipper!,
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
    );
  }
}
