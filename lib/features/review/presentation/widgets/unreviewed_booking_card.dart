import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../pitch/data/models/booking_response_model.dart';
import '../cubit/my_reviews_cubit.dart';
import 'review_form_sheet.dart';

class UnreviewedBookingCard extends StatelessWidget {
  final BookingResponseModel booking;

  const UnreviewedBookingCard({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final dateStr = booking.bookingDate.isNotEmpty
        ? DateFormat('dd/MM/yyyy').format(DateTime.tryParse(booking.bookingDate) ?? DateTime.now())
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Pitch image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: booking.pitchImageUrl != null && booking.pitchImageUrl!.isNotEmpty
                ? Image.network(
                    booking.pitchImageUrl!,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking.pitchName,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (dateStr.isNotEmpty)
                    Text(
                      'Ngày đặt: $dateStr',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => BlocProvider.value(
                        value: context.read<MyReviewsCubit>(),
                        child: ReviewFormSheet(
                          pitchId: booking.pitchId!,
                          pitchName: booking.pitchName,
                        ),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Viết đánh giá',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
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
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: const Color(0xFFF5F5F5),
      child: const Icon(Icons.sports_soccer, color: Color(0xFFCCCCCC), size: 32),
    );
  }
}
