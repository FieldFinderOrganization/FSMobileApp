import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../pitch/data/datasources/booking_remote_datasource.dart';
import '../../../pitch/data/models/booking_response_model.dart';
import '../../../pitch/domain/entities/review_entity.dart';
import '../../data/repositories/review_repository_impl.dart';
import 'my_reviews_state.dart';

class MyReviewsCubit extends Cubit<MyReviewsState> {
  final ReviewRepositoryImpl reviewRepository;
  final BookingRemoteDataSource bookingDataSource;
  final String userId;

  MyReviewsCubit({
    required this.reviewRepository,
    required this.bookingDataSource,
    required this.userId,
  }) : super(MyReviewsInitial());

  Future<void> load() async {
    emit(MyReviewsLoading());
    try {
      final reviews = await reviewRepository.getReviewsByUser(userId);
      final allBookings = await bookingDataSource.getBookingsByUser(userId);

      final reviewedPitchIds = reviews.map((r) => r.pitchId).toSet();

      // Deduplicate: 1 card per pitch (first CONFIRMED booking per pitchId)
      final seen = <String>{};
      final unreviewedBookings = <BookingResponseModel>[];
      for (final b in allBookings) {
        if (b.status == 'CONFIRMED' &&
            b.pitchId != null &&
            b.pitchId!.isNotEmpty &&
            !reviewedPitchIds.contains(b.pitchId) &&
            seen.add(b.pitchId!)) {
          unreviewedBookings.add(b);
        }
      }

      emit(MyReviewsLoaded(
        reviews: reviews,
        unreviewedBookings: unreviewedBookings,
      ));
    } catch (e) {
      emit(MyReviewsError(e.toString()));
    }
  }

  Future<void> submitReview({
    required String pitchId,
    required int rating,
    required String comment,
  }) async {
    emit(MyReviewsSubmitting());
    ReviewEntity created;
    try {
      created = await reviewRepository.addReview(
        pitchId: pitchId,
        userId: userId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      emit(MyReviewsActionError(e.toString()));
      return;
    }
    emit(MyReviewsActionSuccess(_submitMessage(created)));
    await load();
  }

  /// Thông báo theo kết quả kiểm duyệt: bị auto từ chối / đang chờ duyệt / đã duyệt.
  String _submitMessage(ReviewEntity review) {
    if (review.isRejected) {
      final reason = review.moderationReason?.trim();
      return reason != null && reason.isNotEmpty
          ? 'Đánh giá bị từ chối: $reason'
          : 'Đánh giá bị từ chối do vi phạm nội dung.';
    }
    if (review.isPending) {
      return 'Đã gửi đánh giá, đang chờ kiểm duyệt.';
    }
    return 'Đánh giá đã được gửi!';
  }

  Future<void> deleteReview(String reviewId) async {
    emit(MyReviewsSubmitting());
    try {
      await reviewRepository.deleteReview(reviewId);
    } catch (e) {
      emit(MyReviewsActionError(e.toString()));
      return;
    }
    emit(MyReviewsActionSuccess('Đánh giá đã được xóa!'));
    await load();
  }

  Future<void> editReview({
    required String reviewId,
    required String pitchId,
    required int rating,
    required String comment,
  }) async {
    emit(MyReviewsSubmitting());
    ReviewEntity updated;
    try {
      updated = await reviewRepository.updateReview(
        reviewId: reviewId,
        pitchId: pitchId,
        userId: userId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      emit(MyReviewsActionError(e.toString()));
      return;
    }
    emit(MyReviewsActionSuccess(_submitMessage(updated)));
    await load();
  }
}
