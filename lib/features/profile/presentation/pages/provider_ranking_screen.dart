import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../data/models/pitch_ranking_model.dart';
import '../../domain/repositories/provider_repository.dart';
import '../cubit/provider_ranking_cubit.dart';
import '../widgets/ranked_progress_bar.dart';

enum RankingTab { mostBooked, topRated, topRevenue }

/// Bảng xếp hạng sân của provider: đặt nhiều nhất / đánh giá cao nhất / doanh thu cao nhất.
class ProviderRankingScreen extends StatelessWidget {
  final String providerId;
  final RankingTab initialTab;

  const ProviderRankingScreen({
    super.key,
    required this.providerId,
    this.initialTab = RankingTab.mostBooked,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ProviderRankingCubit(
        repository: context.read<ProviderRepository>(),
        providerId: providerId,
      )..load(),
      child: _RankingView(initialTab: initialTab),
    );
  }
}

class _RankingView extends StatelessWidget {
  final RankingTab initialTab;
  const _RankingView({required this.initialTab});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.index,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FB),
        appBar: AppBar(
          title: Text(
            'Xếp hạng sân',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              color: Colors.white,
              child: TabBar(
                labelColor: AppColors.primaryRed,
                unselectedLabelColor: AppColors.textGrey,
                indicatorColor: AppColors.primaryRed,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle:
                    GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                unselectedLabelStyle:
                    GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: const [
                  Tab(text: 'Đặt nhiều'),
                  Tab(text: 'Đánh giá cao'),
                  Tab(text: 'Doanh thu'),
                ],
              ),
            ),
          ),
        ),
        body: BlocBuilder<ProviderRankingCubit, ProviderRankingState>(
          builder: (context, state) {
            if (state is ProviderRankingLoading ||
                state is ProviderRankingInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryRed),
              );
            }
            if (state is ProviderRankingError) {
              return _errorView(context, state.message);
            }
            final pitches = (state as ProviderRankingLoaded).pitches;
            return TabBarView(
              children: [
                _MostBookedTab(pitches: pitches),
                _TopRatedTab(pitches: pitches),
                _TopRevenueTab(pitches: pitches),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _errorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: AppColors.textGrey, size: 40),
          const SizedBox(height: 8),
          Text(message, style: GoogleFonts.inter(color: AppColors.textGrey)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.read<ProviderRankingCubit>().load(),
            child: const Text('Thử lại',
                style: TextStyle(color: AppColors.primaryRed)),
          ),
        ],
      ),
    );
  }
}

// ─── Đặt nhiều nhất ─────────────────────────────────────────────────────────────
class _MostBookedTab extends StatelessWidget {
  final List<PitchRankingModel> pitches;
  const _MostBookedTab({required this.pitches});

  @override
  Widget build(BuildContext context) {
    final list = pitches.where((p) => p.bookingCount > 0).toList()
      ..sort((a, b) => b.bookingCount.compareTo(a.bookingCount));
    if (list.isEmpty) return const _EmptyRanking(text: 'Chưa có lượt đặt nào');

    final maxVal = list.first.bookingCount;
    return _RankingList(
      itemCount: list.length,
      builder: (i) {
        final p = list[i];
        return RankedProgressBar(
          rank: i + 1,
          label: p.pitchName,
          count: '${p.bookingCount} lượt',
          ratio: maxVal == 0 ? 0 : p.bookingCount / maxVal,
          color: kRankPalette[i % kRankPalette.length],
          isLast: i == list.length - 1,
        );
      },
    );
  }
}

// ─── Đánh giá cao nhất ──────────────────────────────────────────────────────────
class _TopRatedTab extends StatelessWidget {
  final List<PitchRankingModel> pitches;
  const _TopRatedTab({required this.pitches});

  @override
  Widget build(BuildContext context) {
    // Chỉ xếp hạng sân đã có đánh giá; tie-break theo số lượt đánh giá.
    final list = pitches.where((p) => p.reviewCount > 0).toList()
      ..sort((a, b) {
        final cmp = b.avgRating.compareTo(a.avgRating);
        return cmp != 0 ? cmp : b.reviewCount.compareTo(a.reviewCount);
      });
    if (list.isEmpty) return const _EmptyRanking(text: 'Chưa có đánh giá nào');

    return _RankingList(
      itemCount: list.length,
      builder: (i) {
        final p = list[i];
        return RankedProgressBar(
          rank: i + 1,
          label: p.pitchName,
          count: '★ ${p.avgRating.toStringAsFixed(1)} (${p.reviewCount})',
          ratio: (p.avgRating / 5).clamp(0.0, 1.0),
          color: kRankPalette[i % kRankPalette.length],
          isLast: i == list.length - 1,
        );
      },
    );
  }
}

// ─── Doanh thu cao nhất ─────────────────────────────────────────────────────────
class _TopRevenueTab extends StatelessWidget {
  final List<PitchRankingModel> pitches;
  const _TopRevenueTab({required this.pitches});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.compactCurrency(
        locale: 'vi_VN', symbol: '₫', decimalDigits: 0);
    final list = pitches.where((p) => p.totalRevenue > 0).toList()
      ..sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    if (list.isEmpty) return const _EmptyRanking(text: 'Chưa có doanh thu');

    final maxVal = list.first.totalRevenue;
    return _RankingList(
      itemCount: list.length,
      builder: (i) {
        final p = list[i];
        return RankedProgressBar(
          rank: i + 1,
          label: p.pitchName,
          count: fmt.format(p.totalRevenue),
          ratio: maxVal == 0 ? 0 : p.totalRevenue / maxVal,
          color: kRankPalette[i % kRankPalette.length],
          isLast: i == list.length - 1,
        );
      },
    );
  }
}

// ─── Shared list shell ──────────────────────────────────────────────────────────
class _RankingList extends StatelessWidget {
  final int itemCount;
  final Widget Function(int index) builder;
  const _RankingList({required this.itemCount, required this.builder});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 20, 16, 20 + MediaQuery.of(context).padding.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: List.generate(itemCount, builder),
        ),
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  final String text;
  const _EmptyRanking({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.leaderboard_outlined,
              size: 48, color: AppColors.textGrey),
          const SizedBox(height: 12),
          Text(text, style: GoogleFonts.inter(color: AppColors.textGrey)),
        ],
      ),
    );
  }
}
