import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/my_product_reviews_cubit.dart';
import '../cubit/my_product_reviews_state.dart';

class ProductReviewFormSheet extends StatefulWidget {
  final int productId;
  final String productName;
  // Nếu chỉnh sửa, truyền giá trị hiện có
  final String? reviewId;
  final int initialRating;
  final String initialComment;

  const ProductReviewFormSheet({
    super.key,
    required this.productId,
    required this.productName,
    this.reviewId,
    this.initialRating = 5,
    this.initialComment = '',
  });

  @override
  State<ProductReviewFormSheet> createState() => _ProductReviewFormSheetState();
}

class _ProductReviewFormSheetState extends State<ProductReviewFormSheet> {
  late int _rating;
  late TextEditingController _commentController;

  late ScaffoldMessengerState _messenger;
  late NavigatorState _navigator;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _commentController = TextEditingController(text: widget.initialComment);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messenger = ScaffoldMessenger.of(context);
    _navigator = Navigator.of(context);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập nhận xét')),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    final cubit = context.read<MyProductReviewsCubit>();
    if (widget.reviewId != null) {
      cubit.editReview(
        reviewId: widget.reviewId!,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
    } else {
      cubit.submitReview(
        productId: widget.productId,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MyProductReviewsCubit, MyProductReviewsState>(
      listener: (context, state) {
        if (!mounted) return;
        if (state is MyProductReviewsActionSuccess) {
          _navigator.pop();
          _messenger.showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is MyProductReviewsActionError) {
          _messenger.showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${state.message}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).viewPadding.bottom +
              24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.reviewId != null ? 'Chỉnh sửa đánh giá' : 'Viết đánh giá',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.productName,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            // Star rating
            Text(
              'Đánh giá',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _rating = star);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      size: 36,
                      color: star <= _rating
                          ? const Color(0xFFFFC107)
                          : const Color(0xFFCCCCCC),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),
            Text(
              'Nhận xét',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
              decoration: InputDecoration(
                hintText: 'Chia sẻ trải nghiệm của bạn về sản phẩm này...',
                hintStyle:
                    GoogleFonts.inter(fontSize: 14, color: AppColors.textGrey),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primaryRed, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(14),
              ),
            ),
            const SizedBox(height: 16),
            BlocBuilder<MyProductReviewsCubit, MyProductReviewsState>(
              builder: (context, state) {
                final isLoading = state is MyProductReviewsSubmitting;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Gửi đánh giá',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
