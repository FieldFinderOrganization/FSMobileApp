import 'dart:io';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/admin_overview_model.dart';
import '../../data/models/revenue_point_model.dart';

class AdminRevenueScreen extends StatefulWidget {
  final AdminOverviewModel overview;
  final List<RevenuePointModel> revenueData;

  const AdminRevenueScreen({
    super.key,
    required this.overview,
    required this.revenueData,
  });

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  static const _accent    = Color(0xFF3E54AC);
  static const _accentEnd = Color(0xFF5C75D4);
  static const _kTeal   = Color(0xFF0D9988);
  static const _kViolet = Color(0xFF7C6FCD);

  late List<RevenuePointModel> _sorted;
  final DateTime _lastUpdated = DateTime.now();
  bool _isExporting = false;

  String _getTimeAgo() {
    final diff = DateTime.now().difference(_lastUpdated);
    if (diff.inSeconds < 60) return 'Cập nhật ${diff.inSeconds} giây trước';
    if (diff.inMinutes < 60) return 'Cập nhật ${diff.inMinutes}p trước';
    return 'Cập nhật ${diff.inHours}h trước';
  }

  @override
  void initState() {
    super.initState();
    _sorted = List.of(widget.revenueData)
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
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
      final ov       = widget.overview;

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (ctx) => [
            pw.Header(level: 0, child: pw.Text('Báo cáo Doanh thu Admin',
                style: pw.TextStyle(font: boldFont, fontSize: 22))),
            pw.Text('Xuất ngày: ${dateFmt.format(now)}', style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 16),
            pw.Header(level: 1, text: 'Tổng quan'),
            pw.Bullet(text: 'Tổng doanh thu: ${currFmt.format(ov.totalRevenue)}', style: pw.TextStyle(font: font)),
            pw.Bullet(text: 'Doanh thu đặt sân: ${currFmt.format(ov.bookingRevenue)}', style: pw.TextStyle(font: font)),
            pw.Bullet(text: 'Doanh thu sản phẩm: ${currFmt.format(ov.productRevenue)}', style: pw.TextStyle(font: font)),
            pw.SizedBox(height: 16),
            if (_sorted.isNotEmpty) ...[
              pw.Header(level: 1, text: 'Top ngày doanh thu cao nhất'),
              pw.Table.fromTextArray(
                headers: ['#', 'Ngày', 'Doanh thu'],
                data: _sorted.take(10).toList().asMap().entries.map((e) => [
                  '${e.key + 1}',
                  e.value.date,
                  currFmt.format(e.value.revenue),
                ]).toList(),
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
                cellStyle: pw.TextStyle(font: font, fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              ),
            ],
          ],
        ),
      );

      final bytes    = await pdf.save();
      final fileName = 'admin_doanh_thu_${DateFormat('yyyyMMdd').format(now)}.pdf';
      final dir      = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
      final file     = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã lưu: $fileName'),
          backgroundColor: Colors.green.shade700,
          duration: const Duration(seconds: 8),
          action: SnackBarAction(
            label: 'Mở file',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(file.path),
          ),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi xuất PDF: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _fmt(double v) {
    if (v >= 1e9) return '${(v / 1e9).toStringAsFixed(1)}tỷ';
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
          SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 85,
      pinned: true,
      backgroundColor: _accent,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Doanh thu',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
      titleSpacing: 0,
      actions: [
        _isExporting
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
              )
            : IconButton(
                tooltip: 'Xuất PDF',
                icon: const Icon(Icons.picture_as_pdf_outlined, color: Colors.white, size: 22),
                onPressed: () => _exportPdf(),
              ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_accent, _accentEnd],
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
                left: 56, bottom: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, _) => Text(
                        _getTimeAgo(),
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.80),
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() {}),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(Icons.sync_rounded, size: 16,
                              color: Colors.white.withOpacity(0.9)),
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

  Widget _buildContent() {
    final ov = widget.overview;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary chips
          Row(
            children: [
              _chip('Tổng', _fmt(ov.totalRevenue), _accent),
              const SizedBox(width: 10),
              _chip('Đặt sân', _fmt(ov.bookingRevenue), _kTeal),
              const SizedBox(width: 10),
              _chip('Sản phẩm', _fmt(ov.productRevenue), _kViolet),
            ],
          ),
          const SizedBox(height: 20),
          // Chart
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Xu hướng doanh thu',
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
                const SizedBox(height: 16),
                if (widget.revenueData.isEmpty)
                  SizedBox(height: 160, child: Center(child: Text('Chưa có dữ liệu', style: GoogleFonts.inter(color: Colors.grey.shade400))))
                else
                  SizedBox(height: 160, child: _buildChart()),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Breakdown
          Row(
            children: [
              Expanded(child: _breakdownCard('Đặt sân', ov.bookingRevenue, _kTeal, Icons.sports_soccer_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _breakdownCard('Sản phẩm', ov.productRevenue, _kViolet, Icons.shopping_bag_outlined)),
            ],
          ),
          const SizedBox(height: 24),
          // Top days table
          Text('Top 10 ngày doanh thu cao nhất',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: _accent.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: _sorted.take(10).toList().asMap().entries.map((e) {
                final isLast = e.key == (_sorted.length > 10 ? 9 : _sorted.length - 1);
                return _revenueRow(e.key + 1, e.value, isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final pts = widget.revenueData;
    final maxY = pts.map((p) => p.revenue).fold(0.0, (a, b) => a > b ? a : b);
    final spots = pts.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.revenue)).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              getTitlesWidget: (v, _) => Text(_fmt(v),
                  style: GoogleFonts.inter(fontSize: 9, color: Colors.grey.shade400)),
            ),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            preventCurveOverShooting: true,
            color: _accent,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [_accent.withOpacity(0.25), _accent.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _revenueRow(int rank, RevenuePointModel pt, bool isLast) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank <= 3 ? _accent.withOpacity(0.12) : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Text('$rank',
                    style: GoogleFonts.inter(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: rank <= 3 ? _accent : Colors.grey.shade500)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(pt.date,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.black87)),
              ),
              Text(_fmt(pt.revenue),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: _accent)),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 16, endIndent: 16, color: Colors.grey.shade100),
      ],
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.inter(fontSize: 10, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _breakdownCard(String label, double amount, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
                Text(_fmt(amount),
                    style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
