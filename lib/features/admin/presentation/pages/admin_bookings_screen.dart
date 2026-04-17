import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import '../../data/models/admin_booking_list_model.dart';
import 'admin_users_screen.dart' show buildAdminPaginationBar;

class AdminBookingsScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;

  const AdminBookingsScreen({super.key, required this.datasource});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  static const _accent = Color(0xFF0D9988);

  static const _filters = ['Tất cả', 'CONFIRMED', 'PENDING', 'CANCELED'];
  static const _filterLabels = ['Tất cả', 'Xác nhận', 'Chờ duyệt', 'Đã hủy'];

  int _filterIdx = 0;
  int _currentPage = 0;
  AdminBookingListModel? _page;
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
      final result = await widget.datasource.getAdminBookings(
          page: page, status: _activeStatus);
      setState(() { _page = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _statusColor(String s) {
    return switch (s) {
      'CONFIRMED' => const Color(0xFF0D9988),
      'CANCELED' => const Color(0xFFE05FA3),
      _ => const Color(0xFFF59E0B),
    };
  }

  String _statusLabel(String s) {
    return switch (s) {
      'CONFIRMED' => 'Xác nhận',
      'CANCELED' => 'Đã hủy',
      _ => 'Chờ duyệt',
    };
  }

  String _paymentLabel(String s) {
    return switch (s) {
      'PAID' => 'Đã TT',
      'REFUNDED' => 'Hoàn tiền',
      'CANCELED' => 'Đã hủy',
      _ => 'Chưa TT',
    };
  }

  Color _paymentColor(String s) {
    return switch (s) {
      'PAID' => const Color(0xFF0D9988),
      'REFUNDED' => const Color(0xFF7C6FCD),
      'CANCELED' => const Color(0xFFE05FA3),
      _ => const Color(0xFFF59E0B),
    };
  }

  String _fmtPrice(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
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
        title: Text('Đặt sân',
            style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0A7A6E), Color(0xFF3DBFB0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPills() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filterLabels.length, (i) {
            final active = i == _filterIdx;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() { _filterIdx = i; });
                  _load();
                },
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
              child: Text('${_page!.totalElements} lượt đặt',
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

  Widget _buildRow(AdminBookingItem b, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.userName,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(b.pitchName,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 10, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(b.bookingDate, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtPrice(b.totalPrice),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black87)),
                  const SizedBox(height: 4),
                  _pill(_statusLabel(b.status), _statusColor(b.status)),
                  const SizedBox(height: 3),
                  _pill(_paymentLabel(b.paymentStatus), _paymentColor(b.paymentStatus)),
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
