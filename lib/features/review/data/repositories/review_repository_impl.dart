import '../../../pitch/domain/entities/review_entity.dart';
import '../../domain/repositories/review_repository.dart';
import '../datasources/review_remote_datasource.dart';

class ReviewRepositoryImpl implements ReviewRepository {
  final ReviewRemoteDataSource remoteDataSource;

  ReviewRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ReviewEntity>> getReviewsByUser(String userId) =>
      remoteDataSource.getReviewsByUser(userId);

  @override
  Future<ReviewEntity> addReview({
    required String pitchId,
    required String userId,
    required int rating,
    required String comment,
  }) =>
      remoteDataSource.addReview(
        pitchId: pitchId,
        userId: userId,
        rating: rating,
        comment: comment,
      );

  @override
  Future<void> deleteReview(String reviewId) =>
      remoteDataSource.deleteReview(reviewId);

  @override
  Future<ReviewEntity> updateReview({
    required String reviewId,
    required String pitchId,
    required String userId,
    required int rating,
    required String comment,
  }) =>
      remoteDataSource.updateReview(
        reviewId: reviewId,
        pitchId: pitchId,
        userId: userId,
        rating: rating,
        comment: comment,
      );
}
