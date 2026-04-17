import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../product/presentation/pages/product_detail_screen.dart';

class AiProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const AiProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final name = product['name'] as String? ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0;
    final salePrice = (product['salePrice'] as num?)?.toDouble();
    final imageUrl = product['imageUrl'] as String? ?? '';
    final category = product['categoryName'] as String? ?? '';

    final displayPrice = salePrice != null && salePrice < price ? salePrice : price;
    final hasSale = salePrice != null && salePrice < price;
    final formatter = NumberFormat('#,###', 'vi_VN');

    const double cardWidth = 150;
    const double imageHeight = 120;
    const double nameSlotHeight = 34; // vừa đủ 2 dòng với fontSize 12, height 1.3
    const double cardHeight = 250;

    final rawId = product['id'] ?? product['productId'];
    final productId = rawId?.toString();

    return GestureDetector(
      onTap: (productId == null || productId.isEmpty)
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(productId: productId),
                ),
              );
            },
      child: Container(
      width: cardWidth,
      height: cardHeight,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholder(imageHeight),
                  )
                : _placeholder(imageHeight),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 14,
                    child: Text(
                      category,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: nameSlotHeight,
                    child: Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${formatter.format(displayPrice)}đ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC2626),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(
                    height: 14,
                    child: hasSale
                        ? Text(
                            '${formatter.format(price)}đ',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _placeholder(double height) => Container(
        height: height,
        color: const Color(0xFFF3F4F6),
        child: const Center(
          child: Icon(Icons.image_outlined, color: Colors.grey, size: 32),
        ),
      );
}
