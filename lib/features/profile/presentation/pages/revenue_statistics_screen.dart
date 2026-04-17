import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../pitch/data/models/booking_response_model.dart';
import '../cubit/provider_revenue_cubit.dart';
import '../../../../core/constants/app_colors.dart';

class RevenueStatisticsScreen extends StatefulWidget {
  final List<BookingResponseModel> bookings;
  final RevenueTimeRange initialRange;

  const RevenueStatisticsScreen({
    super.key,
    required this.bookings,
    required this.initialRange,
  });

  @override
  State<RevenueStatisticsScreen> createState() => _RevenueStatisticsScreenState();
}

class _RevenueStatisticsScreenState extends State<RevenueStatisticsScreen> {
  late List<BookingResponseModel> _paidBookings;
  
  // Data for charts
  Map<String, double> _dailyRevenue = {};
  Map<String, double> _pitchRevenue = {};
  
  final currencyFmt = NumberFormat.currency(locale: 'vi_VN', symbol: '₫', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _processData();
  }

  void _processData() {
    // Only count CONFIRMED and PAID for revenue
    _paidBookings = widget.bookings.where((b) =>
        b.status.toUpperCase() == 'CONFIRMED' &&
        b.paymentStatus.toUpperCase() == 'PAID').toList();

    // Group by Date
    _dailyRevenue = {};
    for (var b in _paidBookings) {
      final date = b.bookingDate; // Assuming format is YYYY-MM-DD
      _dailyRevenue[date] = (_dailyRevenue[date] ?? 0) + b.totalPrice;
    }

    // Group by Pitch
    _pitchRevenue = {};
    for (var b in _paidBookings) {
      _pitchRevenue[b.pitchName] = (_pitchRevenue[b.pitchName] ?? 0) + b.totalPrice;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'Phân tích Doanh thu',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildCashFlowSection(),
            const SizedBox(height: 24),
            _buildPitchDistributionSection(),
            const SizedBox(height: 24),
            _buildTopPitchesTable(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalRevenue = _paidBookings.fold(0.0, (sum, b) => sum + b.totalPrice);
    final avgRevenue = _paidBookings.isEmpty ? 0.0 : totalRevenue / _paidBookings.length;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            label: 'Tổng thu nhập',
            value: currencyFmt.format(totalRevenue),
            color: Colors.green,
            icon: Icons.payments_outlined,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            label: 'Trung bình/Đơn',
            value: currencyFmt.format(avgRevenue),
            color: Colors.blue,
            icon: Icons.analytics_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildCashFlowSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biểu đồ luồng tiền',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const Icon(Icons.trending_up, color: Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: _paidBookings.isEmpty 
              ? const Center(child: Text('Không có dữ liệu'))
              : _LineChartWidget(dailyRevenue: _dailyRevenue),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchDistributionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Doanh thu theo sân',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: _pitchRevenue.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                : _PieChartWidget(pitchRevenue: _pitchRevenue),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPitchesTable() {
    final sortedPitches = _pitchRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chi tiết từng sân',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedPitches.length,
            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final entry = sortedPitches[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.primaries[index % Colors.primaries.length].withValues(alpha: 0.1),
                      radius: 16,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: Colors.primaries[index % Colors.primaries.length],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      currencyFmt.format(entry.value),
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.primaryRed),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey)),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              value,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartWidget extends StatelessWidget {
  final Map<String, double> dailyRevenue;
  const _LineChartWidget({required this.dailyRevenue});

  @override
  Widget build(BuildContext context) {
    final sortedKeys = dailyRevenue.keys.toList()..sort();
    if (sortedKeys.isEmpty) return const SizedBox.shrink();

    final spots = <FlSpot>[];
    for (int i = 0; i < sortedKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), dailyRevenue[sortedKeys[i]]!));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index < 0 || index >= sortedKeys.length) return const SizedBox.shrink();
                // Show only first and last or every 3rd to avoid clutter
                if (index == 0 || index == sortedKeys.length - 1 || index % 3 == 0) {
                  final date = DateTime.tryParse(sortedKeys[index]);
                  return Text(
                    date != null ? DateFormat('dd/MM').format(date) : '',
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: AppColors.primaryRed,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primaryRed.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _PieChartWidget extends StatelessWidget {
  final Map<String, double> pitchRevenue;
  const _PieChartWidget({required this.pitchRevenue});

  @override
  Widget build(BuildContext context) {
    final total = pitchRevenue.values.fold(0.0, (s, v) => s + v);
    final sections = <PieChartSectionData>[];
    
    int i = 0;
    pitchRevenue.forEach((name, revenue) {
      final percentage = (revenue / total) * 100;
      if (percentage > 5) { // Only show labels for > 5%
        sections.add(
          PieChartSectionData(
            color: Colors.primaries[i % Colors.primaries.length],
            value: revenue,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      } else {
        sections.add(
          PieChartSectionData(
            color: Colors.primaries[i % Colors.primaries.length],
            value: revenue,
            title: '',
            radius: 50,
          ),
        );
      }
      i++;
    });

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
}
