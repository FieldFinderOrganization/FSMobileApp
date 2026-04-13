import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../home/presentation/cubit/home_state.dart';
import '../../../home/presentation/widgets/fade_in_section.dart';
import '../../../home/presentation/widgets/section_header.dart';
import '../../../home/presentation/widgets/shimmer_card.dart';
import '../../domain/entities/product_entity.dart';

class TopProductsSection extends StatelessWidget {
  final HomeState state;

  const TopProductsSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final isLoading =
        state.topProductsStatus == LoadStatus.loading ||
        state.topProductsStatus == LoadStatus.initial;

    return FadeInSection(
      delay: const Duration(milliseconds: 200),
      child: Container(
        color: const Color(0xFFFAFAFA),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Bán chạy nhất',
              onSeeAll: null,
              index: '02',
              darkMode: false,
            ),
            if (isLoading)
              _buildShimmer()
            else if (state.topProducts.isEmpty)
              const SizedBox.shrink()
            else
              _buildPodium(context, state.topProducts),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<ProductEntity> products) {
    // Top 5 Podium order: Rank 4 | Rank 2 | Rank 1 | Rank 3 | Rank 5
    final top1 = products.isNotEmpty ? products[0] : null;
    final top2 = products.length > 1 ? products[1] : null;
    final top3 = products.length > 2 ? products[2] : null;
    final top4 = products.length > 3 ? products[3] : null;
    final top5 = products.length > 4 ? products[4] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #4
          if (top4 != null)
            Expanded(
              child: _PodiumBubble(
                product: top4,
                rank: 4,
                columnHeight: 45,
                bubbleSize: 55,
              ),
            ),
          if (top4 != null) const SizedBox(width: 4),

          // #2
          if (top2 != null)
            Expanded(
              child: _PodiumBubble(
                product: top2,
                rank: 2,
                columnHeight: 85,
                bubbleSize: 75,
              ),
            ),
          if (top2 != null) const SizedBox(width: 4),

          // #1 - Center, Tallest
          if (top1 != null)
            Expanded(
              flex: 2,
              child: _PodiumBubble(
                product: top1,
                rank: 1,
                columnHeight: 140,
                bubbleSize: 100,
                isCenter: true,
              ),
            ),
          if (top1 != null) const SizedBox(width: 4),

          // #3
          if (top3 != null)
            Expanded(
              child: _PodiumBubble(
                product: top3,
                rank: 3,
                columnHeight: 85,
                bubbleSize: 75,
              ),
            ),
          if (top3 != null) const SizedBox(width: 4),

          // #5
          if (top5 != null)
            Expanded(
              child: _PodiumBubble(
                product: top5,
                rank: 5,
                columnHeight: 45,
                bubbleSize: 55,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(
          5,
          (i) => Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ShimmerCard(
                width: double.infinity,
                height: i == 2 ? 220 : (i == 1 || i == 3 ? 180 : 140),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Podium bubble ─────────────────────────────────────────────────────────────

class _PodiumBubble extends StatelessWidget {
  final ProductEntity product;
  final int rank;
  final double columnHeight;
  final double bubbleSize;
  final bool isCenter;

  const _PodiumBubble({
    required this.product,
    required this.rank,
    required this.columnHeight,
    required this.bubbleSize,
    this.isCenter = false,
  });

  static const _rankColors = {
    1: Color(0xFFFFD700), // Gold
    2: Color(0xFFC0C0C0), // Silver
    3: Color(0xFFCD7F32), // Bronze
    4: Color(0xFF7B0323), // Deep Red
    5: Color(0xFF607D8B), // Blue Grey
  };

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColors[rank] ?? Colors.grey;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bubble container
        Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Bubble with image
            Container(
              width: bubbleSize,
              height: bubbleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: rankColor, width: isCenter ? 3 : 2),
                boxShadow: [
                  BoxShadow(
                    color: rankColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipOval(
                child: _buildImage(),
              ),
            ),

            // Rank Badge Overlay
            Positioned(
              bottom: -10,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: rankColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  rank.toString(),
                  style: GoogleFonts.inter(
                    fontSize: isCenter ? 12 : 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Product Info (Compact)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            children: [
              Text(
                product.name,
                textAlign: TextAlign.center,
                maxLines: isCenter ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: isCenter ? 11 : 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${product.salePrice?.toStringAsFixed(0) ?? product.price.toStringAsFixed(0)}k',
                style: GoogleFonts.inter(
                  fontSize: isCenter ? 12 : 10,
                  fontWeight: FontWeight.w800,
                  color: rank == 1 ? AppColors.primaryRed : rankColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Podium Column
        Container(
          width: double.infinity,
          height: columnHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                rankColor.withValues(alpha: 0.5),
                rankColor.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (product.imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFFF0F0F0),
        child: Icon(Icons.image, size: bubbleSize * 0.5, color: Colors.grey),
      );
    }
    return Image.network(
      product.imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: const Color(0xFFF0F0F0),
        child: Icon(Icons.image, size: bubbleSize * 0.5, color: Colors.grey),
      ),
    );
  }
}
