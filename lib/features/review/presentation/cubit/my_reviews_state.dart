import '../../../pitch/domain/entities/review_entity.dart';
import '../../../pitch/data/models/booking_response_model.dart';

abstract class MyReviewsState {}

class MyReviewsInitial extends MyReviewsState {}

class MyReviewsLoading extends MyReviewsState {}

class MyReviewsLoaded extends MyReviewsState {
  final List<ReviewEntity> reviews;
  final List<BookingResponseModel> unreviewedBookings;

  MyReviewsLoaded({required this.reviews, required this.unreviewedBookings});
}

class MyReviewsError extends MyReviewsState {
  final String message;
  MyReviewsError(this.message);
}

class MyReviewsSubmitting extends MyReviewsState {}

class MyReviewsActionSuccess extends MyReviewsState {
  final String message;
  MyReviewsActionSuccess(this.message);
}

class MyReviewsActionError extends MyReviewsState {
  final String message;
  MyReviewsActionError(this.message);
}
