import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
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
      return const ShimmerCard(
        width: double.infinity,
        height: 340,
        borderRadius: BorderRadius.zero,
      );
    }

    if (discounts.isEmpty) {
      return _buildStaticBanner(context);
    }

    return Stack(
      children: [
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _pageController,
            itemCount: discounts.length,
            itemBuilder: (_, index) => RepaintBoundary(
              child: _buildBannerCard(context, discounts[index]),
            ),
          ),
        ),
        // Dash indicators — inside card, bottom-left
        Positioned(
          bottom: 20,
          left: 24,
          child: Row(
            children: List.generate(discounts.length, (i) {
              final isActive = i == _currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                margin: const EdgeInsets.only(right: 5),
                width: isActive ? 28 : 8,
                height: 2,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.35),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(BuildContext context, discount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final valueText = discount.isPercentage
        ? '${discount.value.toInt()}%'
        : '${discount.value.toStringAsFixed(0)}K';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Deep dark gradient — fashion brand base
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color(0xFF1A0008),
                Color(0xFF2D000F),
                Color(0xFF0A0A0A),
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Oversized discount value as background typography element
        Positioned(
          right: -12,
          top: 20,
          child: Text(
            valueText,
            style: GoogleFonts.playfairDisplay(
              fontSize: screenWidth * 0.38,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryRed.withValues(alpha: 0.12),
              height: 1,
            ),
          ),
        ),

        // Thin vertical accent line
        Positioned(
          left: 24,
          top: 36,
          bottom: 50,
          child: Container(
            width: 1,
            color: AppColors.primaryRed.withValues(alpha: 0.6),
          ),
        ),

        // Main content
        Positioned(
          left: 40,
          right: 24,
          top: 36,
          bottom: 50,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow label
              Text(
                'FIELDFINDER — ƯU ĐÃI',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryRed,
                  letterSpacing: 2.5,
                ),
              ),
              const Spacer(),
              // Discount label small
              Text(
                discount.isPercentage ? 'GIẢM ĐẾN' : 'TIẾT KIỆM',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white54,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              // Oversized value — centrepiece
              Text(
                valueText,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 72,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 0.9,
                  letterSpacing: -2,
                ),
              ),
              const SizedBox(height: 12),
              // Thin rule
              Container(
                width: 48,
                height: 1,
                color: Colors.white24,
              ),
              const SizedBox(height: 12),
              // Code
              Text(
                discount.code,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                discount.description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white38,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaticBanner(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 340,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFF1A0008),
                  Color(0xFF2D000F),
                  Color(0xFF0A0A0A),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Huge background text
          Positioned(
            right: -8,
            top: 16,
            child: Text(
              'FF',
              style: GoogleFonts.playfairDisplay(
                fontSize: screenWidth * 0.55,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryRed.withValues(alpha: 0.08),
                height: 1,
              ),
            ),
          ),
          // Thin vertical line
          Positioned(
            left: 24,
            top: 36,
            bottom: 50,
            child: Container(
              width: 1,
              color: AppColors.primaryRed.withValues(alpha: 0.6),
            ),
          ),
          Positioned(
            left: 40,
            right: 24,
            top: 36,
            bottom: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FIELDFINDER',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryRed,
                    letterSpacing: 2.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'ĐẶT SÂN',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 0.95,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'THỂ THAO.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 0.95,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Container(width: 48, height: 1, color: Colors.white24),
                const SizedBox(height: 16),
                Text(
                  'MUA ĐỒ · THI ĐẤU',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white38,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
