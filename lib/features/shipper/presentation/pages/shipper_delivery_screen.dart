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

  late final TrackingWebSocketService _ws;
  late final ShipperRemoteDataSource _ds;
  Timer? _timer;
  final MapController _mapController = MapController();

  LatLng? _me;
  bool _sending = false;
  bool _finishing = false;
  String _status = 'Đang khởi động…';

  LatLng? get _dest =>
      (widget.order.destLat != null && widget.order.destLng != null)
          ? LatLng(widget.order.destLat!, widget.order.destLng!)
          : null;

  @override
  void initState() {
    super.initState();
    _ws = TrackingWebSocketService(tokenStorage: context.read<TokenStorage>());
    _ds = ShipperRemoteDataSource(dioClient: context.read<DioClient>());
    _start();
  }

  Future<void> _start() async {
    // Đảm bảo đơn ở trạng thái SHIPPING.
    if (widget.order.status.toUpperCase() != 'SHIPPING') {
      try {
        await _ds.updateStatus(widget.order.orderId, 'SHIPPING');
      } catch (_) {}
    }
    await _ws.connect(
      orderId: widget.order.orderId.toString(),
      onConnected: () {
        if (mounted) setState(() => _status = 'Đang gửi vị trí (10s/lần)');
        _sendOnce();
        _timer = Timer.periodic(_interval, (_) => _sendOnce());
      },
      onError: (e) {
        if (mounted) setState(() => _status = 'Mất kết nối, đang thử lại…');
      },
    );
  }

  Future<void> _sendOnce() async {
    if (_sending) return;
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
    _ws.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dest = _dest;
    final center = _me ?? dest ?? const LatLng(10.7769, 106.7009);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        title: Text('Giao đơn #${widget.order.orderId}',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
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
          if (widget.order.deliveryAddress != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.home_rounded,
                      size: 18, color: AppColors.primaryRed),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(widget.order.deliveryAddress!,
                        style: GoogleFonts.inter(fontSize: 13)),
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
            onPressed: _finishing ? null : _markDelivered,
            icon: _finishing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded, color: Colors.white),
            label: Text('Đã giao hàng',
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
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
