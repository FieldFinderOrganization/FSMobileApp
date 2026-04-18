import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import '../../data/models/admin_user_list_model.dart';
import '../../data/models/admin_user_stats_model.dart';

class AdminUsersScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;

  const AdminUsersScreen({super.key, required this.datasource});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  // Palette
  static const _kPrimary   = Color(0xFF4454A0);
  static const _kPrimaryEnd= Color(0xFF9E91D1);
  static const _kTeal      = Color(0xFF0D9988);
  static const _kRed       = Color(0xFFEF4444);
  static const _kOrange    = Color(0xFFF59E0B);
  static const _kProviderColor = Color(0xFF059669);
  DateTime _lastUpdated = DateTime.now();

  // Avatar palette (Gmail-style)
  static const _kAvatarPalette = [
    Color(0xFF5C6BC0), Color(0xFF26A69A), Color(0xFF8D6E63),
    Color(0xFF42A5F5), Color(0xFF66BB6A), Color(0xFFEC407A),
    Color(0xFFAB47BC), Color(0xFFFF7043),
  ];

  AdminUserStatsModel? _stats;
  AdminUserListModel?  _page;
  bool   _loading     = true;
  String? _error;
  int    _currentPage = 0;
  bool   _showSearch  = false;
  String _searchQuery = '';
  final _searchCtrl   = TextEditingController();
  bool   _isExporting = false;
  String? _filterStatus; // null = tất cả, 'ACTIVE', 'BLOCKED'
  String? _filterRole;   // null = tất cả, 'ADMIN', 'PROVIDER', 'USER'

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      setState(() { _loading = true; _error = null; });
      final results = await Future.wait([
        widget.datasource.getUserStats(),
        widget.datasource.getUsers(page: _currentPage, search: _searchQuery, status: _filterStatus, role: _filterRole),
      ]);
      
      if (!mounted) return;
      setState(() {
        _stats = results[0] as AdminUserStatsModel;
        _page  = results[1] as AdminUserListModel;
        _loading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadPage(int page) async {
    setState(() { _currentPage = page; _loading = true; });
    try {
      final result = await widget.datasource.getUsers(page: page, search: _searchQuery, status: _filterStatus, role: _filterRole);
      setState(() { _page = result; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  String _getTimeAgo() {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 60) {
      return 'Dữ liệu cập nhật ${diff.inSeconds} giây trước';
    } else if (diff.inMinutes < 60) {
      return 'Dữ liệu cập nhật ${diff.inMinutes}p trước';
    } else {
      return 'Dữ liệu cập nhật ${diff.inHours}h trước';
    }
  }

  Future<void> _showFilterSheet() async {
    String? tempStatus = _filterStatus;
    String? tempRole   = _filterRole;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          Widget chipGroup(String label, List<Map<String, String?>> items, String? selected, void Function(String?) onSelect) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A1D2E))),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: items.map((item) {
                    final val = item['value'];
                    final isSelected = selected == val;
                    return ChoiceChip(
                      label: Text(item['label']!, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
                          color: isSelected ? Colors.white : const Color(0xFF1A1D2E))),
                      selected: isSelected,
                      selectedColor: _kPrimary,
                      checkmarkColor: Colors.white,
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide.none,
                      onSelected: (_) => setLocal(() => onSelect(val)),
                    );
                  }).toList(),
                ),
              ],
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('Lọc người dùng', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D2E))),
                const SizedBox(height: 20),
                chipGroup('Trạng thái', [
                  {'label': 'Tất cả', 'value': null},
                  {'label': 'Hoạt động', 'value': 'ACTIVE'},
                  {'label': 'Bị khóa',   'value': 'BLOCKED'},
                ], tempStatus, (v) => tempStatus = v),
                const SizedBox(height: 20),
                chipGroup('Vai trò', [
                  {'label': 'Tất cả',        'value': null},
                  {'label': 'Admin',          'value': 'ADMIN'},
                  {'label': 'Nhà cung cấp',  'value': 'PROVIDER'},
                  {'label': 'Người dùng',    'value': 'USER'},
                ], tempRole, (v) => tempRole = v),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setLocal(() { tempStatus = null; tempRole = null; });
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text('Đặt lại', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _filterStatus = tempStatus;
                            _filterRole   = tempRole;
                            _currentPage  = 0;
                          });
                          Navigator.pop(ctx);
                          _load();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: Text('Áp dụng', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf() async {
    if (_isExporting) return;

    final total = _page?.totalElements ?? 0;
    if (total == 0) return;

    // Dialog chọn số lượng
    final options = <Map<String, dynamic>>[
      if (total > 50) {'label': '50 bản ghi đầu', 'size': 50},
      if (total > 100) {'label': '100 bản ghi đầu', 'size': 100},
      {'label': 'Tất cả ($total bản ghi)', 'size': total},
    ];

    int? chosenSize;
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
    if (chosenSize == null) return;

    setState(() => _isExporting = true);
    try {
      final exportData = await widget.datasource.getUsers(
        page: 0, size: chosenSize!, search: _searchQuery,
        status: _filterStatus, role: _filterRole,
      );
      final font     = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final dateFmt  = DateFormat('dd/MM/yyyy');
      final now      = DateTime.now();
      final items    = exportData.content;
      final stats    = _stats;

      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        build: (ctx) => [
          pw.Header(level: 0, child: pw.Text('Báo cáo Người dùng',
              style: pw.TextStyle(font: boldFont, fontSize: 22))),
          pw.Text('Xuất ngày: ${dateFmt.format(now)}', style: pw.TextStyle(font: font)),
          pw.SizedBox(height: 16),
          if (stats != null) ...[
            pw.Header(level: 1, text: 'Tổng quan'),
            pw.Bullet(text: 'Tổng người dùng: ${stats.total}', style: pw.TextStyle(font: font)),
            ...stats.byStatus.map((s) => pw.Bullet(
                text: '${s.status}: ${s.count}', style: pw.TextStyle(font: font))),
            pw.SizedBox(height: 16),
          ],
          if (items.isNotEmpty) ...[
            pw.Header(level: 1, text: 'Danh sách người dùng'),
            pw.Table.fromTextArray(
              headers: ['Tên', 'Email', 'Điện thoại', 'Vai trò', 'Trạng thái'],
              data: items.map((u) => [
                u.name, u.email, u.phone, u.role, u.status,
              ]).toList(),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
              cellStyle: pw.TextStyle(font: font, fontSize: 8),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            ),
          ],
        ],
      ));

      final bytes    = await pdf.save();
      final fileName = 'admin_nguoi_dung_${DateFormat('yyyyMMdd').format(now)}.pdf';
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

  void _onSearch(String q) {
    _searchQuery = q;
    _currentPage = 0;
    _load();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final stats  = _stats;
    final total  = stats?.total ?? 0;
    final active = stats?.byStatus.where((s) => s.status == 'ACTIVE').fold(0, (a, b) => a + b.count) ?? 0;
    final blocked = total - active;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _statCard('Tổng cộng', '$total',  null,    Icons.people_alt_outlined),
                  const SizedBox(width: 10),
                  _statCard('Hoạt động', '$active',  _kTeal, Icons.circle),
                  const SizedBox(width: 10),
                  _statCard('Bị khóa',   '$blocked', _kRed,  Icons.circle),
                ],
              ),
            ),
          ),

          // ── Search bar (optional) ───────────────────────────────────────
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
                      hintText: 'Tìm theo tên hoặc email…',
                      hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF4454A0)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                _onSearch('');
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

          // ── Main content ────────────────────────────────────────────────
          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF4454A0))))
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Text(_error!)))
          else ...[
            if (stats != null) SliverToBoxAdapter(child: _buildDonutCard(stats, total)),
            SliverToBoxAdapter(child: _buildTableSection()),
          ],
        ],
      ),
    );
  }

  // ─── SLIVER APP BAR ───────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 85,
      pinned: true,
      backgroundColor: _kPrimary,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Người dùng',
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
            if (!_showSearch) { _searchCtrl.clear(); _onSearch(''); }
          }),
        ),
        IconButton(
          tooltip: 'Lọc',
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
              if (_filterStatus != null || _filterRole != null)
                Positioned(
                  top: -2, right: -2,
                  child: Container(
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: _kRed, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
          onPressed: _showFilterSheet,
        ),
        _isExporting
            ? const Padding(padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
            : IconButton(
                tooltip: 'Xuất PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 22),
                onPressed: _exportPdf),
        IconButton(
          tooltip: 'Thêm người dùng',
          icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 22),
          onPressed: () {},
        ),
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
                    // Dùng StreamBuilder để CHỈ render lại dòng chữ này mỗi 1 giây
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
                        onTap: _loading ? null : _load,
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

  // ─── STAT CARDS (overlap) ─────────────────────────────────────────────────

  Widget _statCard(String label, String value, Color? dotColor, IconData dotIcon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (dotColor != null) ...[
                  Icon(dotIcon, size: 8, color: dotColor),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(label,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF1A1D2E), height: 1)),
          ],
        ),
      ),
    );
  }

  // ─── DONUT + STATUS BARS ─────────────────────────────────────────────────

  Widget _buildDonutCard(AdminUserStatsModel stats, int total) {
    final roleColors = [_kPrimary, _kOrange, _kProviderColor, _kPrimaryEnd];
    final roles = stats.byRole;
    final active  = stats.byStatus.where((s) => s.status == 'ACTIVE').fold(0, (a, b) => a + b.count);
    final blocked = total - active;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phân bổ vai trò',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1D2E))),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _DonutPainter(
                      values: roles.map((r) => r.count.toDouble()).toList(),
                      colors: roleColors,
                    ),
                    child: Center(
                      child: Text('$total',
                          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFF1A1D2E))),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: List.generate(roles.length, (i) {
                      final r     = roles[i];
                      final color = roleColors[i % roleColors.length];
                      final pct   = total > 0 ? (r.count / total * 100).toStringAsFixed(1) : '0';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(width: 8, height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_roleLabel(r.role),
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600))),
                            Text('${r.count} ($pct%)',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1D2E))),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Text('Trạng thái tài khoản',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
            const SizedBox(height: 10),
            _statusBar('Hoạt động', active, total, _kTeal),
            const SizedBox(height: 8),
            _statusBar('Bị khóa',   blocked, total, _kRed),
          ],
        ),
      ),
    );
  }

  Widget _statusBar(String label, int count, int total, Color color) {
    final frac = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        Row(
          children: [
            Icon(Icons.circle, size: 7, color: color),
            const SizedBox(width: 6),
            SizedBox(
              width: 62,
              child: Text(label,
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
            ),
          ],
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: frac,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 32,
          child: Text('$count',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1D2E))),
        ),
      ],
    );
  }

  // ─── TABLE ────────────────────────────────────────────────────────────────

  Widget _buildTableSection() {
    final users = _page?.content ?? [];
    final bottomPad = MediaQuery.of(context).padding.bottom + 24;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Danh sách người dùng',
                  style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1D2E))),
              if (_page != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${_page!.totalElements} người',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _kPrimary)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                ...users.asMap().entries.map((e) => _buildUserRow(e.value, e.key == users.length - 1)),
                if (users.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.search_off_rounded, size: 36, color: Colors.grey.shade300),
                        const SizedBox(height: 8),
                        Text('Không tìm thấy người dùng',
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (_page != null && _page!.totalPages > 1) ...[
            const SizedBox(height: 16),
            buildAdminPaginationBar(_currentPage, _page!.totalPages, _loadPage, _kPrimary),
          ],
        ],
      ),
    );
  }

  Widget _buildUserRow(AdminUserItem user, bool isLast) {
    final initials    = user.name.isNotEmpty ? user.name[0].toUpperCase() : '?';
    final avatarColor = _avatarColor(user.name);
    final isBlocked   = user.status != 'ACTIVE';
    final isAdmin     = user.role == 'ADMIN';
    final isProvider  = user.role == 'PROVIDER';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          child: Row(
            children: [
              // Avatar with status dot
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: avatarColor.withOpacity(0.18),
                    child: Text(initials,
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700, color: avatarColor, fontSize: 15)),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: isBlocked ? _kRed : _kTeal,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // Text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(user.name,
                              style: GoogleFonts.inter(
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1A1D2E)),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        // Only show badge for ADMIN or PROVIDER
                        if (isAdmin) ...[
                          const SizedBox(width: 6),
                          _roleBadge('Admin', _kRed),
                        ] else if (isProvider) ...[
                          const SizedBox(width: 6),
                          _roleBadge('NCC', _kProviderColor),
                        ],
                      ],
                    ),
                    const SizedBox(height: 1),
                    Text(user.email,
                        style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (user.createdAt != null)
                      Text('Tham gia ${_fmtDate(user.createdAt!)}',
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade400)),
                  ],
                ),
              ),
              // Last login
              if (user.lastLoginAt != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Login cuối',
                        style: GoogleFonts.inter(fontSize: 9, color: Colors.grey.shade400)),
                    Text(_fmtDate(user.lastLoginAt!),
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600)),
                  ],
                ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
      ],
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Color _avatarColor(String name) {
    if (name.isEmpty) return _kAvatarPalette[0];
    final idx = name.codeUnits.fold(0, (a, b) => a + b) % _kAvatarPalette.length;
    return _kAvatarPalette[idx];
  }

  String _fmtDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  String _roleLabel(String role) => switch (role) {
    'ADMIN'    => 'Admin',
    'PROVIDER' => 'Nhà cung cấp',
    _          => 'Người dùng',
  };

  Widget _roleBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ─── SHARED PAGINATION BAR ────────────────────────────────────────────────────

