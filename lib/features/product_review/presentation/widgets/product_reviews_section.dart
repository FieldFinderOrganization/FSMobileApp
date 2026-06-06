import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/item_review_remote_datasource.dart';
import '../../domain/entities/item_review_entity.dart';

/// Khu hiển thị đánh giá (chỉ đọc) trên trang chi tiết sản phẩm.
class ProductReviewsSection extends StatefulWidget {
  final String productId;

  const ProductReviewsSection({super.key, required this.productId});

  @override
  State<ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<ProductReviewsSection> {
  late Future<List<ItemReviewEntity>> _future;

  @override
  void initState() {
    super.initState();
    final ds = ItemReviewRemoteDataSource(dioClient: context.read<DioClient>());
    _future = ds.getReviewsByProduct(widget.productId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ItemReviewEntity>>(
      future: _future,
      builder: (context, snapshot) {
        // Đang tải → chừa chỗ tối thiểu, không chặn UI
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _wrap(
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primaryRed,
                  ),
                ),
              ),
            ),
          );
        }
        if (snapshot.hasError) {
          return _wrap(
            Text(
              'Không tải được đánh giá',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
            ),
          );
        }

        final reviews = snapshot.data ?? const [];
        if (reviews.isEmpty) {
          return _wrap(
            Text(
              'Chưa có đánh giá nào cho sản phẩm này',
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textGrey),
            ),
          );
        }

        final avg =
            reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

        return _wrap(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      color: Color(0xFFFFC107), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    avg.toStringAsFixed(1),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '(${reviews.length} đánh giá)',
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textGrey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...reviews.map(_buildReviewTile),
            ],
          ),
        );
      },
    );
  }

  Widget _wrap(Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
        const SizedBox(height: 20),
        Text(
          'Đánh giá sản phẩm',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildReviewTile(ItemReviewEntity r) {
    final dateStr = DateFormat('dd/MM/yyyy').format(r.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.userName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) {
              final star = i + 1;
              return Icon(
                star <= r.rating
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: 15,
                color: star <= r.rating
                    ? const Color(0xFFFFC107)
                    : const Color(0xFFCCCCCC),
              );
            }),
          ),
          if (r.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              r.comment,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textDark,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
