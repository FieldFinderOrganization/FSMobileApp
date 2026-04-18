import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import '../../data/models/admin_booking_list_model.dart';
import '../../data/models/booking_stats_model.dart';
import 'admin_users_screen.dart' show buildAdminPaginationBar;

class AdminBookingsScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;

  const AdminBookingsScreen({super.key, required this.datasource});

  @override
  State<AdminBookingsScreen> createState() => _AdminBookingsScreenState();
}

class _AdminBookingsScreenState extends State<AdminBookingsScreen> {
  // Bảng màu chuẩn Financial Dashboard
  static const _kPrimary = Color(0xFF3E54AC);
  static const _kPrimaryEnd = Color(0xFF9E91D1);
  static const _kBackground = Color(0xFFF4F6FB);
  static const _kTextMain = Color(0xFF1A1D2E);
  static const _kTextMuted = Color(0xFF8A8F9F);

  // Semantic Colors cho Trạng thái
  static const _kSuccess = Color(0xFF10B981); // Xanh lá - Thành công
  static const _kDanger = Color(0xFFEF4444);  // Đỏ - Đã hủy
  static const _kWarning = Color(0xFFF59E0B); // Cam - Chờ xử lý

  AdminBookingListModel? _page;
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  DateTime _lastUpdated = DateTime.now();

  // Biến Tìm kiếm & Lọc
  bool _showSearch = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  int _fetchId = 0;

  // Filter States
  String? _selectedStatus; // null = Tất cả, 'CONFIRMED', 'CANCELED', 'PENDING'
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  double? _filterMinPrice;
  double? _filterMaxPrice;

