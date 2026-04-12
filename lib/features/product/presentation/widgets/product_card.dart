import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/product_entity.dart';
import 'sale_badge.dart';

enum ProductCardMode { horizontal, grid }

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final ProductCardMode mode;

  const ProductCard({
    super.key,
    required this.product,
    this.mode = ProductCardMode.grid,
  });

  @override
  Widget build(BuildContext context) {
    return mode == ProductCardMode.grid
        ? _buildGridCard()
        : _buildHorizontalCard();
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

  Widget _buildHorizontalCard() {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: _buildImage(height: 140),
              ),
              if (product.isOnSale) SaleBadge(percent: product.salePercent!),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
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
      return Container(
        width: double.infinity,
        height: height,
        color: const Color(0xFFF0F0F0),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      );
    }
    return Image.network(
      product.imageUrl,
      width: double.infinity,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        width: double.infinity,
        height: height,
        color: const Color(0xFFF0F0F0),
        child: const Icon(Icons.image_not_supported, color: Colors.grey),
      ),
    );
  }

  Widget _buildPriceRow() {
    if (product.isOnSale && product.salePrice != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${product.price.toStringAsFixed(0)}k',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textGrey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '${product.salePrice!.toStringAsFixed(0)}k',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryRed,
            ),
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
    );
  }
}
