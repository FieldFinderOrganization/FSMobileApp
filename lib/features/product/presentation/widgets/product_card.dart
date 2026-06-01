import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/image_url.dart';
import '../../domain/entities/product_entity.dart';
import '../../../home/presentation/widgets/tilt_card.dart';
import '../pages/product_detail_screen.dart';
import 'sale_badge.dart';

enum ProductCardMode { horizontal, grid, featured, overlay }

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final ProductCardMode mode;
  final double overlayHeight;

  const ProductCard({
    super.key,
    required this.product,
    this.mode = ProductCardMode.grid,
    this.overlayHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    Widget card;
    switch (mode) {
      case ProductCardMode.grid:
        card = _buildGridCard();
        break;
      case ProductCardMode.horizontal:
        card = _buildHorizontalCard();
        break;
      case ProductCardMode.featured:
        card = _buildFeaturedCard();
        break;
      case ProductCardMode.overlay:
        card = _buildOverlayCard();
        break;
    }
    return TiltCard(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: product.id),
        ),
      ),
      child: card,
    );
  }

  Widget _buildGridCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildImage(height: 130),
              ),
              if (product.isOnSale) SaleBadge(percent: product.salePercent!),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                _buildMeta(),
                const SizedBox(height: 6),
                _buildPriceRow(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Shopee/Lazada-style: nền trắng, ảnh vuông, tên 2 dòng, giá đỏ nổi bật,
  // dòng "đã bán" mờ. Chiều cao cố định gọn để không overflow trong list.
  Widget _buildHorizontalCard() {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(10),
                ),
                child: _buildImage(height: 150), // width 150 → ảnh vuông
              ),
              if (product.isOnSale) SaleBadge(percent: product.salePercent!),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _buildHorizontalPriceRow(),
                if (product.totalSold > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Đã bán ${product.totalSold}',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Giá đỏ nổi bật, giá gốc gạch ngang nằm cạnh (kiểu Shopee).
  Widget _buildHorizontalPriceRow() {
    if (product.isOnSale && product.salePrice != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Text(
              '${product.salePrice!.toStringAsFixed(0)}k',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.primaryRed,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${product.price.toStringAsFixed(0)}k',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textGrey,
              decoration: TextDecoration.lineThrough,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    return Text(
      '${product.price.toStringAsFixed(0)}k',
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFeaturedCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth * 0.40;
        return Container(
          constraints: const BoxConstraints(minHeight: 160),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Left: image — 40% width
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                  child: SizedBox(
                    width: imageWidth,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildImage(height: 180), // height is hint here, StackFit.expand takes over
                        if (product.isOnSale)
                          SaleBadge(percent: product.salePercent!),
                      ],
                    ),
                  ),
                ),
                // Right: text content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Nổi bật',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryRed,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product.name,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        _buildMeta(),
                        const SizedBox(height: 8),
                        _buildPriceRow(),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 32,
                          child: OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primaryRed,
                              side: const BorderSide(
                                color: AppColors.primaryRed,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Xem ngay',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverlayCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: overlayHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh full-bleed
            _buildImage(height: overlayHeight),

            // Gradient từ trong suốt → đen phía dưới
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    Color(0x88000000),
                    Color(0xEE000000),
                  ],
                  stops: [0.0, 0.38, 0.65, 1.0],
                ),
              ),
            ),

            // Sale badge góc trên phải
            if (product.isOnSale) SaleBadge(percent: product.salePercent!),

            // Nội dung phía dưới
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (product.brand.isNotEmpty)
                      Text(
                        product.brand.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 3),
                    Text(
                      product.name,
                      style: GoogleFonts.inter(
                        fontSize: overlayHeight > 240 ? 15 : 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _buildOverlayPriceRow(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayPriceRow() {
    if (product.isOnSale && product.salePrice != null) {
      // Dùng Column để tránh overflow khi card nhỏ (bento 160 / 215)
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${product.price.toStringAsFixed(0)}k',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: Colors.white54,
              decoration: TextDecoration.lineThrough,
              decorationColor: Colors.white54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryRed,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              '${product.salePrice!.toStringAsFixed(0)}k',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return Text(
      '${product.price.toStringAsFixed(0)}k',
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Hiển thị brand · sex (chỉ render phần có giá trị)
  Widget _buildMeta() {
    final parts = <String>[
      if (product.brand.isNotEmpty) product.brand,
      if (product.sex.isNotEmpty) product.sex,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Text(
      parts.join(' · '),
      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildImage({required double height}) {
    if (product.imageUrl.isEmpty) {
      return _imagePlaceholder(width: double.infinity, height: height);
    }
    return CachedNetworkImage(
      imageUrl: ImageUrl.thumbnail(product.imageUrl, width: 400),
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      memCacheWidth: 400,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (_, __) =>
          _imageShimmer(width: double.infinity, height: height),
      errorWidget: (_, __, ___) =>
          _imagePlaceholder(width: double.infinity, height: height),
    );
  }

  Widget _imagePlaceholder({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF0F0F0),
      child: const Icon(Icons.image_not_supported_outlined,
          color: Color(0xFFCCCCCC), size: 32),
    );
  }

  Widget _imageShimmer({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFFF0F0F0),
      child: const _ShimmerBox(),
    );
  }

  Widget _buildPriceRow() {
    if (product.isOnSale && product.salePrice != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${product.price.toStringAsFixed(0)}k',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textGrey,
              decoration: TextDecoration.lineThrough,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '${product.salePrice!.toStringAsFixed(0)}k',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryRed,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      );
    }
    return Text(
      '${product.price.toStringAsFixed(0)}k',
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ── Shimmer đơn giản không cần package bên ngoài ─────────────────────────────
class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox();

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(color: const Color(0xFFE0E0E0)),
    );
  }
}
