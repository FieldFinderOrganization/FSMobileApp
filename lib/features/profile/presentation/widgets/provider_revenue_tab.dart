import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../pitch/data/repositories/booking_repository_impl.dart';
import '../cubit/provider_cubit.dart';
import '../cubit/provider_revenue_cubit.dart';
import '../pages/partner_insights_screen.dart';

class ProviderRevenueTab extends StatelessWidget {
  final UserEntity user;
  const ProviderRevenueTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderCubit, ProviderState>(
      builder: (context, providerState) {
        if (providerState is! ProviderLoaded) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        }
        return BlocProvider(
          create: (_) => ProviderRevenueCubit(
            repository: context.read<BookingRepository>(),
            providerId: providerState.provider.providerId,
          )..loadRevenue(),
          child: const _ProviderRevenueBody(),
        );
      },
    );
  }
}

class _ProviderRevenueBody extends StatelessWidget {
  const _ProviderRevenueBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderRevenueCubit, ProviderRevenueState>(
      builder: (context, state) {
        if (state is ProviderRevenueLoading) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryRed));
        }
        if (state is ProviderRevenueError) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: AppColors.textGrey, size: 40),
                const SizedBox(height: 8),
                Text(state.message, style: GoogleFonts.inter(color: AppColors.textGrey)),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<ProviderRevenueCubit>().loadRevenue(),
                  child: const Text('Thử lại', style: TextStyle(color: AppColors.primaryRed)),
                ),
              ],
            ),
          );
        }
        if (state is ProviderRevenueLoaded) {
          return Column(
            children: [
              _TimeRangeSelector(selectedRange: state.selectedRange),
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primaryRed,
                  onRefresh: () => context.read<ProviderRevenueCubit>().loadRevenue(),
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryHeader(state),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartnerInsightsScreen(
                              bookings: state.allBookings,
                              initialTab: InsightsTab.revenue,
                            ),
                          ),
                        ),
                        child: _StatCard(
                          icon: Icons.attach_money_rounded,
                          iconColor: Colors.green,
                          label: 'Tổng doanh thu',
                          value: NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: '₫',
                            decimalDigits: 0,
                          ).format(state.stats.totalRevenue),
                          subtitle: 'Bấm để xem chi tiết',
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartnerInsightsScreen(
                              bookings: state.allBookings,
                              initialTab: InsightsTab.bookings,
                            ),
                          ),
                        ),
                        child: _StatCard(
                          icon: Icons.receipt_long_outlined,
                          iconColor: Colors.blue,
                          label: 'Tổng số đơn',
                          value: '${state.stats.totalBookings} đơn',
                          subtitle: 'Bấm để phân tích lượng đặt',
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartnerInsightsScreen(
                              bookings: state.allBookings,
                              initialTab: InsightsTab.pitches,
                            ),
                          ),
                        ),
                        child: _StatCard(
                          icon: Icons.sports_soccer,
                          iconColor: AppColors.primaryRed,
                          label: 'Sân được đặt nhiều nhất',
                          value: state.stats.mostBookedPitch,
                          subtitle: '${state.stats.mostBookedPitchCount} lần đặt. Bấm để xem chi tiết',
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartnerInsightsScreen(
                              bookings: state.allBookings,
                              initialTab: InsightsTab.customers,
                            ),
                          ),
                        ),
                        child: _StatCard(
                          icon: Icons.person_outline,
                          iconColor: Colors.orange,
                          label: 'Khách hàng hàng đầu',
                          value: state.stats.topCustomer,
                          subtitle: '${state.stats.topCustomerCount} đơn đặt. Bấm để xem bảng xếp hạng',
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartnerInsightsScreen(
                              bookings: state.allBookings,
                              initialTab: InsightsTab.revenue,
                            ),
                          ),
                        ),
                        child: _StatCard(
                          icon: Icons.trending_up_rounded,
                          iconColor: Colors.purple,
                          label: 'Sân doanh thu cao nhất',
                          value: state.stats.highestRevenuePitch,
                          subtitle: NumberFormat.currency(
                            locale: 'vi_VN',
                            symbol: '₫',
                            decimalDigits: 0,
                          ).format(state.stats.highestRevenuePitchAmount),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _ExportButton(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSummaryHeader(ProviderRevenueLoaded state) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryRed, Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thống kê doanh thu',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                Text(
                  _rangeText(state.selectedRange),
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _rangeText(RevenueTimeRange range) {
    switch (range) {
      case RevenueTimeRange.thisWeek:
        return 'Tuần này';
      case RevenueTimeRange.thisMonth:
        return 'Tháng ${DateTime.now().month}/${DateTime.now().year}';
      case RevenueTimeRange.allTime:
        return 'Toàn bộ thời gian';
    }
  }
}

class _TimeRangeSelector extends StatelessWidget {
  final RevenueTimeRange selectedRange;
  const _TimeRangeSelector({required this.selectedRange});

  static const _ranges = [
    (RevenueTimeRange.thisWeek, 'Tuần này'),
    (RevenueTimeRange.thisMonth, 'Tháng này'),
    (RevenueTimeRange.allTime, 'Tất cả'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: _ranges.map((entry) {
          final isSelected = entry.$1 == selectedRange;
          return Expanded(
            child: GestureDetector(
              onTap: () => context.read<ProviderRevenueCubit>().changeTimeRange(entry.$1),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryRed : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  entry.$2,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textDark,
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textGrey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        icon: const Icon(Icons.picture_as_pdf_outlined),
        label: Text(
          'Xuất báo cáo PDF',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        onPressed: () => context.read<ProviderRevenueCubit>().exportPdf(context),
      ),
    );
  }
}
