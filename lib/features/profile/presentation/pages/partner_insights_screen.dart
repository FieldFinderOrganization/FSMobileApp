import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../pitch/data/models/booking_response_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/ranked_progress_bar.dart';

enum InsightsTab { revenue, bookings, pitches, customers }

/// Gom dữ liệu theo kỳ cho biểu đồ xu hướng (ngày/tuần/tháng).
enum BookingPeriod { day, week, month }

// ─── Design tokens ────────────────────────────────────────────────────────────
const _kCardRadius = 20.0;
const _kChartHeight = 230.0;

const _kPalette = [
  Color(0xFF6366F1), // indigo
  Color(0xFF0EA5E9), // sky
  Color(0xFF10B981), // emerald
  Color(0xFFF59E0B), // amber
  Color(0xFFEC4899), // pink
  Color(0xFF8B5CF6), // violet
  Color(0xFF14B8A6), // teal
  Color(0xFFF97316), // orange
];

Color _statusColor(String s) {
  switch (s.toUpperCase()) {
    case 'CONFIRMED':
      return const Color(0xFF10B981);
    case 'CANCELED':
      return const Color(0xFFEF4444);
    default:
      return const Color(0xFFF59E0B);
  }
}

String _statusLabel(String s) {
  switch (s.toUpperCase()) {
    case 'CONFIRMED':
      return 'Hoàn thành';
    case 'CANCELED':
      return 'Đã hủy';
    default:
      return 'Chờ duyệt';
  }
}
// ──────────────────────────────────────────────────────────────────────────────

class PartnerInsightsScreen extends StatefulWidget {
  final List<BookingResponseModel> bookings;
  final InsightsTab initialTab;

  const PartnerInsightsScreen({
    super.key,
    required this.bookings,
    required this.initialTab,
  });

  @override
  State<PartnerInsightsScreen> createState() => _PartnerInsightsScreenState();
}

