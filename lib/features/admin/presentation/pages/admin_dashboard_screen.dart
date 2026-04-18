import 'dart:math' as math;
import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../features/auth/domain/entities/user_entity.dart';
import '../../data/models/admin_overview_model.dart';
import '../../data/models/booking_by_day_model.dart';
import '../../data/models/pitch_type_model.dart';
import '../../data/models/product_statistics_model.dart';
import '../../data/models/recent_booking_model.dart';
import '../../data/models/revenue_point_model.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../cubit/admin_dashboard_state.dart';
import 'admin_bookings_screen.dart';
import 'admin_orders_screen.dart';
import 'admin_pitches_screen.dart';
import 'admin_rating_screen.dart';
import 'admin_revenue_screen.dart';
import 'admin_users_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserEntity user;

  const AdminDashboardScreen({super.key, required this.user});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int? _touchedDonutIndex;
  int? _touchedBarIndex;
  DateTime _lastUpdated = DateTime.now();

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

  // Hero — diagonal Deep Indigo → Soft Violet pastel
  static const _kHeroStart = Color(0xFF3E54AC);
  static const _kHeroEnd = Color(0xFFBFACE2);
  static const _kHeroDark = Color(0xFF3E54AC);

  // Semantic
  static const _kPositive = Color(0xFF10B981);
  static const _kNegative = Color(0xFFEF4444);
  static const _kWarning = Color(0xFFF59E0B);

  // Palette A — KPI card accents
  static const _kDeepIndigo = Color(0xFF3E54AC);
  static const _kMidViolet = Color(0xFF7C6FCD);
  static const _kTealMint = Color(0xFF0D9988);
  static const _kCoralPink = Color(0xFFE05FA3);

  static const List<Color> _kDonutColors = [
    _kDeepIndigo,
    _kMidViolet,
    _kTealMint,
    _kCoralPink,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminDashboardCubit, AdminDashboardState>(
      listener: (context, state) {
        // Cập nhật lại thời gian khi Cubit tải xong dữ liệu thành công
        if (state is AdminDashboardLoaded) {
          _lastUpdated = DateTime.now(); 
        }
      },
      builder: (context, state) {
        if (state is AdminDashboardLoading || state is AdminDashboardInitial) {
          return _buildLoadingBody();
        }
        if (state is AdminDashboardError) {
          return _buildErrorBody(state.message);
        }
        if (state is AdminDashboardLoaded) {
          return _buildLoadedBody(state);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildLoadingBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeroSkeleton(),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _buildSkeletonBox(height: 200),
                const SizedBox(height: 20),
                _buildSkeletonBox(height: 280),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSkeleton() {
    return Container(
      height: 180,
      color: _kHeroDark,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white54),
      ),
    );
  }

  Widget _buildSkeletonBox({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildErrorBody(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: _kNegative, size: 48),
          const SizedBox(height: 16),
          Text(message,
              style: GoogleFonts.inter(
                  fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () =>
                context.read<AdminDashboardCubit>().loadDashboard(),
            child:
                Text('Thử lại', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedBody(AdminDashboardLoaded state) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroHeader(state.overview),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildKpiGrid(state.overview, state.revenueData, state.pitchesByType),
                const SizedBox(height: 24),
                _buildRevenueChart(
                    state.revenueData, state.overview, state.selectedTimeRange),
                const SizedBox(height: 20),
                _buildBarChart(state.bookingsByDay),
                const SizedBox(height: 16),
                _buildDonutChart(
                    state.pitchesByType, state.overview.totalPitches),
                const SizedBox(height: 20),
                _buildProductSection(state.productStatistics),
                const SizedBox(height: 20),
                _buildActivityFeed(state.recentBookings),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── HERO HEADER ─────────────────────────────────────────────────────────

  Widget _buildHeroHeader(AdminOverviewModel overview) {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, d MMMM, y', 'vi').format(now);
    final revenue = _formatRevenue(overview.totalRevenue);

    final statusBarHeight = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kHeroStart, _kHeroEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, statusBarHeight + 20, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào,',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.white.withOpacity(0.7)),
                    ),
                    Text(
                      widget.user.name,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: const Icon(Icons.notifications_outlined,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 0,
            runSpacing: 6,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.white.withOpacity(0.6)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Container(
                  width: 4, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      return Text(
                        _getTimeAgo(),
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500),
                      );
                    }
                  ),
                  const SizedBox(width: 2),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        context.read<AdminDashboardCubit>().loadDashboard();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.sync_rounded,
                          size: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildGlassStat(
                      revenue, 'Doanh thu', Icons.trending_up)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildGlassStat('${overview.totalUsers}', 'Người dùng',
                      Icons.people_outline)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildGlassStat('${overview.bookingsTodayCount}',
                      'Đặt sân HN', Icons.calendar_today_outlined)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassStat(String value, String label, IconData icon) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.22), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.8), size: 14),
              const SizedBox(height: 6),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.65),
                    height: 1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── KPI GRID ─────────────────────────────────────────────────────────────

  Widget _buildKpiGrid(AdminOverviewModel overview,
      List<RevenuePointModel> revenueData, List<PitchTypeModel> pitchTypes) {
    final sparkSpots = _revenueToSpots(revenueData);

    String pct(double v) {
      final formatted = v.toStringAsFixed(1);
      if (formatted == '0.0' || formatted == '-0.0') return ''; // Nếu là 0 thì trả về chuỗi rỗng
      return '${v > 0 ? '+' : ''}$formatted%';
    }
    Color changeColor(double v) =>
        v > 0 ? _kTealMint : v < 0 ? _kCoralPink : Colors.grey.shade400;
    bool isPos(double v) => v > 0;

    final ds = context.read<AdminDashboardCubit>().datasource;
    void push(Widget screen) =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

    return Column(
      children: [
        GestureDetector(
          onTap: () => push(AdminRevenueScreen(overview: overview, revenueData: revenueData)),
          child: _buildLargeKpiCard(
            title: 'Tổng doanh thu',
            value: _formatRevenue(overview.totalRevenue),
            change: pct(overview.revenueChangePercent),
            changeColor: changeColor(overview.revenueChangePercent),
            isPositive: isPos(overview.revenueChangePercent),
            icon: Icons.account_balance_wallet_outlined,
            accentColor: _kDeepIndigo,
            sparklineSpots: sparkSpots,
            bookingRevenue: overview.bookingRevenue,
            productRevenue: overview.productRevenue,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => push(AdminUsersScreen(datasource: ds)),
                child: _buildCompactKpiCard(
                  title: 'Người dùng',
                  value: _formatNumber(overview.totalUsers),
                  change: pct(overview.usersChangePercent),
                  changeColor: changeColor(overview.usersChangePercent),
                  icon: Icons.people_outline,
                  accentColor: _kMidViolet,
                  sparklineSpots: const [],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => push(AdminPitchesScreen(datasource: ds, pitchTypeData: pitchTypes)),
                child: _buildRingKpiCard(
                  title: 'Sân hoạt động',
                  value: _formatNumber(overview.totalPitches),
                  change: pct(overview.pitchesChangePercent),
                  changeColor: changeColor(overview.pitchesChangePercent),
                  accentColor: _kDeepIndigo,
                  progress: (overview.totalPitches / 200).clamp(0.0, 1.0),
                  icon: Icons.sports_soccer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => push(AdminBookingsScreen(datasource: ds)),
                child: _buildCompactKpiCard(
                  title: 'Tổng đơn đặt sân',
                  value: _formatNumber(overview.totalBookings),
                  change: pct(overview.bookingsTodayChangePercent),
                  changeColor: changeColor(overview.bookingsTodayChangePercent),
                  icon: Icons.calendar_today_outlined,
                  accentColor: _kTealMint,
                  sparklineSpots: const [],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => push(AdminRatingScreen(datasource: ds)),
                child: _buildRingKpiCard(
                  title: 'Đánh giá TB',
                  value: overview.averageRating.toStringAsFixed(1),
                  change: '/ 5.0 ★',
                  changeColor: Colors.grey.shade400,
                  accentColor: _kMidViolet,
                  progress: (overview.averageRating / 5.0).clamp(0.0, 1.0),
                  icon: Icons.star_outline_rounded,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => push(AdminOrdersScreen(datasource: ds)),
          child: _buildPendingKpiCard(
            value: _formatNumber(overview.pendingOrdersCount),
            accentColor: _kWarning,
          ),
        ),
      ],
    );
  }

  Widget _buildLargeKpiCard({
    required String title,
    required String value,
    required String change,
    required Color changeColor,
    required bool isPositive,
    required IconData icon,
    required Color accentColor,
    required List<FlSpot> sparklineSpots,
    double bookingRevenue = 0,
    double productRevenue = 0,
  }) {
    final hasBreakdown = bookingRevenue > 0 || productRevenue > 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: accentColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600),
                  ),
                ],
              ),
              if (change.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: changeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    change,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: changeColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87,
                    height: 1,
                    letterSpacing: -1),
              ),
              if (sparklineSpots.isNotEmpty)
                _buildSparkline(sparklineSpots, accentColor,
                    barWidth: 2, height: 36),
            ],
          ),
          if (hasBreakdown) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRevenueBreakdownItem(
                      label: 'Đặt sân',
                      value: _formatRevenue(bookingRevenue),
                      color: _kDeepIndigo,
                      icon: Icons.sports_soccer_outlined,
                    ),
                  ),
                  Container(width: 1, height: 32, color: Colors.grey.shade200),
                  Expanded(
                    child: _buildRevenueBreakdownItem(
                      label: 'Sản phẩm',
                      value: _formatRevenue(productRevenue),
                      color: _kTealMint,
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRevenueBreakdownItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500)),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactKpiCard({
    required String title,
    required String value,
    required String change,
    required Color changeColor,
    required IconData icon,
    required Color accentColor,
    required List<FlSpot> sparklineSpots,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              if (sparklineSpots.isNotEmpty)
                _buildSparkline(sparklineSpots, accentColor,
                    barWidth: 1.5, height: 24),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: changeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRingKpiCard({
    required String title,
    required String value,
    required String change,
    required Color changeColor,
    required Color accentColor,
    required double progress,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon ?? Icons.bar_chart_outlined, size: 18, color: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                change,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: changeColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingKpiCard({
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.pending_actions_outlined,
                color: accentColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Đơn hàng chờ xử lý',
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade500)),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        height: 1.1)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Xem tất cả →',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accentColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildSparkline(List<FlSpot> spots, Color color,
      {double barWidth = 1.5, double height = 28}) {
    return SizedBox(
      width: 50,
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.5,
              color: color,
              barWidth: barWidth,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
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

  // ─── REVENUE CHART ────────────────────────────────────────────────────────

  Widget _buildRevenueChart(List<RevenuePointModel> data,
      AdminOverviewModel overview, int selectedRange) {
    final spots = _revenueToSpots(data);
    final total = _formatRevenue(overview.totalRevenue);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hiệu suất doanh thu',
            style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  'Cập nhật lần cuối: hôm nay',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey.shade400),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTimeRangeToggle(0, '1T', selectedRange),
                  _buildTimeRangeToggle(1, '1Th', selectedRange),
                  _buildTimeRangeToggle(2, '1N', selectedRange),
                  _buildTimeRangeToggle(3, 'Tất cả', selectedRange),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                total,
                style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.black87),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: overview.revenueChangePercent >= 0
                      ? _kPositive.withOpacity(0.12)
                      : _kNegative.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${overview.revenueChangePercent >= 0 ? '+' : ''}${overview.revenueChangePercent.toStringAsFixed(1)}%',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: overview.revenueChangePercent >= 0
                        ? _kPositive
                        : _kNegative,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: spots.isEmpty
                ? Center(
                    child: Text('Chưa có dữ liệu',
                        style: GoogleFonts.inter(color: Colors.grey)))
                : LineChart(
                    LineChartData(
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: const Color(0xFFF0F0F5),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 1, 
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt() - 1;
                              final total = data.length;
                              if (index < 0 || index >= total) return const SizedBox();

                              // Thuật toán: Chia mảng dữ liệu ra thành khoảng 5 khúc
                              int step = (total / 5).ceil();
                              if (step < 1) step = 1;

                              // CHỈ hiển thị nhãn nếu là: Điểm ĐẦU, Điểm CUỐI, hoặc nằm đúng vào bước nhảy (step)
                              bool isVisible = (index == 0) || (index == total - 1) || (index % step == 0);
                              
                              if (!isVisible) return const SizedBox(); // Ẩn các mốc còn lại để có khoảng trống

                              String labelText = '';
                              final now = DateTime.now();
                              final stepsBack = total - 1 - index;
                              
                              if (selectedRange == 0) { 
                                // 1 Tuần: Dùng T2, T3... CN cho siêu gọn
                                final date = now.subtract(Duration(days: stepsBack));
                                int weekday = date.weekday;
                                labelText = weekday == 7 ? 'CN' : 'T${weekday + 1}';
                              } 
                              else if (selectedRange == 1) { 
                                // 1 Tháng: Ngày/Tháng (VD: 15/4)
                                final date = now.subtract(Duration(days: stepsBack));
                                labelText = '${date.day}/${date.month}';
                              } 
                              else if (selectedRange == 2) { 
                                // 1 Năm: Tháng (VD: Th1, Th4, Th7...)
                                int m = now.month - stepsBack;
                                while (m <= 0) m += 12;
                                labelText = 'Th$m';
                              } 
                              else { 
                                // Tất cả: Ánh xạ đều mốc thời gian từ 1/1/2025 đến ngày hiện tại
                                DateTime startDate = DateTime(2025, 1, 1);
                                int totalDays = now.difference(startDate).inDays;
                                
                                // Tính phần trăm vị trí hiện tại và quy ra ngày thực tế
                                double percent = total <= 1 ? 1.0 : index / (total - 1);
                                DateTime mappedDate = startDate.add(Duration(days: (totalDays * percent).round()));
                                
                                // Hiển thị dạng Tháng/Năm (VD: 6/25, 3/26) để không bị lặp lại "2025 2025"
                                String shortYear = mappedDate.year.toString().substring(2);
                                labelText = '${mappedDate.month}/$shortYear';
                                
                                // MẸO: Nếu bạn THỰC SỰ CHỈ MUỐN HIỆN SỐ 2025, 2026 thì xóa 2 dòng trên và dùng dòng dưới:
                                // labelText = '${mappedDate.year}';
                              }

                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  labelText,
                                  style: GoogleFonts.inter(
                                    color: Colors.grey.shade500, // Đậm màu lên một chút cho dễ nhìn
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${(value / 1000000).toStringAsFixed(0)}tr',
                                style: GoogleFonts.inter(
                                    color: Colors.grey.shade400, fontSize: 10),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => _kHeroDark,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (spots) => spots
                              .map((spot) => LineTooltipItem(
                                    _formatRevenue(spot.y),
                                    GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ))
                              .toList(),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          preventCurveOverShooting: true,
                          color: AppColors.primaryRed,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryRed.withOpacity(0.18),
                                AppColors.primaryRed.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeToggle(int index, String label, int selectedRange) {
    final isSelected = selectedRange == index;
    return GestureDetector(
      onTap: () => context.read<AdminDashboardCubit>().changeTimeRange(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(left: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // ─── BAR CHART ────────────────────────────────────────────────────────────

  Widget _buildBarChart(List<BookingByDayModel> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Đặt sân theo ngày',
              style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 2),
          Text('7 ngày gần nhất',
              style: GoogleFonts.inter(
                  fontSize: 11, color: Colors.grey.shade400)),
          const SizedBox(height: 14),
          SizedBox(
            height: 160,
            child: data.isEmpty
                ? Center(
                    child: Text('Chưa có dữ liệu',
                        style: GoogleFonts.inter(color: Colors.grey)))
                : BarChart(
                    BarChartData(
                      maxY: data.isEmpty ? 10 : data.map((e) => e.count.toDouble()).reduce(math.max) * 1.25,
                      barGroups: data.asMap().entries.map((e) {
                        final i = e.key;
                        final item = e.value;
                        final isActive = _touchedBarIndex == i;
                        final hasData = item.count > 0;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: hasData ? item.count.toDouble() : 0.5,
                              width: 22,
                              borderRadius: BorderRadius.circular(6),
                              color: isActive
                                  ? _kDeepIndigo
                                  : (hasData
                                      ? _kDeepIndigo.withOpacity(0.2)
                                      : Colors.grey.shade100),
                            ),
                          ],
                        );
                      }).toList(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                            color: Color(0xFFF0F0F5), strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= data.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  data[idx].dayLabel,
                                  style: GoogleFonts.inter(
                                      color: Colors.grey.shade400,
                                      fontSize: 10),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        touchCallback: (event, response) {
                          setState(() {
                            if (response?.spot != null) {
                              _touchedBarIndex =
                                  response!.spot!.touchedBarGroupIndex;
                            } else {
                              _touchedBarIndex = null;
                            }
                          });
                        },
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => _kHeroDark,
                          getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                            '${rod.toY.toInt()} đặt sân',
                            GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─── DONUT CHART ──────────────────────────────────────────────────────────

  static const double _kDonutSize = 160.0;

  void _handleDonutTap(TapDownDetails details, List<PitchTypeModel> data) {
    final c = Offset(_kDonutSize / 2, _kDonutSize / 2);
    final dx = details.localPosition.dx - c.dx;
    final dy = details.localPosition.dy - c.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 28 || dist > _kDonutSize / 2 - 2) return;

    double angle = math.atan2(dy, dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;

    final total = data.fold(0.0, (s, e) => s + e.percentage);
    double cum = 0;
    for (int i = 0; i < data.length; i++) {
      cum += (data[i].percentage / total) * 2 * math.pi;
      if (angle <= cum) {
        setState(() => _touchedDonutIndex = _touchedDonutIndex == i ? null : i);
        return;
      }
    }
  }

  Widget _buildDonutChart(List<PitchTypeModel> data, int totalPitches) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kDeepIndigo.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phân bố loại sân',
                      style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87)),
                  Text('Tổng $totalPitches',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: Colors.grey.shade400)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('Hiện tại',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (data.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Chưa có dữ liệu',
                    style: GoogleFonts.inter(color: Colors.grey)),
              ),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTapDown: (d) => _handleDonutTap(d, data),
                  child: SizedBox(
                    width: _kDonutSize,
                    height: _kDonutSize,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(_kDonutSize, _kDonutSize),
                          painter: _RoundedDonutPainter(
                            data: data,
                            colors: _kDonutColors,
                            touchedIndex: _touchedDonutIndex,
                          ),
                        ),
                        Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: _touchedDonutIndex != null &&
                                    _touchedDonutIndex! < data.length
                                ? Column(
                                    key: ValueKey(_touchedDonutIndex),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${data[_touchedDonutIndex!].percentage.toStringAsFixed(0)}%',
                                        style: GoogleFonts.inter(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: _kDonutColors[
                                              _touchedDonutIndex! %
                                                  _kDonutColors.length],
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        data[_touchedDonutIndex!].type,
                                        style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade500),
                                      ),
                                    ],
                                  )
                                : Column(
                                    key: const ValueKey('total'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$totalPitches',
                                        style: GoogleFonts.inter(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black87,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Tổng sân',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: Colors.grey.shade400),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: data.asMap().entries.map((e) {
                      final i = e.key;
                      final color = _kDonutColors[i % _kDonutColors.length];
                      final isActive = _touchedDonutIndex == i;
                      final pitchCount =
                          (e.value.percentage * totalPitches / 100).round();
                      return GestureDetector(
                        onTap: () => setState(() {
                          _touchedDonutIndex = isActive ? null : i;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isActive
                                ? color.withOpacity(0.09)
                                : Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? color.withOpacity(0.45)
                                  : Colors.grey.shade200,
                              width: 1.5,
                            ),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.18),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? color
                                      : color.withOpacity(0.45),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e.value.type,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isActive
                                        ? color
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Text(
                                '$pitchCount',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isActive ? color : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── PRODUCT SECTION ─────────────────────────────────────────────────────

  Widget _buildProductSection(ProductStatisticsModel data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sản phẩm',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
              Text('Xem tất cả →',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryRed)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniKpi(
                  '${data.totalProducts}',
                  'Tổng sản phẩm',
                  Icons.inventory_2_outlined,
                  const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMiniKpi(
                  _formatNumber(data.totalSold),
                  'Đã bán',
                  Icons.shopping_bag_outlined,
                  _kPositive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Top sản phẩm bán chạy',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87)),
          const SizedBox(height: 10),
          if (data.topProducts.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Chưa có dữ liệu',
                    style: GoogleFonts.inter(color: Colors.grey)),
              ),
            )
          else
            ...data.topProducts.asMap().entries.map(
                (e) => _buildTopProductRow(e.key + 1, e.value)),
          if (data.byCategory.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Phân bố theo danh mục',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            _buildCategoryBars(data.byCategory, data.totalProducts),
          ],
        ],
      ),
    );
  }

  Widget _buildMiniKpi(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductRow(int rank, TopProductModel product) {
    final rankColor = rank == 1
        ? const Color(0xFFFFD700)
        : rank == 2
            ? const Color(0xFFC0C0C0)
            : rank == 3
                ? const Color(0xFFCD7F32)
                : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(color: rankColor, shape: BoxShape.circle),
            child: Center(
              child: Text('$rank',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: rank <= 3 ? Colors.white : Colors.grey.shade600)),
            ),
          ),
          const SizedBox(width: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                ? Image.network(
                    product.imageUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildProductPlaceholder(),
                  )
                : _buildProductPlaceholder(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87),
                    overflow: TextOverflow.ellipsis),
                Text('Đã bán: ${_formatNumber(product.totalSold)}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(
            _formatRevenue(product.totalRevenue),
            style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryRed),
          ),
        ],
      ),
    );
  }

  Widget _buildProductPlaceholder() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.inventory_2_outlined,
          color: Colors.grey.shade400, size: 20),
    );
  }

  Widget _buildCategoryBars(List<ProductCategoryModel> categories, int total) {
    final colors = [
      AppColors.primaryRed,
      const Color(0xFF2563EB),
      _kPositive,
      _kWarning,
      const Color(0xFF8B5CF6),
    ];

    return Column(
      children: categories.asMap().entries.map((e) {
        final color = colors[e.key % colors.length];
        final pct = total > 0 ? e.value.count / total : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(e.value.category,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87)),
                  Text(
                      '${e.value.count} SP · ${(pct * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.toDouble(),
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── ACTIVITY FEED ────────────────────────────────────────────────────────

  Widget _buildActivityFeed(List<RecentBookingModel> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hoạt động gần đây',
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
              Text('Xem tất cả →',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryRed)),
            ],
          ),
          const SizedBox(height: 16),
          if (data.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('Chưa có hoạt động',
                    style: GoogleFonts.inter(color: Colors.grey)),
              ),
            )
          else
            ...data.map((item) => _buildActivityItem(item)),
        ],
      ),
    );
  }

  Widget _buildActivityItem(RecentBookingModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              color: _statusColor(item.status),
              alignment: Alignment.center,
              child: Text(
                item.userInitials,
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(item.userName,
                          style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusPill(item.status),
                  ],
                ),
                const SizedBox(height: 2),
                Text(item.description,
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey.shade500)),
                Text(item.timeAgo,
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final (label, bg, fg) = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  (String, Color, Color) _statusStyle(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return ('Xác nhận', _kPositive.withOpacity(0.12),
            const Color(0xFF16A34A));
      case 'CANCELED':
        return ('Đã hủy', _kNegative.withOpacity(0.12),
            const Color(0xFFDC2626));
      default:
        return ('Chờ xử lý', _kWarning.withOpacity(0.12),
            const Color(0xFFD97706));
    }
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CONFIRMED':
        return _kPositive;
      case 'CANCELED':
        return _kNegative;
      default:
        return _kWarning;
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  List<FlSpot> _revenueToSpots(List<RevenuePointModel> data) {
    if (data.isEmpty) return [];
    return data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble() + 1, e.value.revenue);
    }).toList();
  }

  String _formatRevenue(double value) {
    if (value >= 1000000000) {
      return '${(value / 1000000000).toStringAsFixed(1)} tỷ đ';
    } else if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)} triệu đ';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k đ';
    }
    return '${value.toStringAsFixed(0)} đ';
  }

  String _formatNumber(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }
}

