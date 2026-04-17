import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../pitch/data/models/booking_response_model.dart';
import '../../../../core/constants/app_colors.dart';

enum InsightsTab { revenue, bookings, pitches, customers }

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

class _PartnerInsightsScreenState extends State<PartnerInsightsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late List<BookingResponseModel> _paidBookings;
  
  Map<String, double> _dailyRevenue = {};
  Map<String, int> _dailyBookings = {};
  Map<String, int> _statusDistribution = {};
  Map<String, int> _pitchBookings = {};
  Map<String, double> _pitchRevenue = {};
  List<int> _slotUsage = List.filled(24, 0);
  Map<String, Map<String, dynamic>> _customerMetrics = {};
  
  final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab.index);
    _processData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _processData() {
    _paidBookings = widget.bookings.where((b) =>
        b.status.toUpperCase() == 'CONFIRMED' &&
        b.paymentStatus.toUpperCase() == 'PAID').toList();

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
          if (slot >= 0 && slot < 24) _slotUsage[slot]++;
        }
      }

      final userId = b.userId;
      final current = _customerMetrics[userId] ?? {
        'name': b.userName,
        'bookings': 0,
        'spend': 0.0,
      };
      current['bookings'] = (current['bookings'] as int) + 1;
      if (status == 'CONFIRMED' && b.paymentStatus.toUpperCase() == 'PAID') {
        current['spend'] = (current['spend'] as double) + b.totalPrice;
        _dailyRevenue[date] = (_dailyRevenue[date] ?? 0) + b.totalPrice;
        _pitchRevenue[b.pitchName] = (_pitchRevenue[b.pitchName] ?? 0) + b.totalPrice;
      }
      _customerMetrics[userId] = current;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Phân tích Đối tác',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryRed,
          unselectedLabelColor: AppColors.textGrey,
          indicatorColor: AppColors.primaryRed,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(text: 'Tiền tệ'),
            Tab(text: 'Lượng đặt'),
            Tab(text: 'Sân bãi'),
            Tab(text: 'Khách'),
          ],
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

  Widget _buildRevenueTab() {
    final totalRevenue = _paidBookings.fold(0.0, (sum, b) => sum + b.totalPrice);
    final avgRevenue = _paidBookings.isEmpty ? 0.0 : totalRevenue / _paidBookings.length;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        children: [
          _buildSummaryCards(
            leftLabel: 'Tổng thu nhập',
            leftValue: currencyFmt.format(totalRevenue),
            leftColor: Colors.green,
            rightLabel: 'Trung bình/Đơn',
            rightValue: currencyFmt.format(avgRevenue),
            rightColor: Colors.blue,
          ),
          const SizedBox(height: 24),
          _buildChartContainer(
            title: 'Biểu đồ luồng tiền',
            icon: Icons.trending_up,
            child: _LineChartWidget(data: _dailyRevenue, color: const Color(0xFF6366F1), isCurrency: true),
          ),
          const SizedBox(height: 24),
          _buildChartContainer(
            title: 'Doanh thu theo sân',
            child: _PieChartWidget(data: _pitchRevenue),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    final total = widget.bookings.length;
    final confirmed = _statusDistribution['CONFIRMED'] ?? 0;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        children: [
          _buildSummaryCards(
            leftLabel: 'Tổng số đơn',
            leftValue: '$total đơn',
            leftColor: Colors.blue,
            rightLabel: 'Đã hoàn thành',
            rightValue: '$confirmed đơn',
            rightColor: Colors.green,
          ),
          const SizedBox(height: 24),
          _buildChartContainer(
            title: 'Xu hướng lượng đặt',
            icon: Icons.show_chart,
            child: _LineChartWidget(data: _dailyBookings.map((k, v) => MapEntry(k, v.toDouble())), color: const Color(0xFF0EA5E9)),
          ),
          const SizedBox(height: 24),
          _buildChartContainer(
            title: 'Trạng thái đơn hàng',
            child: _PieChartWidget(data: _statusDistribution.map((k, v) => MapEntry(k, v.toDouble())), isStatus: true),
          ),
          const SizedBox(height: 24),
          _buildChartContainer(
            title: 'Khung giờ phổ biến',
            child: _BarChartWidget(data: _slotUsage),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        children: [
          _buildChartContainer(
            title: 'Tần suất đặt sân',
            child: Column(
              children: _pitchBookings.entries.map((e) {
                final ratio = widget.bookings.isEmpty ? 0.0 : e.value / widget.bookings.length;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          Text('${e.value} lượt', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: ratio,
                        backgroundColor: Colors.grey.shade100,
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 8,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          _buildChartContainer(
            title: 'Phân bổ doanh thu',
            child: _PieChartWidget(data: _pitchRevenue),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersTab() {
    final sortedCustomers = _customerMetrics.values.toList()
      ..sort((a, b) => (b['spend'] as double).compareTo(a['spend'] as double));

    if (sortedCustomers.isEmpty) {
        return const Center(child: Text('Chưa có dữ liệu khách hàng'));
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      itemCount: sortedCustomers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = sortedCustomers[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                child: Text('${index + 1}', style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('${customer['bookings']} đơn đặt', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(currencyFmt.format(customer['spend']), style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.green)),
                  const Text('Tổng chi', style: TextStyle(fontSize: 10, color: AppColors.textGrey)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards({
    required String leftLabel,
    required String leftValue,
    required Color leftColor,
    required String rightLabel,
    required String rightValue,
    required Color rightColor,
  }) {
    return Row(
      children: [
        Expanded(child: _SummaryCard(label: leftLabel, value: leftValue, color: leftColor, icon: Icons.analytics)),
        const SizedBox(width: 12),
        Expanded(child: _SummaryCard(label: rightLabel, value: rightValue, color: rightColor, icon: Icons.check_circle)),
      ],
    );
  }

  Widget _buildChartContainer({required String title, IconData? icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textDark)),
              if (icon != null) Icon(icon, color: AppColors.textGrey, size: 20),
            ],
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 14),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 19, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final Color color;
  final bool isCurrency;
  const _LineChartWidget({required this.data, required this.color, this.isCurrency = false});

  String _formatValue(double value) {
    if (isCurrency) {
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}tr';
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
      return value.toInt().toString();
    }
    return value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final sortedKeys = data.keys.toList()..sort();
    if (sortedKeys.isEmpty) return const SizedBox(height: 180, child: Center(child: Text('Không có dữ liệu')));

    final spots = <FlSpot>[];
    double maxY = 0;
    for (int i = 0; i < sortedKeys.length; i++) {
      final val = data[sortedKeys[i]]!;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxY) maxY = val;
    }
    
    // Add margin to maxY
    maxY = maxY == 0 ? 10 : maxY * 1.2;

    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(_formatValue(value), style: const TextStyle(fontSize: 10, color: AppColors.textGrey), textAlign: TextAlign.right),
                ),
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index < 0 || index >= sortedKeys.length) return const SizedBox.shrink();
                  if (index == 0 || index == sortedKeys.length - 1 || index % 3 == 0) {
                    final date = DateTime.tryParse(sortedKeys[index]);
                    return Text(date != null ? DateFormat('dd/MM').format(date) : '', style: const TextStyle(fontSize: 10, color: AppColors.textGrey));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.textDark.withValues(alpha: 0.8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((s) {
                  return LineTooltipItem(
                    _formatValue(s.y),
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: color,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: Colors.white, strokeWidth: 2, strokeColor: color),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.0)],
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

class _PieChartWidget extends StatelessWidget {
  final Map<String, double> data;
  final bool isStatus;
  const _PieChartWidget({required this.data, this.isStatus = false});

  @override
  Widget build(BuildContext context) {
    final total = data.values.fold(0.0, (s, v) => s + v);
    if (total == 0) return const SizedBox(height: 180, child: Center(child: Text('Không có dữ liệu')));

    final sections = <PieChartSectionData>[];
    final legendEntries = <Widget>[];
    
    int i = 0;
    data.forEach((key, value) {
      final percentage = (value / total) * 100;
      Color color;
      if (isStatus) {
        color = key == 'CONFIRMED' ? Colors.green : (key == 'CANCELED' ? Colors.red : Colors.orange);
      } else {
        color = Colors.primaries[i % Colors.primaries.length];
      }

      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 55,
          titleStyle: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            shadows: [const Shadow(color: Colors.black26, blurRadius: 2)],
          ),
          badgeWidget: null, // Removed bubble badge for cleaner look
          badgePositionPercentageOffset: 0.9,
        ),
      );

      legendEntries.add(_LegendItem(color: color, label: key, value: value.toInt().toString()));
      i++;
    });

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 45,
              sectionsSpace: 4,
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: legendEntries.map((e) => SizedBox(
              width: (MediaQuery.of(context).size.width - 80) / 2, // 2 items per row
              child: e,
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AppColors.textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BarChartWidget extends StatelessWidget {
  final List<int> data;
  const _BarChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty ? 10.0 : data.reduce((a, b) => a > b ? a : b).toDouble() * 1.2;
    if (data.every((v) => v == 0)) return const SizedBox(height: 180, child: Center(child: Text('Không có dữ liệu')));

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxVal == 0 ? 10 : maxVal,
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: false, 
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0) return const SizedBox.shrink(); // Only integers
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '${value.toInt()} đơn',
                      style: const TextStyle(fontSize: 9, color: AppColors.textGrey, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx % 4 == 0) return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('$idx:00', style: const TextStyle(fontSize: 9, color: AppColors.textGrey)),
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.textDark.withValues(alpha: 0.8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                '${group.x}:00\n${rod.toY.toInt()} đơn',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          barGroups: List.generate(data.length, (i) => BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: data[i].toDouble(),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxVal, color: Colors.grey.shade50),
              )
            ],
          )),
        ),
      ),
    );
  }
}
