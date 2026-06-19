import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../constants/app_colors.dart';
import 'location_helper.dart' as loc;

/// Kết quả chọn vị trí: toạ độ + địa chỉ reverse-geocode (nếu có).
class MapPickResult {
  final LatLng latLng;
  final String? address;   // display_name đầy đủ
  final String? district;  // quận/huyện
  final String? province;  // tỉnh/thành phố

  const MapPickResult({
    required this.latLng,
    this.address,
    this.district,
    this.province,
  });
}

/// Màn chọn vị trí trên bản đồ (OSM, không cần API key).
/// Chạm để đặt ghim → trả về [MapPickResult] qua Navigator.pop.
class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String title;

  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.title = 'Chọn vị trí',
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  final MapController _controller = MapController();
  // Mặc định trung tâm TP.HCM nếu chưa có toạ độ.
  static const LatLng _fallback = LatLng(10.7769, 106.7009);

  late LatLng _picked;
  bool _locating = false;
  bool _confirming = false;
  bool _searching = false;
  final TextEditingController _searchCtrl = TextEditingController();
  List<_SearchHit> _results = [];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _picked = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : _fallback;
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    final pos = await loc.LocationHelper.currentPosition();
    if (!mounted) return;
    setState(() => _locating = false);
    if (pos == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không lấy được vị trí. Bật GPS / cấp quyền vị trí.'),
        ),
      );
      return;
    }
    final p = LatLng(pos.latitude, pos.longitude);
    setState(() => _picked = p);
    _controller.move(p, 16);
  }

  /// Forward geocode: gõ địa chỉ → danh sách điểm (Nominatim search).
  Future<void> _search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final dio = Dio();
      final resp = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': q,
          'format': 'json',
          'limit': 6,
          'countrycodes': 'vn',
          'accept-language': 'vi',
        },
        options: Options(
          headers: {'User-Agent': 'FSMobileApp/1.0 (sportshub)'},
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final list = (resp.data as List)
          .map((e) => _SearchHit(
                name: e['display_name']?.toString() ?? '',
                lat: double.tryParse(e['lat'].toString()) ?? 0,
                lng: double.tryParse(e['lon'].toString()) ?? 0,
              ))
          .where((h) => h.lat != 0 || h.lng != 0)
          .toList();
      if (!mounted) return;
      setState(() => _results = list);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectHit(_SearchHit h) {
    final p = LatLng(h.lat, h.lng);
    setState(() {
      _picked = p;
      _results = [];
      _searchCtrl.clear();
    });
    FocusScope.of(context).unfocus();
    _controller.move(p, 16);
  }

  /// Reverse geocode Nominatim → MapPickResult (lỗi → chỉ toạ độ).
  Future<MapPickResult> _resolve() async {
    try {
      final dio = Dio();
      final resp = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': _picked.latitude,
          'lon': _picked.longitude,
          'format': 'json',
          'addressdetails': 1,
          'accept-language': 'vi',
        },
        options: Options(
          headers: {'User-Agent': 'FSMobileApp/1.0 (sportshub)'},
          sendTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      final data = resp.data as Map<String, dynamic>;
      final addr = data['address'] as Map<String, dynamic>?;
      String? pick(List<String> keys) {
        if (addr == null) return null;
        for (final k in keys) {
          final v = addr[k];
          if (v != null && v.toString().trim().isNotEmpty) return v.toString();
        }
        return null;
      }

      final district = pick(['city_district', 'suburb', 'county', 'quarter', 'ward']);
      final province = pick(['city', 'state', 'region']);

      // Ghép địa chỉ NGẮN từ component (tránh display_name dài + lặp quận/tỉnh).
      final parts = <String>[];
      void add(String? v) {
        if (v == null) return;
        final s = v.trim();
        if (s.isEmpty) return;
        if (s == district || s == province) return; // không lặp quận/tỉnh
        if (parts.contains(s)) return;
        parts.add(s);
      }
      add(pick(['amenity', 'building', 'shop', 'office', 'tourism']));
      add(addr?['house_number']?.toString());
      add(addr?['road']?.toString());
      add(pick(['neighbourhood', 'residential', 'hamlet']));

      final shortAddress = parts.isNotEmpty
          ? parts.join(', ')
          : data['display_name']?.toString();

      return MapPickResult(
        latLng: _picked,
        address: shortAddress,
        district: district,
        province: province,
      );
    } catch (_) {
      return MapPickResult(latLng: _picked);
    }
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    final result = await _resolve();
    if (!mounted) return;
    setState(() => _confirming = false);
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 1,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _picked,
              initialZoom: 15,
              onTap: (_, point) => setState(() => _picked = point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.fsmobileapp',
                maxZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _picked,
                    width: 44,
                    height: 44,
                    alignment: Alignment.topCenter,
                    child: const Icon(Icons.location_on,
                        color: AppColors.primaryRed, size: 44),
                  ),
                ],
              ),
            ],
          ),
          // Ô tìm địa chỉ + kết quả + toạ độ
          Positioned(
            left: 12,
            right: 12,
            top: 12,
            child: Column(
              children: [
                // Thanh tìm kiếm
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 20, color: AppColors.textGrey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            onSubmitted: _search,
                            style: GoogleFonts.inter(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Nhập địa chỉ để tìm…',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searching)
                          const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                        else if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() {
                              _searchCtrl.clear();
                              _results = [];
                            }),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.arrow_forward, size: 18),
                            onPressed: () => _search(_searchCtrl.text),
                          ),
                      ],
                    ),
                  ),
                ),
                // Kết quả tìm kiếm
                if (_results.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _results.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFEEEEEE)),
                      itemBuilder: (_, i) {
                        final h = _results[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined,
                              size: 18, color: AppColors.primaryRed),
                          title: Text(h.name,
                              style: GoogleFonts.inter(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis),
                          onTap: () => _selectHit(h),
                        );
                      },
                    ),
                  ),
                // Toạ độ + nút vị trí hiện tại
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location,
                              size: 18, color: AppColors.textGrey),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_picked.latitude.toStringAsFixed(6)}, ${_picked.longitude.toStringAsFixed(6)}',
                              style: GoogleFonts.inter(fontSize: 13),
                            ),
                          ),
                          TextButton(
                            onPressed: _locating ? null : _useCurrentLocation,
                            child: _locating
                                ? const SizedBox(
                                    width: 16, height: 16,
                                    child:
                                        CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Vị trí của tôi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Hướng dẫn
          Positioned(
            left: 12,
            right: 12,
            bottom: 84,
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Chạm vào bản đồ để đặt ghim',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: _confirming ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: _confirming
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Xác nhận vị trí',
                    style: GoogleFonts.inter(
                        color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}

class _SearchHit {
  final String name;
  final double lat;
  final double lng;
  const _SearchHit({required this.name, required this.lat, required this.lng});
}