// ─── CUSTOM PAINTERS ──────────────────────────────────────────────────────────

class _RoundedDonutPainter extends CustomPainter {
  final List<PitchTypeModel> data;
  final List<Color> colors;
  final int? touchedIndex;

  const _RoundedDonutPainter({
    required this.data,
    required this.colors,
    this.touchedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - 4;
    const strokeWidth = 20.0;
    const activeStrokeWidth = 26.0;
    final total = data.fold(0.0, (s, e) => s + e.percentage);
    double startAngle = -math.pi / 2;
    const gap = 0.07;

    for (int i = 0; i < data.length; i++) {
      final color = colors[i % colors.length];
      final isActive = touchedIndex == i;
      final sw = isActive ? activeStrokeWidth : strokeWidth;
      final r = outerRadius - sw / 2;
      final sweep = (data[i].percentage / total) * 2 * math.pi - gap;

      if (isActive) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: r),
          startAngle + gap / 2,
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = sw + 10
            ..strokeCap = StrokeCap.round
            ..color = color.withOpacity(0.15),
        );
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        startAngle + gap / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round
          ..color = isActive ? color : color.withOpacity(0.7),
      );

      startAngle += (data[i].percentage / total) * 2 * math.pi;
    }
  }

  @override
  bool shouldRepaint(_RoundedDonutPainter old) =>
      old.touchedIndex != touchedIndex || old.data != data;
}

class _ProgressRingPainter extends CustomPainter {
  final double progress; // 0.0 – 1.0
  final Color color;
  final Color trackColor;

  const _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    const strokeWidth = 5.0;
    const startAngle = -math.pi / 2;

    // Track
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    // Progress arc with rounded caps
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        progress * 2 * math.pi,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.progress != progress || old.color != color;
}