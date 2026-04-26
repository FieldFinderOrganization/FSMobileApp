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
import '../../data/models/admin_rating_stats_model.dart';

class AdminRatingScreen extends StatefulWidget {
  final AdminStatisticsDatasource datasource;

  const AdminRatingScreen({super.key, required this.datasource});

  @override
  State<AdminRatingScreen> createState() => _AdminRatingScreenState();
}

class _AdminRatingScreenState extends State<AdminRatingScreen> {
  static const _accent = Color(0xFF7C6FCD);
  static const _accentEnd = Color(0xFF9B8EE0);
  static const _gold = Color(0xFFF59E0B);

  AdminRatingStatsModel? _data;
  bool _loading = true;
  String? _error;
  DateTime _lastUpdated = DateTime.now();

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

  Future<void> _exportPdf() async {
    final data = _data;
    if (data == null) return;
    setState(() => _loading = true);
    try {
      final font = await PdfGoogleFonts.notoSansRegular();
      final boldFont = await PdfGoogleFonts.notoSansBold();
      final dateFmt = DateFormat('dd/MM/yyyy');
      final now = DateTime.now();

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          build: (ctx) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Báo cáo Đánh giá',
                style: pw.TextStyle(font: boldFont, fontSize: 22),
              ),
            ),
            pw.Text(
              'Xuất ngày: ${dateFmt.format(now)}',
              style: pw.TextStyle(font: font),
            ),
            pw.Text(
              'Số bản ghi: ${data.totalReviews} đánh giá',
              style: pw.TextStyle(font: font),
            ),
            pw.SizedBox(height: 16),
            pw.Header(level: 1, text: 'Tổng quan'),
            pw.Bullet(
              text: 'Tổng đánh giá: ${data.totalReviews}',
              style: pw.TextStyle(font: font),
            ),
            pw.Bullet(
              text:
                  'Điểm trung bình: ${data.averageRating.toStringAsFixed(1)} / 5.0',
              style: pw.TextStyle(font: font),
            ),
            pw.SizedBox(height: 8),
            pw.Header(level: 1, text: 'Phân bố sao'),
            pw.Table.fromTextArray(
              headers: ['Số sao', 'Số lượng', 'Tỉ lệ'],
              data: data.distribution
                  .map(
                    (d) => [
                      '${d.stars} ★',
                      '${d.count}',
                      '${d.percentage.toStringAsFixed(1)}%',
                    ],
                  )
                  .toList(),
              headerStyle: pw.TextStyle(font: boldFont, fontSize: 10),
              cellStyle: pw.TextStyle(font: font, fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
            ),
            if (data.recentReviews.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Header(level: 1, text: 'Đánh giá gần đây'),
              pw.Table.fromTextArray(
                headers: ['Người dùng', 'Sân', 'Sao', 'Nhận xét', 'Ngày'],
                data: data.recentReviews
                    .map(
                      (r) => [
                        r.userName,
                        r.pitchName,
                        '${r.rating} ★',
                        r.comment.length > 40
                            ? '${r.comment.substring(0, 40)}...'
                            : r.comment,
                        r.createdAt,
                      ],
                    )
                    .toList(),
                headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
                cellStyle: pw.TextStyle(font: font, fontSize: 8),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
            ],
          ],
        ),
      );

      final bytes = await pdf.save();
      final fileName =
          'admin_danh_gia_${DateFormat('yyyyMMdd').format(now)}.pdf';
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      if (mounted) {
        await Share.shareXFiles([
          XFile(file.path, mimeType: 'application/pdf'),
        ], subject: fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xuất PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.datasource.getRatingStats();
      setState(() {
        _data = result;
        _loading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Text(_error!)))
          else ...[
            SliverToBoxAdapter(child: _buildRatingChart()),
            SliverToBoxAdapter(child: _buildRecentReviews()),
          ],
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
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.white,
          size: 18,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Đánh giá',
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      titleSpacing: 0,
      actions: [
        IconButton(
          tooltip: 'Tìm kiếm',
          icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
          onPressed: () {},
        ),
        IconButton(
          tooltip: 'Lọc',
          icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          onPressed: () {},
        ),
        IconButton(
          tooltip: 'Xuất PDF',
          icon: const Icon(
            Icons.picture_as_pdf_outlined,
            color: Colors.white,
            size: 22,
          ),
          onPressed: _data != null ? _exportPdf : null,
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
                right: -30,
                top: -20,
                child: Container(
                  width: 160,
                  height: 160,
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
                      builder: (context, _) => Text(
                        _getTimeAgo(),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.80),
                          fontWeight: FontWeight.w400,
                        ),
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
                          child: Icon(
                            Icons.sync_rounded,
                            size: 16,
                            color: Colors.white.withOpacity(
                              _loading ? 0.4 : 0.9,
                            ),
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

  Widget _buildRatingChart() {
    final data = _data!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Big rating display
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      data.averageRating.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        height: 1,
                      ),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        return Icon(
                          i < data.averageRating.round()
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: _gold,
                          size: 16,
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.totalReviews} đánh giá',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: data.distribution.map((d) {
                      final frac = d.percentage / 100.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text(
                              '${d.stars}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.star_rounded, size: 12, color: _gold),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: frac,
                                  backgroundColor: Colors.grey.shade100,
                                  valueColor: AlwaysStoppedAnimation(_accent),
                                  minHeight: 7,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              width: 32,
                              child: Text(
                                '${d.count}',
                                textAlign: TextAlign.right,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
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

  Widget _buildRecentReviews() {
    final reviews = _data!.recentReviews;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Đánh giá gần đây',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _accent.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ...reviews.asMap().entries.map(
                  (e) => _buildReviewRow(e.value, e.key == reviews.length - 1),
                ),
                if (reviews.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Chưa có đánh giá',
                      style: GoogleFonts.inter(color: Colors.grey.shade400),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(RecentReview r, bool isLast) {
    final initials = r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?';
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _accent.withOpacity(0.12),
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: _accent,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r.userName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Row(
                          children: List.generate(
                            5,
                            (i) => Icon(
                              i < r.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 12,
                              color: _gold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.pitchName,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _accent.withOpacity(0.7),
                      ),
                    ),
                    if (r.comment.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        r.comment,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      r.createdAt,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 16,
            endIndent: 16,
            color: Colors.grey.shade100,
          ),
      ],
    );
  }
}