Widget buildAdminPaginationBar(
    int current, int total, void Function(int) onChanged, Color accent) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _PageBtn(label: '← Trước', enabled: current > 0, accent: accent,
          onTap: () => onChanged(current - 1)),
      const SizedBox(width: 16),
      Text('Trang ${current + 1} / $total',
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D2E))),
      const SizedBox(width: 16),
      _PageBtn(label: 'Tiếp →', enabled: current < total - 1, accent: accent,
          onTap: () => onChanged(current + 1)),
    ],
  );
}

class _PageBtn extends StatelessWidget {
  final String label;
  final bool enabled;
  final Color accent;
  final VoidCallback onTap;

  const _PageBtn(
      {required this.label, required this.enabled, required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? accent.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: enabled ? accent : Colors.grey.shade400)),
      ),
    );
  }
}

// ─── DONUT PAINTER ────────────────────────────────────────────────────────────

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  _DonutPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold(0.0, (a, b) => a + b);
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final rect   = Rect.fromCircle(center: center, radius: radius);
    final paint  = Paint()
      ..style      = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap  = StrokeCap.butt;

    double start = -math.pi / 2;
    for (int i = 0; i < values.length; i++) {
      final sweep = 2 * math.pi * values[i] / total;
      paint.color = colors[i % colors.length];
      canvas.drawArc(rect.deflate(6.5), start + 0.03, sweep - 0.06, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