  BookingStatsModel? _bookingStats;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadBookingStats();
  }

  Future<void> _loadBookingStats() async {
    try {
      final stats = await widget.datasource.getBookingStats();
      if (!mounted) return;
      setState(() => _bookingStats = stats);
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 0}) async {
    final currentFetchId = ++_fetchId;
    setState(() { _loading = true; _error = null; _currentPage = page; });
    
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final result = await widget.datasource.getAdminBookings(
        page: page, size: 10, status: _selectedStatus,
        startDate: _filterStartDate != null ? fmt.format(_filterStartDate!) : null,
        endDate: _filterEndDate != null ? fmt.format(_filterEndDate!) : null,
        minPrice: _filterMinPrice,
        maxPrice: _filterMaxPrice,
      );
      
      if (!mounted || currentFetchId != _fetchId) return;
      setState(() { 
        _page = result; 
        _loading = false; 
        _lastUpdated = DateTime.now(); 
      });
    } catch (e) {
      if (!mounted || currentFetchId != _fetchId) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSearch(String q) {
    setState(() => _searchQuery = q);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _load(page: 0));
  }

  String _getTimeAgo() {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 60) return 'Cập nhật ${diff.inSeconds} giây trước';
    if (diff.inMinutes < 60) return 'Cập nhật ${diff.inMinutes}p trước';
    return 'Cập nhật ${diff.inHours}h trước';
  }

  Future<void> _exportPdf() async {
    if (_isExporting) return;

    final total = _page?.totalElements ?? 0;
    if (total == 0) return;

    final options = <Map<String, dynamic>>[
      if (total > 50) {'label': '50 bản ghi đầu', 'size': 50},
      if (total > 100) {'label': '100 bản ghi đầu', 'size': 100},
      {'label': 'Tất cả ($total bản ghi)', 'size': total},
    ];

    int? chosenSize;
    if (options.length == 1) {
      chosenSize = total;
    } else {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Chọn số lượng xuất', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) => ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(opt['label'] as String, style: GoogleFonts.inter(fontSize: 13)),
            leading: Radio<int>(
              value: opt['size'] as int,
              groupValue: chosenSize,
              activeColor: const Color(0xFF4454A0),
              onChanged: (v) { chosenSize = v; Navigator.pop(ctx); },
            ),
            onTap: () { chosenSize = opt['size'] as int; Navigator.pop(ctx); },
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Huỷ', style: GoogleFonts.inter(color: Colors.grey.shade600)),
          ),
        ],
      ),
    );
    } // end else
    if (chosenSize == null) return;

    setState(() => _isExporting = true);
    try {
      final fmt2 = DateFormat('yyyy-MM-dd');
      final exportData = await widget.datasource.getAdminBookings(
        page: 0, size: chosenSize!, status: _selectedStatus,
        startDate: _filterStartDate != null ? fmt2.format(_filterStartDate!) : null,
        endDate: _filterEndDate != null ? fmt2.format(_filterEndDate!) : null,
        minPrice: _filterMinPrice,
        maxPrice: _filterMaxPrice,
      );
      final font     = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final currFmt  = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
      final dateFmt  = DateFormat('dd/MM/yyyy');
      final now      = DateTime.now();
      final stats    = _bookingStats;
      final items    = exportData.content;

      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Báo cáo Đặt sân',
              style: pw.TextStyle(font: boldFont, fontSize: 22))),
          pw.Text('Xuất ngày: ${dateFmt.format(now)}', style: pw.TextStyle(font: font)),
          pw.Text('Số bản ghi xuất: ${items.length}', style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 16),
          if (stats != null) ...[
            pw.Header(level: 1, text: 'Tổng quan'),
            pw.Bullet(text: 'Tổng đơn: ${stats.total}', style: pw.TextStyle(font: font)),
            pw.Bullet(text: 'Thành công: ${stats.confirmed}', style: pw.TextStyle(font: font)),
            pw.Bullet(text: 'Chờ xử lý: ${stats.pending}', style: pw.TextStyle(font: font)),
            pw.Bullet(text: 'Đã hủy: ${stats.canceled}', style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 16),
          ],
          if (items.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Danh sách đặt sân'),
            pw.Table.fromTextArray(
              headers: ['Người đặt', 'Sân', 'Ngày', 'Giá', 'Trạng thái'],
              data: items.map((b) => [
                b.userName, b.pitchName, b.bookingDate,
                currFmt.format(b.totalPrice), b.status,
              ]).toList(),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
              cellStyle: pw.TextStyle(font: font, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
          ],
        ],
      ));

      final bytes    = await pdf.save();
      final fileName = 'admin_dat_san_${DateFormat('yyyyMMdd').format(now)}.pdf';
      final tempDir  = await getTemporaryDirectory();
      final file     = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          subject: fileName,
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất PDF: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _fmtPrice(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)} Tỷ';
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)} Tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}K';
    return '${v.toStringAsFixed(0)}đ';
  }

  bool get _hasActiveFilter =>
      _filterStartDate != null || _filterEndDate != null ||
      _filterMinPrice != null || _filterMaxPrice != null;

  void _showFilterSheet() {
    DateTime? tempStart = _filterStartDate;
    DateTime? tempEnd   = _filterEndDate;
    final minCtrl = TextEditingController(text: _filterMinPrice?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: _filterMaxPrice?.toStringAsFixed(0) ?? '');
    final dateFmt = DateFormat('dd/MM/yyyy');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final bottomPad = MediaQuery.of(ctx).padding.bottom;
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 24, 24, bottomPad + 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Bộ lọc nâng cao', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800, color: _kTextMain)),
                  const SizedBox(height: 20),
                  Text('Khoảng thời gian', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextMuted)),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () async {
                      final range = await showDateRangePicker(
                        context: ctx,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        initialDateRange: (tempStart != null && tempEnd != null)
                            ? DateTimeRange(start: tempStart!, end: tempEnd!)
                            : null,
                        builder: (ctx, child) => Theme(
                          data: ThemeData.light().copyWith(colorScheme: const ColorScheme.light(primary: _kPrimary)),
                          child: child!,
                        ),
                      );
                      if (range != null) {
                        setSheet(() { tempStart = range.start; tempEnd = range.end; });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: (tempStart != null) ? _kPrimary : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: (tempStart != null) ? _kPrimary : _kTextMuted),
                          const SizedBox(width: 10),
                          Text(
                            tempStart != null && tempEnd != null
                                ? '${dateFmt.format(tempStart!)} — ${dateFmt.format(tempEnd!)}'
                                : 'Chọn khoảng ngày',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: tempStart != null ? _kTextMain : _kTextMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          if (tempStart != null)
                            GestureDetector(
                              onTap: () => setSheet(() { tempStart = null; tempEnd = null; }),
                              child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Khoảng giá (₫)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextMuted)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Từ',
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('—', style: GoogleFonts.inter(color: _kTextMuted)),
                      ),
                      Expanded(
                        child: TextField(
                          controller: maxCtrl,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Đến',
                            hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setSheet(() { tempStart = null; tempEnd = null; });
                            minCtrl.clear(); maxCtrl.clear();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Đặt lại', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterStartDate = tempStart;
                              _filterEndDate   = tempEnd;
                              _filterMinPrice  = double.tryParse(minCtrl.text);
                              _filterMaxPrice  = double.tryParse(maxCtrl.text);
                              _currentPage = 0;
                            });
                            Navigator.pop(ctx);
                            _load(page: 0);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text('Áp dụng', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _kBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          
          if (_showSearch)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 3))],
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    onChanged: _onSearch,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Tìm người đặt hoặc tên sân...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 20, color: _kPrimary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () { _searchCtrl.clear(); _onSearch(''); },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _buildFilterChips(),
                const SizedBox(height: 16),
                _buildFinancialStatsCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _kPrimary)))
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Text(_error!, style: const TextStyle(color: _kDanger))))
          else
            SliverToBoxAdapter(
              child: _buildTransactionList(bottomPadding),
            ),
        ],
      ),
    );
  }

  // ─── HERO HEADER ────────────────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 85,
      pinned: true,
      backgroundColor: _kPrimary,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Quản lý Đặt sân',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      titleSpacing: 0,
      actions: [
        IconButton(
          tooltip: 'Tìm kiếm',
          icon: Icon(_showSearch ? Icons.search_off_rounded : Icons.search_rounded, color: Colors.white, size: 22),
          onPressed: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) { _searchCtrl.clear(); _onSearch(''); }
          }),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Lọc nâng cao',
              icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
              onPressed: _showFilterSheet,
            ),
            if (_hasActiveFilter)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
        _isExporting
            ? const Padding(padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            : IconButton(
                tooltip: 'Xuất PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 22),
                onPressed: _exportPdf),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_kPrimary, _kPrimaryEnd], 
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30, top: -20,
                child: Container(
                  width: 160, height: 160,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.06)),
                ),
              ),
              Positioned(
                left: 56, 
                bottom: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        return Text(_getTimeAgo(),
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.80), fontWeight: FontWeight.w400));
                      }
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _loading ? null : () => _load(page: _currentPage),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(Icons.sync_rounded, size: 16, color: Colors.white.withOpacity(_loading ? 0.4 : 0.9)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── FILTER CHIPS (Tách riêng trạng thái ra để bấm trực tiếp) ────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        physics: const BouncingScrollPhysics(),
        children: [
          // Nhóm trạng thái (Status)
          _buildStatusChip('Tất cả', null),
          const SizedBox(width: 8),
          _buildStatusChip('Thành công', 'CONFIRMED'),
          const SizedBox(width: 8),
          _buildStatusChip('Chờ xử lý', 'PENDING'),
          const SizedBox(width: 8),
          _buildStatusChip('Đã hủy', 'CANCELED'),
          
          // Dấu gạch chia cách
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(width: 1.5, color: Colors.grey.shade300),
          ),
          
          // Nhóm Option Hành động (Mở bottom sheet)
          _buildActionChip(label: 'Thời gian & Giá', icon: Icons.tune_rounded, onTap: _showFilterSheet),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, String? statusValue) {
    final isActive = _selectedStatus == statusValue;
    return GestureDetector(
      onTap: () {
        if (_selectedStatus != statusValue) {
          setState(() => _selectedStatus = statusValue);
          _load(page: 0);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isActive ? _kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _kPrimary : Colors.grey.shade300, width: 1),
          boxShadow: isActive ? [BoxShadow(color: _kPrimary.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))] : null,
        ),
        alignment: Alignment.center,
        child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.white : _kTextMain)),
      ),
    );
  }

  Widget _buildActionChip({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _kTextMuted),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _kTextMain)),
            const SizedBox(width: 2),
            Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: _kTextMuted),
          ],
        ),
      ),
    );
  }

  // ─── FINANCIAL PORTFOLIO CHART (TOÀN BỘ DỮ LIỆU) ──────────────────────────
  Widget _buildFinancialStatsCard() {
    if (_bookingStats == null) return const SizedBox();

    final int confirmed = _bookingStats!.confirmed;
    final int canceled  = _bookingStats!.canceled;
    final int pending   = _bookingStats!.pending;
    final int total     = _bookingStats!.total;
    if (total == 0) return const SizedBox();

    // Tỉ lệ và màu label thay đổi theo tab đang chọn
    final String rateLabel;
    final double rate;
    final Color rateColor;
    final List<Widget> barSegments;
    final List<Widget> legendItems;
    const _kRest = Color(0xFFE5E7EB); // xám nhạt cho phần "còn lại"

    switch (_selectedStatus) {
      case 'CONFIRMED':
        rateLabel = 'Tỉ lệ thành công';
        rate      = (confirmed / total) * 100;
        rateColor = _kSuccess;
        barSegments = [
          if (confirmed > 0) Expanded(flex: confirmed, child: Container(color: _kSuccess)),
          if (total - confirmed > 0) Expanded(flex: total - confirmed, child: Container(color: _kRest)),
        ];
        legendItems = [
          _buildLegendItem('Thành công', confirmed, _kSuccess),
          _buildLegendItem('Tổng đơn', total, _kRest),
        ];
      case 'PENDING':
        rateLabel = 'Tỉ lệ chờ xử lý';
        rate      = (pending / total) * 100;
        rateColor = _kWarning;
        barSegments = [
          if (pending > 0) Expanded(flex: pending, child: Container(color: _kWarning)),
          if (total - pending > 0) Expanded(flex: total - pending, child: Container(color: _kRest)),
        ];
        legendItems = [
          _buildLegendItem('Chờ xử lý', pending, _kWarning),
          _buildLegendItem('Tổng đơn', total, _kRest),
        ];
      case 'CANCELED':
        rateLabel = 'Tỉ lệ đã hủy';
        rate      = (canceled / total) * 100;
        rateColor = _kDanger;
        barSegments = [
          if (canceled > 0) Expanded(flex: canceled, child: Container(color: _kDanger)),
          if (total - canceled > 0) Expanded(flex: total - canceled, child: Container(color: _kRest)),
        ];
        legendItems = [
          _buildLegendItem('Đã hủy', canceled, _kDanger),
          _buildLegendItem('Tổng đơn', total, _kRest),
        ];
      default:
        rateLabel = 'Tỉ lệ hoàn thành';
        rate      = (confirmed / total) * 100;
        rateColor = _kSuccess;
        barSegments = [
          if (confirmed > 0) Expanded(flex: confirmed, child: Container(color: _kSuccess)),
          if (pending > 0)   Expanded(flex: pending,   child: Container(color: _kWarning)),
          if (canceled > 0)  Expanded(flex: canceled,  child: Container(color: _kDanger)),
        ];
        legendItems = [
          _buildLegendItem('Thành công', confirmed, _kSuccess),
          _buildLegendItem('Chờ xử lý', pending, _kWarning),
          _buildLegendItem('Đã hủy', canceled, _kDanger),
        ];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _kTextMain.withOpacity(0.03), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(rateLabel, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: _kTextMuted)),
                Text('${rate.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w900, color: rateColor)),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 12,
                child: Row(children: barSegments),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: legendItems,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$count $label', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _kTextMain)),
      ],
    );
  }

  // ─── TRANSACTION LIST (Danh sách Giao dịch Đặt sân) ──────────────────────
  Widget _buildTransactionList(double bottomPadding) {
    var items = _page?.content ?? [];
    int displayTotal = _page?.totalElements ?? 0;
    
    // Lọc local nếu API không filter (dự phòng)
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final filteredLocally = items.where((p) => 
        p.userName.toLowerCase().contains(q) || 
        p.pitchName.toLowerCase().contains(q)
      ).toList();
      
      if (filteredLocally.length != items.length) {
        items = filteredLocally;
        displayTotal = items.length;
      }
    }
    
    return Padding(
      // Ép padding đáy để không dính thanh Navigation
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: _kTextMain.withOpacity(0.03), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Lịch sử Giao dịch',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextMain)),
                  if (_page != null)
                    Text('$displayTotal đơn',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _kTextMuted)),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F5)),
            
            ...items.asMap().entries.map((e) => _buildTransactionRow(e.value, e.key == items.length - 1)),
            
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('Không tìm thấy đơn đặt sân', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),

            // Pagination Area
            if (_page != null && _page!.totalPages > 1 && displayTotal > 10) ...[
              const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F5)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: buildAdminPaginationBar(_currentPage, _page!.totalPages, (p) => _load(page: p), _kPrimary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRow(AdminBookingItem item, bool isLast) {
    Color statusColor = _kWarning;
    String statusLabel = 'Chờ xử lý';
    if (item.status == 'CONFIRMED') { statusColor = _kSuccess; statusLabel = 'Thành công'; }
    else if (item.status == 'CANCELED') { statusColor = _kDanger; statusLabel = 'Đã hủy'; }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Avatar chữ cái đầu
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _kBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200, width: 1),
                ),
                alignment: Alignment.center,
                child: Text(item.userName.isNotEmpty ? item.userName[0].toUpperCase() : '?',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: _kPrimary)),
              ),
              const SizedBox(width: 14),
              
              // Thông tin giao dịch
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.userName,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextMain),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('${item.pitchName} • ${item.bookingDate}',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _kTextMuted),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              
              // Số tiền & Trạng thái
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtPrice(item.totalPrice),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextMain, letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(statusLabel, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 80, endIndent: 24, color: Color(0xFFF0F0F5)),
      ],
    );
  }
}