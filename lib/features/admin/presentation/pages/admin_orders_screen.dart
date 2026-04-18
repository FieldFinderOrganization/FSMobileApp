import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
  static const _kPrimary    = Color(0xFF3E54AC);
  static const _kPrimaryEnd = Color(0xFF9E91D1);
  static const _kBackground = Color(0xFFF4F6FB);
  static const _kTextMain   = Color(0xFF1A1D2E);
  static const _kTextMuted  = Color(0xFF8A8F9F);
  static const _kTeal       = Color(0xFF0D9988);
  static const _kCoral      = Color(0xFFE05FA3);
  static const _kWarning    = Color(0xFFF59E0B);

  static const _filters      = ['Tất cả', 'PENDING', 'PAID', 'CONFIRMED', 'DELIVERED', 'CANCELED'];
  static const _filterLabels = ['Tất cả', 'Chờ xử lý', 'Đã TT', 'Xác nhận', 'Đã giao', 'Đã hủy'];

  int _filterIdx = 0;
  int _currentPage = 0;
  AdminOrderListModel? _page;
  List<Map<String, dynamic>> _stats = [];
  bool _loading = true;
  String? _error;
  DateTime _lastUpdated = DateTime.now();

  bool _showSearch = false;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  bool _isExporting = false;

  // Advanced filter state
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;
  double? _filterMinAmount;
  double? _filterMaxAmount;
  String _filterSort = 'default'; // 'default' | 'customer_most_orders'

  bool get _hasAdvancedFilter =>
      _filterStartDate != null || _filterEndDate != null ||
      _filterMinAmount != null || _filterMaxAmount != null ||
      _filterSort != 'default';

  String _getTimeAgo() {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 60) return 'Cập nhật ${diff.inSeconds} giây trước';
    if (diff.inMinutes < 60) return 'Cập nhật ${diff.inMinutes}p trước';
    return 'Cập nhật ${diff.inHours}h trước';
  }

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

  String? get _activeStatus => _filterIdx == 0 ? null : _filters[_filterIdx];

  Future<void> _load({int page = 0}) async {
    setState(() { _loading = true; _error = null; _currentPage = page; });
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      if (_stats.isEmpty) {
        final results = await Future.wait([
          widget.datasource.getAdminOrders(
            page: page, status: _activeStatus, search: _searchQuery,
            startDate: _filterStartDate != null ? fmt.format(_filterStartDate!) : null,
            endDate: _filterEndDate != null ? fmt.format(_filterEndDate!) : null,
            minAmount: _filterMinAmount, maxAmount: _filterMaxAmount, sort: _filterSort,
          ),
          widget.datasource.getOrderStats(),
        ]);
        setState(() {
          _page = results[0] as AdminOrderListModel;
          _stats = results[1] as List<Map<String, dynamic>>;
          _loading = false;
          _lastUpdated = DateTime.now();
        });
      } else {
        final result = await widget.datasource.getAdminOrders(
          page: page, status: _activeStatus, search: _searchQuery,
          startDate: _filterStartDate != null ? fmt.format(_filterStartDate!) : null,
          endDate: _filterEndDate != null ? fmt.format(_filterEndDate!) : null,
          minAmount: _filterMinAmount, maxAmount: _filterMaxAmount, sort: _filterSort,
        );
        setState(() { _page = result; _loading = false; _lastUpdated = DateTime.now(); });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onSearch(String q) {
    setState(() => _searchQuery = q);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _load(page: 0));
  }

  Color _statusColor(String s) => switch (s) {
    'PAID' || 'DELIVERED' => _kTeal,
    'CONFIRMED' => _kPrimary,
    'PENDING' => _kWarning,
    _ => _kCoral,
  };

  String _statusLabel(String s) => switch (s) {
    'PAID' => 'Đã TT',
    'DELIVERED' => 'Đã giao',
    'CONFIRMED' => 'Xác nhận',
    'PENDING' => 'Chờ xử lý',
    _ => 'Đã hủy',
  };

  void _showFilterSheet() {
    DateTime? tempStart = _filterStartDate;
    DateTime? tempEnd   = _filterEndDate;
    String tempSort     = _filterSort;
    final minCtrl = TextEditingController(text: _filterMinAmount?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: _filterMaxAmount?.toStringAsFixed(0) ?? '');
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
              child: SingleChildScrollView(
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
                        if (range != null) setSheet(() { tempStart = range.start; tempEnd = range.end; });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: tempStart != null ? _kPrimary : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 16, color: tempStart != null ? _kPrimary : _kTextMuted),
                            const SizedBox(width: 10),
                            Text(
                              tempStart != null && tempEnd != null
                                  ? '${dateFmt.format(tempStart!)} — ${dateFmt.format(tempEnd!)}'
                                  : 'Chọn khoảng ngày',
                              style: GoogleFonts.inter(fontSize: 13, color: tempStart != null ? _kTextMain : _kTextMuted, fontWeight: FontWeight.w500),
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
                    Text('Khoảng giá trị (₫)', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextMuted)),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
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
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text('Sắp xếp theo', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextMuted)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        {'label': 'Mặc định', 'value': 'default'},
                        {'label': 'Khách đặt nhiều nhất', 'value': 'customer_most_orders'},
                      ].map((opt) {
                        final val = opt['value'] as String;
                        final selected = tempSort == val;
                        return ChoiceChip(
                          label: Text(opt['label'] as String),
                          selected: selected,
                          checkmarkColor: Colors.white,
                          selectedColor: _kPrimary,
                          labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : _kTextMain),
                          onSelected: (_) => setSheet(() => tempSort = val),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheet(() { tempStart = null; tempEnd = null; tempSort = 'default'; });
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
                                _filterMinAmount = double.tryParse(minCtrl.text);
                                _filterMaxAmount = double.tryParse(maxCtrl.text);
                                _filterSort      = tempSort;
                                _currentPage     = 0;
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
            ),
          );
        });
      },
    );
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
                activeColor: _kPrimary,
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
    }
    if (chosenSize == null) return;

    setState(() => _isExporting = true);
    try {
      final fmt = DateFormat('yyyy-MM-dd');
      final exportData = await widget.datasource.getAdminOrders(
        page: 0, size: chosenSize!, status: _activeStatus, search: _searchQuery,
        startDate: _filterStartDate != null ? fmt.format(_filterStartDate!) : null,
        endDate: _filterEndDate != null ? fmt.format(_filterEndDate!) : null,
        minAmount: _filterMinAmount, maxAmount: _filterMaxAmount, sort: _filterSort,
      );
      final font     = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final currFmt  = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
      final dateFmt  = DateFormat('dd/MM/yyyy');
      final now      = DateTime.now();
      final items    = exportData.content;

      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Báo cáo Đơn hàng',
              style: pw.TextStyle(font: boldFont, fontSize: 22))),
          pw.Text('Xuất ngày: ${dateFmt.format(now)}', style: pw.TextStyle(font: font)),
          pw.Text('Số bản ghi xuất: ${items.length} / $total', style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 16),
          if (_stats.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Phân bổ trạng thái'),
            pw.Table.fromTextArray(
              headers: ['Trạng thái', 'Số lượng'],
              data: _stats.map((s) => [
                _statusLabel(s['status']?.toString() ?? ''),
                '${(s['count'] as num? ?? 0).toInt()}',
              ]).toList(),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
            pw.SizedBox(height: 16),
          ],
          if (items.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Danh sách đơn hàng'),
            pw.Table.fromTextArray(
              headers: ['Mã đơn', 'Khách hàng', 'Ngày tạo', 'Giá trị', 'Trạng thái'],
              data: items.map((o) => [
                '#${o.orderId}', o.userName, o.createdAt,
                currFmt.format(o.totalAmount), _statusLabel(o.status),
              ]).toList(),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
              cellStyle: pw.TextStyle(font: font, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
          ],
        ],
      ));

      final bytes    = await pdf.save();
      final fileName = 'admin_don_hang_${DateFormat('yyyyMMdd').format(now)}.pdf';
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
    if (v >= 1e6) return '${(v / 1e6).toStringAsFixed(1)}tr';
    if (v >= 1e3) return '${(v / 1e3).toStringAsFixed(0)}k';
    return v.toStringAsFixed(0);
  }

  static const _donutColors = [_kWarning, _kTeal, _kPrimary, _kTeal, _kCoral];

  @override
  Widget build(BuildContext context) {
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
                      hintText: 'Tìm theo tên khách hoặc mã đơn...',
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
          if (_stats.isNotEmpty) SliverToBoxAdapter(child: _buildDonut()),
          SliverToBoxAdapter(child: _buildFilterPills()),
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: _kPrimary)))
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
      expandedHeight: 85,
      pinned: true,
      backgroundColor: _kPrimary,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Đơn hàng',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      titleSpacing: 0,
      actions: [
        IconButton(
          tooltip: 'Tìm kiếm',
          icon: Icon(_showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              color: Colors.white, size: 22),
          onPressed: () => setState(() {
            _showSearch = !_showSearch;
            if (!_showSearch) { _searchCtrl.clear(); _onSearch(''); }
          }),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              tooltip: 'Lọc',
              icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
              onPressed: _showFilterSheet,
            ),
            if (_hasAdvancedFilter)
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
                left: 56, bottom: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, _) => Text(
                        _getTimeAgo(),
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.80), fontWeight: FontWeight.w400),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _loading ? null : _load,
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
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

  Widget _buildDonut() {
    final values = _stats.map((s) => ((s['count'] as num?) ?? 0).toDouble()).toList();
    final total  = values.fold(0.0, (a, b) => a + b);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phân bổ trạng thái', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _kTextMain)),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 110, height: 110,
                  child: CustomPaint(
                    painter: _DonutP(values: values, colors: _donutColors),
                    child: Center(
                      child: Text('${total.toInt()}',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: _kTextMain)),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: _stats.asMap().entries.map((e) {
                      final color = _donutColors[e.key % _donutColors.length];
                      final count = (e.value['count'] as num? ?? 0).toInt();
                      final pct   = total > 0 ? (count / total * 100).toStringAsFixed(1) : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 6),
                            Expanded(child: Text(_statusLabel(e.value['status']?.toString() ?? ''),
                                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600))),
                            Text('$count ($pct%)',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kTextMain)),
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
                    color: active ? _kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: active ? _kPrimary : Colors.grey.shade200),
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
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 40),
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
              boxShadow: [BoxShadow(color: _kPrimary.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
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
            buildAdminPaginationBar(_currentPage, _page!.totalPages, (p) => _load(page: p), _kPrimary),
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
                width: 38, height: 38,
                decoration: BoxDecoration(color: _kPrimary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Center(
                  child: Text('#${order.orderId}',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _kPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.userName,
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: _kTextMain),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(order.createdAt, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_fmtPrice(order.totalAmount),
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: _kTextMain)),
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
    final rect   = Rect.fromCircle(center: center, radius: radius);
    final paint  = Paint()..style = PaintingStyle.stroke..strokeWidth = 14..strokeCap = StrokeCap.butt;
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
