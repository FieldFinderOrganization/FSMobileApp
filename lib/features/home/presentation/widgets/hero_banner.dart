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

class _HeroBannerState extends State<HeroBanner>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _shimmerCtrl;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageScroll);
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
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
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Widget _shimmerText(Widget child) {
    return AnimatedBuilder(
      animation: _shimmerCtrl,
      builder: (_, _) {
        final t = _shimmerCtrl.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment(-1.5 + t * 3.0, -0.4),
              end: Alignment(-0.5 + t * 3.0, 0.4),
              colors: const [
                Colors.transparent,
                Colors.white24,
                Colors.transparent,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(rect);
          },
          child: child,
        );
      },
    );
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
                    ? AppColors.accentGold
                    : Colors.white.withValues(alpha: 0.35),
              );
            }),
          ),
        ),
        // Gold hairline separating hero from body
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accentGold.withValues(alpha: 0),
                  AppColors.accentGold.withValues(alpha: 0.6),
                  AppColors.accentGold.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(BuildContext context, discount) {
    final valueText = discount.isPercentage
        ? '${discount.value.toInt()}%'
        : '${discount.value.toStringAsFixed(0)}K';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Fintech-grade midnight gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                AppColors.midnightDeep,
                AppColors.midnightMid,
                AppColors.midnightSoft,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Champagne radial accent — soft warmth
        Positioned(
          right: -120,
          top: -60,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.champagne.withValues(alpha: 0.18),
                  AppColors.champagne.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),

        // Champagne vertical accent
        Positioned(
          left: 24,
          top: 36,
          bottom: 50,
          child: Container(
            width: 1,
            color: AppColors.champagne.withValues(alpha: 0.55),
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
                  color: AppColors.champagne,
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
                  color: AppColors.warmIvory.withValues(alpha: 0.55),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              // Oversized value — centrepiece (auto-fit when long)
              _shimmerText(
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    valueText,
                    maxLines: 1,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: AppColors.warmIvory,
                      height: 0.9,
                      letterSpacing: -2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Champagne rule
              Container(
                width: 48,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.champagne,
                      AppColors.champagne.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Code
              Text(
                discount.code,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.warmIvory,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                discount.description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.warmIvory.withValues(alpha: 0.45),
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
                  AppColors.midnightDeep,
                  AppColors.midnightMid,
                  AppColors.midnightSoft,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          // Champagne radial accent
          Positioned(
            right: -120,
            top: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.champagne.withValues(alpha: 0.18),
                    AppColors.champagne.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          // Champagne vertical accent
          Positioned(
            left: 24,
            top: 36,
            bottom: 50,
            child: Container(
              width: 1,
              color: AppColors.champagne.withValues(alpha: 0.55),
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
                    color: AppColors.champagne,
                    letterSpacing: 2.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'ĐẶT SÂN',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    color: AppColors.warmIvory,
                    height: 0.95,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'THỂ THAO.',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 58,
                    fontWeight: FontWeight.w900,
                    color: AppColors.warmIvory,
                    height: 0.95,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 48,
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.champagne,
                        AppColors.champagne.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'MUA ĐỒ · THI ĐẤU',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.warmIvory.withValues(alpha: 0.45),
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