class _PartnerInsightsScreenState extends State<PartnerInsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<BookingResponseModel> _paidBookings;

  Map<String, double> _dailyRevenue = {};
  Map<String, int> _dailyBookings = {};
  Map<String, int> _statusDistribution = {};
  Map<String, int> _pitchBookings = {};
  Map<String, double> _pitchRevenue = {};
  List<int> _slotUsage = List.filled(24, 0);
  Map<String, Map<String, dynamic>> _customerMetrics = {};

  // Kỳ gom cho tab Doanh thu & Đặt sân (mặc định: ngày).
  BookingPeriod _period = BookingPeriod.day;

  final _currFmt = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _processData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _processData() {
    _paidBookings = widget.bookings
        .where(
          (b) =>
              b.status.toUpperCase() == 'CONFIRMED' &&
              b.paymentStatus.toUpperCase() == 'PAID',
        )
        .toList();

    _dailyRevenue = {};
    _dailyBookings = {};
    _statusDistribution = {};
    _pitchBookings = {};
    _pitchRevenue = {};
    _slotUsage = List.filled(24, 0);
    _customerMetrics = {};

    for (var b in widget.bookings) {
      final date = b.bookingDate;
      final status = b.status.toUpperCase();
      _dailyBookings[date] = (_dailyBookings[date] ?? 0) + 1;
      _statusDistribution[status] = (_statusDistribution[status] ?? 0) + 1;
      _pitchBookings[b.pitchName] = (_pitchBookings[b.pitchName] ?? 0) + 1;

      if (status != 'CANCELED') {
        for (var slot in b.slots) {
          final hour = slot + 4;
          if (hour >= 0 && hour < 24) _slotUsage[hour]++;
        }
      }

      final userId = b.userId;
      final current =
          _customerMetrics[userId] ??
          {'name': b.userName, 'bookings': 0, 'spend': 0.0};
      current['bookings'] = (current['bookings'] as int) + 1;
      if (status == 'CONFIRMED' && b.paymentStatus.toUpperCase() == 'PAID') {
        current['spend'] = (current['spend'] as double) + b.totalPrice;
        _dailyRevenue[date] = (_dailyRevenue[date] ?? 0) + b.totalPrice;
        _pitchRevenue[b.pitchName] =
            (_pitchRevenue[b.pitchName] ?? 0) + b.totalPrice;
      }
      _customerMetrics[userId] = current;
    }
  }

  // ─── Gom theo kỳ (ngày/tuần/tháng) ─────────────────────────────────────────
  /// Khoá kỳ chuẩn hoá về dạng yyyy-MM-dd (parse được) để sắp xếp & vẽ chart:
  /// ngày → chính ngày đó; tuần → thứ Hai đầu tuần; tháng → ngày 01 của tháng.
  String _bucketKey(DateTime d) {
    switch (_period) {
      case BookingPeriod.day:
        return DateFormat('yyyy-MM-dd').format(d);
      case BookingPeriod.week:
        final monday = d.subtract(Duration(days: d.weekday - 1));
        return DateFormat('yyyy-MM-dd')
            .format(DateTime(monday.year, monday.month, monday.day));
      case BookingPeriod.month:
        return DateFormat('yyyy-MM-01').format(d);
    }
  }

  /// Nhãn hiển thị cho 1 kỳ trong danh sách.
  String _bucketLabel(String key) {
    final d = DateTime.tryParse(key);
    if (d == null) return key;
    switch (_period) {
      case BookingPeriod.day:
        return DateFormat('dd/MM/yyyy').format(d);
      case BookingPeriod.week:
        final end = d.add(const Duration(days: 6));
        return '${DateFormat('dd/MM').format(d)} – ${DateFormat('dd/MM').format(end)}';
      case BookingPeriod.month:
        return DateFormat('MM/yyyy').format(d);
    }
  }

  /// Gom lại map theo-ngày (key yyyy-MM-dd) sang map theo kỳ đang chọn.
  Map<String, double> _rebucket(Map<String, double> daily) {
    if (_period == BookingPeriod.day) return daily;
    final out = <String, double>{};
    daily.forEach((k, v) {
      final d = DateTime.tryParse(k);
      if (d == null) return;
      final key = _bucketKey(d);
      out[key] = (out[key] ?? 0) + v;
    });
    return out;
  }

  /// Tập sân khác nhau được đặt trong mỗi kỳ (để hiện "n sân").
  Map<String, Set<String>> _bucketPitchSets() {
    final out = <String, Set<String>>{};
    for (final b in widget.bookings) {
      final d = DateTime.tryParse(b.bookingDate);
      if (d == null) continue;
      (out[_bucketKey(d)] ??= <String>{}).add(b.pitchName);
    }
    return out;
  }

  String get _periodSubtitle {
    switch (_period) {
      case BookingPeriod.day:
        return 'Theo ngày';
      case BookingPeriod.week:
        return 'Theo tuần';
      case BookingPeriod.month:
        return 'Theo tháng';
    }
  }

  String get _periodNoun {
    switch (_period) {
      case BookingPeriod.day:
        return 'ngày';
      case BookingPeriod.week:
        return 'tuần';
      case BookingPeriod.month:
        return 'tháng';
    }
  }

  /// Danh sách số lượt đặt + số sân theo từng kỳ (mới nhất trước).
  Widget _buildPeriodBreakdownCard() {
    final counts =
        _rebucket(_dailyBookings.map((k, v) => MapEntry(k, v.toDouble())));
    final pitchSets = _bucketPitchSets();
    final keys = counts.keys.toList()..sort((a, b) => b.compareTo(a));

    return _ChartCard(
      title: 'Chi tiết theo $_periodNoun',
      subtitle: '${keys.length} $_periodNoun có lượt đặt',
      child: keys.isEmpty
          ? _emptyState()
          : Column(
              children: List.generate(keys.length, (i) {
                final k = keys[i];
                return _PeriodBreakdownRow(
                  label: _bucketLabel(k),
                  bookingCount: counts[k]?.toInt() ?? 0,
                  pitchCount: pitchSets[k]?.length ?? 0,
                  isLast: i == keys.length - 1,
                );
              }),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(
          'Phân tích Đối tác',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryRed,
              unselectedLabelColor: AppColors.textGrey,
              indicator: UnderlineTabIndicator(
                borderSide: const BorderSide(
                  color: AppColors.primaryRed,
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Doanh thu'),
                Tab(text: 'Đặt sân'),
                Tab(text: 'Sân bãi'),
                Tab(text: 'Khách'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRevenueTab(),
          _buildBookingsTab(),
          _buildPitchesTab(),
          _buildCustomersTab(),
        ],
      ),
    );
  }

  // ─── Revenue tab ─────────────────────────────────────────────────────────────
  Widget _buildRevenueTab() {
    final totalRevenue = _paidBookings.fold(0.0, (s, b) => s + b.totalPrice);
    final avgRevenue = _paidBookings.isEmpty
        ? 0.0
        : totalRevenue / _paidBookings.length;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          _KpiRow(
            items: [
              _KpiItem(
                label: 'Tổng doanh thu',
                value: _currFmt.format(totalRevenue),
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF10B981),
              ),
              _KpiItem(
                label: 'Trung bình / đơn',
                value: _currFmt.format(avgRevenue),
                icon: Icons.receipt_long_rounded,
                color: const Color(0xFF6366F1),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PeriodSelector(
            period: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Xu hướng doanh thu',
            subtitle: _periodSubtitle,
            child: _AreaLineChart(
              data: _rebucket(_dailyRevenue),
              color: const Color(0xFF10B981),
              isCurrency: true,
            ),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Phân bổ theo sân',
            subtitle: 'Tỉ lệ doanh thu',
            child: _DonutChart(data: _pitchRevenue, isCurrency: true),
          ),
        ],
      ),
    );
  }

  // ─── Bookings tab ─────────────────────────────────────────────────────────────
  Widget _buildBookingsTab() {
    final total = widget.bookings.length;
    final confirmed = _statusDistribution['CONFIRMED'] ?? 0;
    final rate = total == 0 ? 0.0 : confirmed / total * 100;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          _KpiRow(
            items: [
              _KpiItem(
                label: 'Tổng đơn',
                value: '$total đơn',
                icon: Icons.event_note_rounded,
                color: const Color(0xFF0EA5E9),
              ),
              _KpiItem(
                label: 'Tỉ lệ hoàn thành',
                value: '${rate.toStringAsFixed(1)}%',
                icon: Icons.verified_rounded,
                color: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _PeriodSelector(
            period: _period,
            onChanged: (p) => setState(() => _period = p),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Xu hướng đặt sân',
            subtitle: _periodSubtitle,
            child: _AreaLineChart(
              data: _rebucket(
                _dailyBookings.map((k, v) => MapEntry(k, v.toDouble())),
              ),
              color: const Color(0xFF0EA5E9),
            ),
          ),
          const SizedBox(height: 16),
          _buildPeriodBreakdownCard(),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Trạng thái đơn',
            subtitle: 'Phân bổ tổng quan',
            child: _DonutChart(
              data: _statusDistribution.map(
                (k, v) => MapEntry(k, v.toDouble()),
              ),
              isStatus: true,
            ),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Khung giờ phổ biến',
            subtitle: 'Số lượt đặt theo giờ trong ngày',
            child: _PeakHourChart(data: _slotUsage),
          ),
        ],
      ),
    );
  }

  // ─── Pitches tab ─────────────────────────────────────────────────────────────
  Widget _buildPitchesTab() {
    final totalBookings = widget.bookings.length;
    final totalRevenue = _pitchRevenue.values.fold(0.0, (s, v) => s + v);

    final sortedByBookings = _pitchBookings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        children: [
          _ChartCard(
            title: 'Tần suất đặt sân',
            subtitle: 'Xếp hạng theo lượt đặt',
            child: Column(
              children: List.generate(sortedByBookings.length, (i) {
                final entry = sortedByBookings[i];
                final ratio = totalBookings == 0
                    ? 0.0
                    : entry.value / totalBookings;
                final color = _kPalette[i % _kPalette.length];
                return RankedProgressBar(
                  rank: i + 1,
                  label: entry.key,
                  count: '${entry.value} lượt',
                  ratio: ratio,
                  color: color,
                  isLast: i == sortedByBookings.length - 1,
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          _ChartCard(
            title: 'Doanh thu theo sân',
            subtitle: _currFmt.format(totalRevenue),
            child: _DonutChart(data: _pitchRevenue, isCurrency: true),
          ),
        ],
      ),
    );
  }

  // ─── Customers tab ────────────────────────────────────────────────────────────
  Widget _buildCustomersTab() {
    final sorted = _customerMetrics.values.toList()
      ..sort((a, b) => (b['spend'] as double).compareTo(a['spend'] as double));

    if (sorted.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 48, color: AppColors.textGrey),
            SizedBox(height: 12),
            Text(
              'Chưa có dữ liệu khách hàng',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    final maxSpend = (sorted.first['spend'] as double);

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final c = sorted[index];
        final spend = c['spend'] as double;
        final bookings = c['bookings'] as int;
        final ratio = maxSpend == 0 ? 0.0 : spend / maxSpend;
        final isTop = index < 3;
        final badgeColor = [
          const Color(0xFFFFD700),
          const Color(0xFFC0C0C0),
          const Color(0xFFCD7F32),
        ];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(_kCardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Rank badge
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isTop
                          ? badgeColor[index].withValues(alpha: 0.15)
                          : const Color(0xFFF4F6FB),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isTop
                          ? Icon(
                              Icons.emoji_events_rounded,
                              color: badgeColor[index],
                              size: 20,
                            )
                          : Text(
                              '${index + 1}',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textGrey,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c['name'] as String,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '$bookings lượt đặt',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _currFmt.format(spend),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        'tổng chi',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Spending bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: const Color(0xFFF0F0F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isTop
                        ? badgeColor[index]
                        : const Color(0xFF6366F1).withValues(alpha: 0.6),
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── KPI Row ──────────────────────────────────────────────────────────────────
class _KpiItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _KpiItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _KpiRow extends StatelessWidget {
  final List<_KpiItem> items;
  const _KpiRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: items.expand((item) sync* {
        if (items.indexOf(item) > 0) yield const SizedBox(width: 12);
        yield Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_kCardRadius),
              boxShadow: [
                BoxShadow(
                  color: item.color.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(height: 12),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item.value,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Chart card wrapper ───────────────────────────────────────────────────────
class _ChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_kCardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

// ─── Area line chart ──────────────────────────────────────────────────────────
class _AreaLineChart extends StatefulWidget {
  final Map<String, double> data;
  final Color color;
  final bool isCurrency;
  const _AreaLineChart({
    required this.data,
    required this.color,
    this.isCurrency = false,
  });

  @override
  State<_AreaLineChart> createState() => _AreaLineChartState();
}

class _AreaLineChartState extends State<_AreaLineChart> {
  int? _touchedIndex;

  String _fmt(double v) {
    if (widget.isCurrency) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}tr';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
      return v.toInt().toString();
    }
    return v.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final keys = widget.data.keys.toList()..sort();
    if (keys.isEmpty) return _emptyState();

    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < keys.length; i++) {
      final v = widget.data[keys[i]]!;
      spots.add(FlSpot(i.toDouble(), v));
      if (v > maxY) maxY = v;
    }
    maxY = maxY == 0 ? 10 : maxY * 1.25;

    return SizedBox(
      height: _kChartHeight,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                interval: maxY / 4,
                getTitlesWidget: (v, _) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _fmt(v),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textGrey,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= keys.length) return const SizedBox.shrink();
                  // Show label for first, last, and every ~5 days
                  final show = i == 0 || i == keys.length - 1 || i % 5 == 0;
                  if (!show) return const SizedBox.shrink();
                  final d = DateTime.tryParse(keys[i]);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      d != null ? DateFormat('dd/MM').format(d) : '',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textGrey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            handleBuiltInTouches: true,
            touchCallback: (event, response) {
              if (response?.lineBarSpots != null &&
                  response!.lineBarSpots!.isNotEmpty) {
                setState(
                  () => _touchedIndex = response.lineBarSpots!.first.spotIndex,
                );
              } else if (event is FlTapUpEvent || event is FlLongPressEnd) {
                setState(() => _touchedIndex = null);
              }
            },
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((i) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: widget.color.withValues(alpha: 0.4),
                    strokeWidth: 1.5,
                    dashArray: [4, 4],
                  ),
                  FlDotData(
                    show: true,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 6,
                      color: Colors.white,
                      strokeWidth: 2.5,
                      strokeColor: widget.color,
                    ),
                  ),
                );
              }).toList();
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.textDark,
              tooltipRoundedRadius: 10,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItems: (spots) => spots.map((s) {
                final i = s.spotIndex;
                final dateStr = i < keys.length ? keys[i] : '';
                final d = DateTime.tryParse(dateStr);
                final dateLabel = d != null
                    ? DateFormat('dd/MM/yyyy').format(d)
                    : dateStr;
                return LineTooltipItem(
                  '$dateLabel\n${_fmt(s.y)}',
                  GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: widget.color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length <= 14,
                getDotPainter: (spot, _, _, i) {
                  final isTouched = i == _touchedIndex;
                  return FlDotCirclePainter(
                    radius: isTouched ? 6 : 3,
                    color: isTouched ? widget.color : Colors.white,
                    strokeWidth: 2,
                    strokeColor: widget.color,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    widget.color.withValues(alpha: 0.25),
                    widget.color.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Donut chart ──────────────────────────────────────────────────────────────
class _DonutChart extends StatefulWidget {
  final Map<String, double> data;
  final bool isStatus;
  final bool isCurrency;
  const _DonutChart({
    required this.data,
    this.isStatus = false,
    this.isCurrency = false,
  });

  @override
  State<_DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<_DonutChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.values.fold(0.0, (s, v) => s + v);
    if (total == 0) return _emptyState();

    final entries = widget.data.entries.toList();
    final sections = List.generate(entries.length, (i) {
      final isTouched = i == _touchedIndex;
      final pct = entries[i].value / total * 100;
      final color = widget.isStatus
          ? _statusColor(entries[i].key)
          : _kPalette[i % _kPalette.length];

      return PieChartSectionData(
        color: color,
        value: entries[i].value,
        title: isTouched ? '${pct.toStringAsFixed(1)}%' : '',
        radius: isTouched ? 68 : 58,
        titleStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          shadows: [const Shadow(color: Colors.black26, blurRadius: 3)],
        ),
      );
    });

    final fmtCenter = widget.isCurrency
        ? _formatCompact(total)
        : total.toInt().toString();
    final centerLabel = widget.isCurrency ? 'Tổng thu' : 'Tổng đơn';

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 60,
                  sectionsSpace: 3,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (event is FlTapDownEvent) {
                          if (pieTouchResponse?.touchedSection != null &&
                              pieTouchResponse!
                                      .touchedSection!
                                      .touchedSectionIndex !=
                                  -1) {
                            final index = pieTouchResponse
                                .touchedSection!
                                .touchedSectionIndex;
                            _touchedIndex = _touchedIndex == index ? -1 : index;
                          } else {
                            _touchedIndex = -1;
                          }
                        }
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fmtCenter,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    centerLabel,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Legend
        Column(
          children: List.generate(entries.length, (i) {
            final isTouched = i == _touchedIndex;
            final pct = entries[i].value / total * 100;
            final color = widget.isStatus
                ? _statusColor(entries[i].key)
                : _kPalette[i % _kPalette.length];
            final label = widget.isStatus
                ? _statusLabel(entries[i].key)
                : entries[i].key;
            final valStr = widget.isCurrency
                ? _formatCompact(entries[i].value)
                : entries[i].value.toInt().toString();

            return GestureDetector(
              onTap: () {
                setState(() {
                  _touchedIndex = _touchedIndex == i ? -1 : i;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isTouched
                      ? color.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isTouched
                        ? color.withValues(alpha: 0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isTouched
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isTouched
                              ? AppColors.textDark
                              : AppColors.textGrey,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      valStr,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${pct.toStringAsFixed(1)}%',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Peak hour bar chart ──────────────────────────────────────────────────────
class _PeakHourChart extends StatefulWidget {
  final List<int> data;
  const _PeakHourChart({required this.data});

  @override
  State<_PeakHourChart> createState() => _PeakHourChartState();
}

class _PeakHourChartState extends State<_PeakHourChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    // Only display 5:00 to 23:00 (indices 5 to 23)
    final relevantData = widget.data.sublist(5, 24);
    if (relevantData.every((v) => v == 0)) return _emptyState();

    final maxVal = relevantData.reduce((a, b) => a > b ? a : b);
    final peakHour = relevantData.indexOf(maxVal) + 5;
    final chartMax = maxVal == 0 ? 10.0 : maxVal * 1.3;

    return SizedBox(
      height: _kChartHeight,
      child: BarChart(
        BarChartData(
          maxY: chartMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) {
                  if (v % 1 != 0 || v == 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${v.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textGrey,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i % 3 != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${i}h',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textGrey,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (event is FlTapDownEvent) {
                  if (barTouchResponse?.spot != null &&
                      barTouchResponse!.spot!.touchedBarGroupIndex != -1) {
                    final index = barTouchResponse.spot!.touchedBarGroupIndex;
                    _touchedIndex = _touchedIndex == index ? null : index;
                  } else {
                    _touchedIndex = null;
                  }
                }
              });
            },
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.textDark,
              tooltipRoundedRadius: 10,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${group.x}:00 – ${group.x + 1}:00\n${rod.toY.toInt()} lượt đặt',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          barGroups: List.generate(19, (index) {
            final i = index + 5;
            final isPeak = i == peakHour;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: widget.data[i].toDouble(),
                  gradient: isPeak
                      ? const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                  width: 9,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: chartMax,
                    color: Colors.grey.shade50,
                  ),
                ),
              ],
              // _touchedIndex corresponds to the index of this group in the 0..18 list
              showingTooltipIndicators:
                  (_touchedIndex == null && isPeak) || _touchedIndex == index
                  ? [0]
                  : [],
            );
          }),
        ),
      ),
    );
  }
}

// ─── Period selector (Ngày / Tuần / Tháng) ────────────────────────────────────
class _PeriodSelector extends StatelessWidget {
  final BookingPeriod period;
  final ValueChanged<BookingPeriod> onChanged;
  const _PeriodSelector({required this.period, required this.onChanged});

  static const _items = [
    (BookingPeriod.day, 'Ngày'),
    (BookingPeriod.week, 'Tuần'),
    (BookingPeriod.month, 'Tháng'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: _items.map((e) {
          final selected = e.$1 == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryRed : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  e.$2,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textGrey,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Period breakdown row ──────────────────────────────────────────────────────
class _PeriodBreakdownRow extends StatelessWidget {
  final String label;
  final int bookingCount;
  final int pitchCount;
  final bool isLast;

  const _PeriodBreakdownRow({
    required this.label,
    required this.bookingCount,
    required this.pitchCount,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0EA5E9).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.event_note_rounded,
                color: Color(0xFF0EA5E9), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$bookingCount lượt',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                '$pitchCount sân',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
Widget _emptyState() {
  return const SizedBox(
    height: 160,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bar_chart_rounded, size: 40, color: AppColors.textGrey),
          SizedBox(height: 8),
          Text(
            'Chưa có dữ liệu',
            style: TextStyle(color: AppColors.textGrey, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

String _formatCompact(double v) {
  if (v >= 1000000000) return '${(v / 1000000000).toStringAsFixed(1)}tỷ';
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}tr';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}k';
  return v.toInt().toString();
}
