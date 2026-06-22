import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/login/presentation/bloc/auth_cubit.dart';
import '../../../discount/domain/repositories/discount_repository.dart';
import '../../../discount/presentation/cubit/available_vouchers_cubit.dart';
import '../../../discount/presentation/pages/available_vouchers_screen.dart';
import '../cubit/home_state.dart';
import 'shimmer_card.dart';

class HeroBanner extends StatefulWidget {
  final HomeState state;

  const HeroBanner({super.key, required this.state});

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  static const double _bannerHeight = 180;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageScroll);
    _startAutoPlay();
  }

  void _onPageScroll() {
    final p = _pageController.page ?? 0.0;
    final rounded = p.round();
    if (rounded != _currentPage) {
      setState(() => _currentPage = rounded);
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      final discounts = widget.state.activeDiscounts;
      if (discounts.isEmpty) return;
      final next = (_currentPage + 1) % discounts.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        widget.state.discountsStatus == LoadStatus.loading ||
        widget.state.discountsStatus == LoadStatus.initial;
    final discounts = widget.state.activeDiscounts;

    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ShimmerCard(
          width: double.infinity,
          height: _bannerHeight,
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    if (discounts.isEmpty) {
      return _buildStaticBanner(context);
    }

    return Column(
      children: [
        SizedBox(
          height: _bannerHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: discounts.length,
            itemBuilder: (_, index) => RepaintBoundary(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _openVouchers(context),
                child: _buildBannerCard(context, discounts[index]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Dash indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(discounts.length, (i) {
            final isActive = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 24 : 8,
              height: 3,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryRed : AppColors.inactiveDot,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Bấm vào banner -> sheet xác nhận lưu mã vào ví.
  /// Bấm mã ở banner → mở KHO VOUCHER (list mã + khóa theo hạng/điều kiện) để tự lấy,
  /// thay vì lưu trực tiếp — vì hầu hết mã có điều kiện (hạng thành viên, đổi điểm...).
  Future<void> _openVouchers(BuildContext context) async {
    final user = context.read<AuthCubit>().state.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Vui lòng đăng nhập để lấy mã',
            style: GoogleFonts.inter(fontSize: 13)),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (ctx) =>
              AvailableVouchersCubit(repository: ctx.read<DiscountRepository>()),
          child: AvailableVouchersScreen(userId: user.userId),
        ),
      ),
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: const Color(0xFFFFF7F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.hairline, width: 1),
      );

  Widget _buildBannerCard(BuildContext context, discount) {
    final valueText = discount.isPercentage
        ? 'Giảm ${discount.value.toInt()}%'
        : 'Giảm ${discount.value.toStringAsFixed(0)}K';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Eyebrow label
          Text(
            'SPORTSHUB — ƯU ĐÃI',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryRed,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          // Discount value — centrepiece (auto-fit when long)
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valueText,
              maxLines: 1,
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
                height: 1,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Code chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  discount.code,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryRed,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  discount.description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textGrey,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaticBanner(BuildContext context) {
    return Container(
      height: _bannerHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPORTSHUB',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryRed,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Text(
            'Đặt sân thể thao',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Mua đồ · Thi đấu',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }
}
