import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  // Bảng màu chuẩn Financial Dashboard
  static const _kPrimary = Color(0xFF3E54AC);
  static const _kPrimaryEnd = Color(0xFF9E91D1);
  static const _kSecondary = Color(0xFF7C6FCD);
  static const _kTeal = Color(0xFF0D9988);
  static const _kBackground = Color(0xFFF4F6FB); 
  static const _kTextMain = Color(0xFF1A1D2E);
  static const _kTextMuted = Color(0xFF8A8F9F);

  static const _typeColors = [_kPrimary, _kSecondary, _kTeal];

  AdminPitchListModel? _page;
  bool _loading = true;
  String? _error;
  int _currentPage = 0;
  
  // Biến lưu thời gian cập nhật
  DateTime _lastUpdated = DateTime.now();

  // Biến phục vụ chức năng Tìm kiếm
  bool _showSearch = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  
  // Biến chống lỗi đua mạng (Race Condition) và hạn chế spam API
  Timer? _debounce;
  int _fetchId = 0;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 0}) async {
    final currentFetchId = ++_fetchId; // Đánh dấu ID cho request này
    setState(() { _loading = true; _error = null; _currentPage = page; });
    
    try {
      final result = await widget.datasource.getAdminPitches(page: page, search: _searchQuery);
      
      // Nếu ID không khớp (nghĩa là đã có 1 request mới hơn được gửi đi), ta bỏ qua kết quả cũ này
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
    setState(() {
      _searchQuery = q;
    });
    
    // Xóa timer cũ nếu người dùng vẫn đang gõ liên tục
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Thiết lập độ trễ 500ms. Chỉ gọi API khi người dùng đã ngừng gõ nửa giây
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _load(page: 0);
    });
  }

  Future<void> _exportPdf() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);
    try {
      final font     = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final currFmt  = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
      final dateFmt  = DateFormat('dd/MM/yyyy');
      final now      = DateTime.now();
      final items    = _page?.content ?? [];
      final total    = _page?.totalElements ?? 0;

      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Báo cáo Sân hoạt động',
              style: pw.TextStyle(font: boldFont, fontSize: 22))),
          pw.Text('Xuất ngày: ${dateFmt.format(now)}', style: pw.TextStyle(font: font)),
          pw.Text('Tổng số sân: $total', style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 16),
          if (items.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Danh sách sân'),
            pw.Table.fromTextArray(
              headers: ['Tên sân', 'Loại', 'Nhà cung cấp', 'Giá', 'Môi trường'],
              data: items.map((p) => [
                p.name, p.type, p.providerName,
                currFmt.format(p.price), p.environment,
              ]).toList(),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
              cellStyle: pw.TextStyle(font: font, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
          ],
        ],
      ));

      final bytes    = await pdf.save();
      final fileName = 'admin_san_${DateFormat('yyyyMMdd').format(now)}.pdf';
      final dir      = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file     = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã lưu: $fileName'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(label: 'Mở file', textColor: Colors.white,
              onPressed: () => OpenFile.open(file.path)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xuất PDF: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _getTimeAgo() {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 60) {
      return 'Cập nhật ${diff.inSeconds} giây trước';
    } else if (diff.inMinutes < 60) {
      return 'Cập nhật ${diff.inMinutes}p trước';
    } else {
      return 'Cập nhật ${diff.inHours}h trước';
    }
  }

  String _fmtPrice(double v) {
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr/h';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k/h';
    return '${v.toStringAsFixed(0)}/h';
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
          
          // Thanh Tìm kiếm (Ẩn/Hiện)
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
                      hintText: 'Tìm theo tên sân hoặc nhà cung cấp...',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 20, color: _kPrimary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearch(''); // Sẽ tự clear và tự động load lại
                              },
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
              children: [
                const SizedBox(height: 20),
                _buildDonutCard(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _kPrimary)))
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))))
          else
            SliverToBoxAdapter(
              child: _buildTableCard(bottomPadding),
            ),
        ],
      ),
    );
  }

  // ─── HEADER ĐÃ CHỈNH SỬA GIỐNG TRANG USER ───────────────────────────────

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
      title: Text('Sân hoạt động',
          style: GoogleFonts.inter(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      titleSpacing: 0,
      actions: [
        IconButton(
          tooltip: 'Tìm kiếm',
          icon: Icon(
            _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
            color: Colors.white, size: 22,
          ),
          onPressed: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) { 
              _searchCtrl.clear(); 
              _onSearch(''); 
            }
          }),
        ),
        IconButton(
          tooltip: 'Lọc',
          icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          onPressed: () {}, 
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
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
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
                        return Text(
                          _getTimeAgo(),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.80),
                            fontWeight: FontWeight.w400,
                          ),
                        );
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
                          child: Icon(
                            Icons.sync_rounded, 
                            size: 16, 
                            color: Colors.white.withOpacity(_loading ? 0.4 : 0.9)
                          ),
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

  // ─── SUMMARY CARD (Báo cáo tổng quan) ─────────────────────────────────────

  Widget _buildDonutCard() {
    final pts = widget.pitchTypeData;
    if (pts.isEmpty) return const SizedBox();
    final total = pts.fold(0.0, (a, b) => a + b.count);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: _kTextMain.withOpacity(0.03), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Cơ cấu danh mục',
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextMain)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Tất cả',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kTextMuted)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CustomPaint(
                    painter: _DonutP(
                      values: pts.map((p) => p.count.toDouble()).toList(),
                      colors: _typeColors,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${total.toInt()}',
                              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: _kTextMain, height: 1)),
                          const SizedBox(height: 2),
                          Text('Tổng sân',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: _kTextMuted)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: Column(
                    children: pts.asMap().entries.map((e) {
                      final color = _typeColors[e.key % _typeColors.length];
                      final pct = total > 0 ? (e.value.count / total * 100).toStringAsFixed(1) : '0';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(e.value.type,
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700))),
                            Text('${e.value.count}',
                                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextMain)),
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

  // ─── DATA TABLE (Danh sách chi tiết) ──────────────────────────────────────

  Widget _buildTableCard(double bottomPadding) {
    var items = _page?.content ?? [];
    int displayTotal = _page?.totalElements ?? 0;
    
    // BACKUP: Lọc cục bộ tại App trong trường hợp API ở Backend chưa được thiết lập xử lý tham số `search`
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      final filteredLocally = items.where((p) => 
        p.name.toLowerCase().contains(q) || 
        p.providerName.toLowerCase().contains(q) ||
        p.type.toLowerCase().contains(q)
      ).toList();
      
      // Nếu lọc cục bộ trả về kết quả khác list gốc -> Backend chưa chịu lọc -> Ép dùng kết quả lọc cục bộ
      if (filteredLocally.length != items.length) {
        items = filteredLocally;
        displayTotal = items.length; // Hiển thị số đếm cho chuẩn
      }
    }
    
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottomPadding + 32),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: _kTextMain.withOpacity(0.03), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Chi tiết Sân',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: _kTextMain)),
                  if (_page != null)
                    Text('$displayTotal kết quả',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _kTextMuted)),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F5)),
            ...items.asMap().entries.map((e) => _buildRow(e.value, e.key == items.length - 1)),
            
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade300),
                      const SizedBox(height: 8),
                      Text('Không tìm thấy sân phù hợp', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              ),

            // Pagination Area (Ẩn đi nếu kết quả tìm kiếm quá ít không chia nổi trang)
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

  Widget _buildRow(AdminPitchItem pitch, bool isLast) {
    final typeColor = pitch.type.contains('5') 
        ? _kPrimary 
        : pitch.type.contains('7') ? _kSecondary : _kTeal;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: typeColor.withOpacity(0.1), width: 1),
                ),
                child: Icon(Icons.sports_soccer_rounded, color: typeColor, size: 22),
              ),
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pitch.name,
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextMain),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.storefront_rounded, size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(pitch.providerName,
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: _kTextMuted),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _pill(pitch.type, typeColor),
                  const SizedBox(height: 6),
                  Text(_fmtPrice(pitch.price),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: _kTextMain, letterSpacing: -0.5)),
                ],
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, indent: 84, endIndent: 24, color: Color(0xFFF0F0F5)),
      ],
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ─── DONUT CHART PAINTER ──────────────────────────────────────────────────

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
    
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..color = Colors.grey.shade100;
    canvas.drawCircle(center, radius - 6, bgPaint);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round; 
      
    double startAngle = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] / total;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect.deflate(7), startAngle + 0.05, sweep - 0.1, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}