import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import '../../data/models/admin_order_list_model.dart';
import 'admin_users_screen.dart' show buildAdminPaginationBar;

class AdminOrdersScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;

  const AdminOrdersScreen({super.key, required this.datasource});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  static const _accent = Color(0xFFF59E0B);
  static const _kTeal = Color(0xFF0D9988);
  static const _kCoral = Color(0xFFE05FA3);
  static const _kIndigo = Color(0xFF3E54AC);
  static const _kViolet = Color(0xFF7C6FCD);

  static const _filters = ['Tất cả', 'PENDING', 'PAID', 'CONFIRMED', 'DELIVERED', 'CANCELED'];
  static const _filterLabels = ['Tất cả', 'Chờ xử lý', 'Đã TT', 'Xác nhận', 'Đã giao', 'Đã hủy'];

  int _filterIdx = 0;
  int _currentPage = 0;
  AdminOrderListModel? _page;
  List<Map<String, dynamic>> _stats = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _activeStatus => _filterIdx == 0 ? null : _filters[_filterIdx];

  Future<void> _load({int page = 0}) async {
    setState(() { _loading = true; _error = null; _currentPage = page; });
    try {
      if (_stats.isEmpty) {
        final results = await Future.wait([
          widget.datasource.getAdminOrders(page: page, status: _activeStatus),
          widget.datasource.getOrderStats(),
        ]);
        setState(() {
          _page = results[0] as AdminOrderListModel;
          _stats = results[1] as List<Map<String, dynamic>>;
          _loading = false;
        });
      } else {
        final result = await widget.datasource.getAdminOrders(page: page, status: _activeStatus);
        setState(() { _page = result; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _statusColor(String s) => switch (s) {
    'PAID' || 'DELIVERED' => _kTeal,
    'CONFIRMED' => _kIndigo,
    'PENDING' => _accent,
    _ => _kCoral,
  };

  String _statusLabel(String s) => switch (s) {
    'PAID' => 'Đã TT',
    'DELIVERED' => 'Đã giao',
    'CONFIRMED' => 'Xác nhận',
    'PENDING' => 'Chờ xử lý',
    _ => 'Đã hủy',
  };

  String _fmtPrice(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  static const _donutColors = [_kTeal, _kIndigo, _accent, _kTeal, _kCoral];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_stats.isNotEmpty) SliverToBoxAdapter(child: _buildDonut()),
          SliverToBoxAdapter(child: _buildFilterPills()),
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
        title: Text('Đơn hàng',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFD97706), Color(0xFFFBBF24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDonut() {
    final values = _stats.map((s) => ((s['count'] as num?) ?? 0).toDouble()).toList();
    final total = values.fold(0.0, (a, b) => a + b);
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
            Text('Phân bổ trạng thái',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutP(values: values, colors: _donutColors),
                    child: Center(
                      child: Text('${total.toInt()}',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87)),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: _stats.asMap().entries.map((e) {
                      final color = _donutColors[e.key % _donutColors.length];
                      final count = (e.value['count'] as num? ?? 0).toInt();
                      final pct = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(_statusLabel(e.value['status']?.toString() ?? ''),
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600))),
                            Text('$count ($pct%)',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
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

  Widget _buildFilterPills() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filterLabels.length, (i) {
            final active = i == _filterIdx;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () { setState(() { _filterIdx = i; }); _load(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? _accent : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? _accent : Colors.grey.shade200),
                  ),
                  child: Text(_filterLabels[i],
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : Colors.grey.shade600)),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTable() {
    final items = _page?.content ?? [];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_page != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('${_page!.totalElements} đơn hàng',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
            ),
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

  Widget _buildRow(AdminOrderItem order, bool isLast) {
    final color = _statusColor(order.status);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text('#${order.orderId}',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _accent)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.userName,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(order.createdAt,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtPrice(order.totalAmount),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 4),
                  _pill(_statusLabel(order.status), color),
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
