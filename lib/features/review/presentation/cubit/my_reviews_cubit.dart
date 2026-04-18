import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../pitch/data/datasources/booking_remote_datasource.dart';
import '../../../pitch/data/models/booking_response_model.dart';
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
    try {
      await reviewRepository.addReview(
        pitchId: pitchId,
        userId: userId,
        rating: rating,
        comment: comment,
      );
    } catch (e) {
      emit(MyReviewsActionError(e.toString()));
      return;
    }
    emit(MyReviewsActionSuccess('Đánh giá đã được gửi!'));
    await load();
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
    try {
      await reviewRepository.updateReview(
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
    emit(MyReviewsActionSuccess('Đánh giá đã được cập nhật!'));
    await load();
  }
}
