import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import '../../data/models/admin_pitch_list_model.dart';
import '../../data/models/pitch_type_model.dart';
import 'admin_users_screen.dart' show buildAdminPaginationBar;

class AdminPitchesScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;
  final List<PitchTypeModel> pitchTypeData;

  const AdminPitchesScreen({
    super.key,
    required this.datasource,
    required this.pitchTypeData,
  });

  @override
  State<AdminPitchesScreen> createState() => _AdminPitchesScreenState();
}

class _AdminPitchesScreenState extends State<AdminPitchesScreen> {
  static const _accent = Color(0xFF3E54AC);
  static const _kViolet = Color(0xFF7C6FCD);
  static const _kTeal = Color(0xFF0D9988);

  static const _typeColors = [_accent, _kViolet, _kTeal];

  AdminPitchListModel? _page;
  bool _loading = true;
  String? _error;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({int page = 0}) async {
    setState(() { _loading = true; _error = null; _currentPage = page; });
    try {
      final result = await widget.datasource.getAdminPitches(page: page);
      setState(() { _page = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _envLabel(String e) {
    return switch (e) {
      'INDOOR' => 'Trong nhà',
      'OUTDOOR' => 'Ngoài trời',
      _ => e,
    };
  }

  String _fmtPrice(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr/h';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k/h';
    return '${v.toStringAsFixed(0)}/h';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildDonut()),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Text(_error!)))
          else
            SliverToBoxAdapter(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: _accent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(56, 0, 16, 16),
        title: Text('Sân hoạt động',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2A3D8F), Color(0xFF5C75D4)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonut() {
    final pts = widget.pitchTypeData;
    if (pts.isEmpty) return const SizedBox();
    final total = pts.fold(0.0, (a, b) => a + b.count);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _accent.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phân bổ loại sân',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutP(
                      values: pts.map((p) => p.count.toDouble()).toList(),
                      colors: _typeColors,
                    ),
                    child: Center(
                      child: Text('${total.toInt()}',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: pts.asMap().entries.map((e) {
                      final color = _typeColors[e.key % _typeColors.length];
                      final pct = total > 0 ? (e.value.count / total * 100).toStringAsFixed(1) : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(e.value.type,
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600))),
                            Text('${e.value.count} ($pct%)',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    final items = _page?.content ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Danh sách sân',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
              if (_page != null)
                Text('${_page!.totalElements} sân',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ...items.asMap().entries.map((e) => _buildRow(e.value, e.key == items.length - 1)),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Không có dữ liệu', style: GoogleFonts.inter(color: Colors.grey.shade400)),
                  ),
              ],
            ),
          ),
          if (_page != null && _page!.totalPages > 1) ...[
            const SizedBox(height: 16),
            buildAdminPaginationBar(_currentPage, _page!.totalPages, (p) => _load(page: p), _accent),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(AdminPitchItem pitch, bool isLast) {
    final typeColor = pitch.type.contains('5') ? _accent : pitch.type.contains('7') ? _kViolet : _kTeal;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.sports_soccer_outlined, color: typeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pitch.name,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(pitch.providerName,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _pill(pitch.type, typeColor),
                  const SizedBox(height: 4),
                  Text(_fmtPrice(pitch.price),
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
    );
  }
}

class _DonutP extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutP({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.butt;
    double startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] / total;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect.deflate(7), startAngle + 0.03, sweep - 0.06, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
