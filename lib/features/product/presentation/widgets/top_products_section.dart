import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../home/presentation/cubit/home_state.dart';
import '../../../home/presentation/widgets/fade_in_section.dart';
import '../../../home/presentation/widgets/section_header.dart';
import '../../../home/presentation/widgets/shimmer_card.dart';
import '../../domain/entities/product_entity.dart';
import 'sale_badge.dart';

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
        color: const Color(0xFF111111),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Bán chạy nhất',
              onSeeAll: null,
              index: '02',
              darkMode: true,
            ),
            if (isLoading)
              _buildShimmer()
            else if (state.topProducts.isEmpty)
              const SizedBox.shrink()
            else
              _buildPodium(context, state.topProducts),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPodium(BuildContext context, List<ProductEntity> products) {
    // Podium order: #2 left, #1 center (tallest), #3 right
    final top1 = products.isNotEmpty ? products[0] : null;
    final top2 = products.length > 1 ? products[1] : null;
    final top3 = products.length > 2 ? products[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #2 — left, medium height
          if (top2 != null)
            Expanded(
              child: _PodiumCard(product: top2, rank: 2, imageHeight: 110),
            ),
          if (top2 != null) const SizedBox(width: 8),

          // #1 — center, tallest
          if (top1 != null)
            Expanded(
              flex: 2,
              child: _PodiumCard(product: top1, rank: 1, imageHeight: 160),
            ),

          if (top3 != null) const SizedBox(width: 8),
          // #3 — right, shortest
          if (top3 != null)
            Expanded(
              child: _PodiumCard(product: top3, rank: 3, imageHeight: 90),
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
        children: [
          Expanded(
            child: ShimmerCard(
              width: double.infinity,
              height: 200,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ShimmerCard(
              width: double.infinity,
              height: 260,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ShimmerCard(
              width: double.infinity,
              height: 170,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Podium card ───────────────────────────────────────────────────────────────

class _PodiumCard extends StatelessWidget {
  final ProductEntity product;
  final int rank;
  final double imageHeight;

  const _PodiumCard({
    required this.product,
    required this.rank,
    required this.imageHeight,
  });

  static const _rankColors = {
    1: Color(0xFFD4A017), // gold
    2: Color(0xFFAAAAAA), // silver
    3: Color(0xFFCD7F32), // bronze
  };

  @override
  Widget build(BuildContext context) {
    final rankColor = _rankColors[rank] ?? Colors.white54;
    final isTop1 = rank == 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image area
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
                child: Stack(
                  children: [
                    _buildImage(),
                    if (product.isOnSale)
                      SaleBadge(percent: product.salePercent!),
                  ],
                ),
              ),
              // Text area
              Padding(
                padding: EdgeInsets.all(isTop1 ? 10 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: isTop1 ? 12 : 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    _buildPrice(isTop1),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Podium rank block
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: isTop1 ? 10 : 7),
          decoration: BoxDecoration(
            color: rankColor.withValues(alpha: 0.15),
            border: Border(
              bottom: BorderSide(color: rankColor, width: isTop1 ? 2 : 1),
            ),
          ),
          child: Text(
            '#$rank',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isTop1 ? 14 : 12,
              fontWeight: FontWeight.w800,
              color: rankColor,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    if (product.imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        height: imageHeight,
        color: const Color(0xFFF0F0F0),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return Image.network(
      product.imageUrl,
      width: double.infinity,
      height: imageHeight,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: double.infinity,
        height: imageHeight,
        color: const Color(0xFFF0F0F0),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }

  Widget _buildPrice(bool large) {
    if (product.isOnSale && product.salePrice != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${product.price.toStringAsFixed(0)}k',
            style: GoogleFonts.inter(
              fontSize: large ? 10 : 9,
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '${product.salePrice!.toStringAsFixed(0)}k',
            style: GoogleFonts.inter(
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF7B0323),
            ),
          ),
        ],
      );
    }
    return Text(
      '${product.price.toStringAsFixed(0)}k',
      style: GoogleFonts.inter(
        fontSize: large ? 13 : 11,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1A1A1A),
      ),
    );
  }
}
