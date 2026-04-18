import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../pitch/data/datasources/review_remote_datasource.dart';
import '../../../pitch/data/models/review_model.dart';

class PitchReviewsSheet extends StatelessWidget {
  final String pitchId;
  final String pitchName;

  const PitchReviewsSheet({
    super.key,
    required this.pitchId,
    required this.pitchName,
  });

  @override
  Widget build(BuildContext context) {
    final datasource = ReviewRemoteDatasource(context.read<DioClient>().dio);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 20, color: AppColors.primaryRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đánh giá sân',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            pitchName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close_rounded, color: AppColors.textGrey),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              // Content
              Expanded(
                child: FutureBuilder<List<ReviewModel>>(
                  future: datasource.fetchReviewsByPitch(pitchId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primaryRed),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Không thể tải đánh giá',
                          style: GoogleFonts.inter(color: AppColors.textGrey),
                        ),
                      );
                    }
                    final reviews = snapshot.data ?? [];
                    if (reviews.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_outline_rounded, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text(
                              'Sân này chưa có đánh giá nào',
                              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
                            ),
                          ],
                        ),
                      );
                    }

                    // Tính trung bình
                    final avg = reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        // Summary bar
                        _buildSummaryBar(reviews, avg),
                        const SizedBox(height: 16),
                        ...reviews.map((r) => _buildReviewCard(r)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryBar(List<ReviewModel> reviews, double avg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: GoogleFonts.inter(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return Icon(
                    star <= avg.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14,
                    color: const Color(0xFFFFC107),
                  );
                }),
              ),
              const SizedBox(height: 2),
              Text(
                '${reviews.length} đánh giá',
                style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(child: _buildRatingBars(reviews)),
        ],
      ),
    );
  }

  Widget _buildRatingBars(List<ReviewModel> reviews) {
    final counts = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in reviews) {
      counts[r.rating] = (counts[r.rating] ?? 0) + 1;
    }
    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = counts[star] ?? 0;
        final fraction = reviews.isEmpty ? 0.0 : count / reviews.length;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text('$star', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey)),
              const SizedBox(width: 4),
              const Icon(Icons.star_rounded, size: 11, color: Color(0xFFFFC107)),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: fraction,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFEEEEEE),
                    color: const Color(0xFFFFC107),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              SizedBox(
                width: 18,
                child: Text('$count', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey), textAlign: TextAlign.end),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewCard(ReviewModel review) {
    final dateStr = DateFormat('dd/MM/yyyy').format(review.createdAt);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryRed.withValues(alpha: 0.1),
                backgroundImage: review.userImageUrl != null && review.userImageUrl!.isNotEmpty
                    ? NetworkImage(review.userImageUrl!)
                    : null,
                child: review.userImageUrl == null || review.userImageUrl!.isEmpty
                    ? Text(
                        review.userName.isNotEmpty ? review.userName[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primaryRed),
                      )
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.userName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    Text(dateStr, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textGrey)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return Icon(
                    star <= review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 14,
                    color: star <= review.rating ? const Color(0xFFFFC107) : const Color(0xFFCCCCCC),
                  );
                }),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(review.comment, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark, height: 1.5)),
          ],
        ],
      ),
    );
  }
}
