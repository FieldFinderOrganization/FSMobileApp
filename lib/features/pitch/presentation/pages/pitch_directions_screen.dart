import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/location_helper.dart' show LocationHelper;
import '../../../../core/network/dio_client.dart';
import '../../../../core/tracking/route_path.dart';
import '../../data/datasources/pitch_remote_datasource.dart';
import '../../domain/entities/pitch_entity.dart';

/// Dẫn đường từ vị trí user hiện tại đến sân.
/// Vẽ tuyến OSRM (qua BE); OSRM tắt/lỗi → fallback đường thẳng.
class PitchDirectionsScreen extends StatefulWidget {
  final PitchEntity pitch;

  const PitchDirectionsScreen({super.key, required this.pitch});

  @override
  State<PitchDirectionsScreen> createState() => _PitchDirectionsScreenState();
}

class _PitchDirectionsScreenState extends State<PitchDirectionsScreen> {
  final MapController _mapController = MapController();

  LatLng? _user;
  RoutePath? _routePath;
  double? _distanceMeters;
  double? _durationSeconds;

  bool _loading = true;
  String? _error;

  LatLng get _dest => LatLng(widget.pitch.latitude!, widget.pitch.longitude!);

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final pos = await LocationHelper.currentPosition();
    if (!mounted) return;
    if (pos == null) {
      setState(() {
        _loading = false;
        _error = 'Không lấy được vị trí. Bật GPS và cấp quyền vị trí rồi thử lại.';
      });
      return;
    }
    final user = LatLng(pos.latitude, pos.longitude);
    _user = user;

    // Lấy tuyến từ BE (OSRM). Lỗi/204 → đường thẳng user→sân.
    RoutePath path;
    double? dist;
    double? dur;
    try {
      final ds = PitchRemoteDatasource(context.read<DioClient>().dio);
      final data = await ds.fetchPitchRoute(
        widget.pitch.pitchId,
        fromLat: user.latitude,
        fromLng: user.longitude,
      );
      final geometry = data?['geometry'] as String?;
      if (geometry != null && geometry.isNotEmpty) {
        path = RoutePath.decode(geometry);
        dist = (data?['distanceMeters'] as num?)?.toDouble();
        dur = (data?['durationSeconds'] as num?)?.toDouble();
      } else {
        path = RoutePath([user, _dest]);
      }
    } catch (_) {
      path = RoutePath([user, _dest]);
    }
    if (path.isEmpty) path = RoutePath([user, _dest]);

    if (!mounted) return;
    setState(() {
      _routePath = path;
      _distanceMeters = dist;
      _durationSeconds = dur;
      _loading = false;
    });
    _fitBounds(user, _dest);
  }

  void _fitBounds(LatLng a, LatLng b) {
    final bounds = LatLngBounds(a, b);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(64),
      ),
    );
  }

  String _fmtDistance(double? m) {
    if (m == null) return '—';
    return m >= 1000
        ? '${(m / 1000).toStringAsFixed(1)} km'
        : '${m.toStringAsFixed(0)} m';
  }

  String _fmtDuration(double? s) {
    if (s == null) return '—';
    final mins = (s / 60).round();
    if (mins < 60) return '$mins phút';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '$h giờ' : '$h giờ $m phút';
  }

  @override
  Widget build(BuildContext context) {
    final center = _user ?? _dest;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
        title: Text(
          'Dẫn đường tới ${widget.pitch.name}',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: _error != null
          ? _buildError()
          : Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.fsmobileapp',
                      maxZoom: 19,
                    ),
                    if (_routePath != null && !_routePath!.isEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routePath!.points,
                            strokeWidth: 5,
                            color: const Color(0x99B71C1C),
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _dest,
                          width: 44,
                          height: 44,
                          alignment: Alignment.topCenter,
                          child: const Icon(Icons.sports_soccer_rounded,
                              color: AppColors.primaryRed, size: 38),
                        ),
                        if (_user != null)
                          Marker(
                            point: _user!,
                            width: 40,
                            height: 40,
                            child: const Icon(Icons.my_location_rounded,
                                color: Color(0xFF1565C0), size: 32),
                          ),
                      ],
                    ),
                  ],
                ),
                if (_loading)
                  const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.primaryRed),
                  ),
                if (!_loading && _routePath != null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _buildInfoCard(),
                  ),
              ],
            ),
      floatingActionButton: (!_loading && _user != null)
          ? FloatingActionButton.small(
              onPressed: () => _fitBounds(_user!, _dest),
              backgroundColor: Colors.white,
              child: const Icon(Icons.center_focus_strong_rounded,
                  color: Color(0xFF1565C0)),
            )
          : null,
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          _infoChunk(Icons.straighten_rounded, 'Khoảng cách',
              _fmtDistance(_distanceMeters)),
          Container(width: 1, height: 36, color: const Color(0xFFEEEEEE)),
          _infoChunk(Icons.schedule_rounded, 'Thời gian',
              _fmtDuration(_durationSeconds)),
        ],
      ),
    );
  }

  Widget _infoChunk(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primaryRed),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textGrey)),
              Text(value,
                  style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_off_rounded,
                size: 48, color: AppColors.textGrey),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _init,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed),
              child: Text('Thử lại',
                  style: GoogleFonts.inter(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
