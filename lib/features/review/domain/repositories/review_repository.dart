import '../../../pitch/domain/entities/review_entity.dart';

abstract class ReviewRepository {
  Future<List<ReviewEntity>> getReviewsByUser(String userId);
  Future<ReviewEntity> addReview({
    required String pitchId,
    required String userId,
    required int rating,
    required String comment,
  });
  Future<void> deleteReview(String reviewId);

  Future<ReviewEntity> updateReview({
    required String reviewId,
    required String pitchId,
    required String userId,
    required int rating,
    required String comment,
  });
}
