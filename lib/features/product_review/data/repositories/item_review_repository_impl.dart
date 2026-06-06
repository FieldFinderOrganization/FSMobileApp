import '../../domain/entities/item_review_entity.dart';
import '../../domain/repositories/item_review_repository.dart';
import '../datasources/item_review_remote_datasource.dart';

class ItemReviewRepositoryImpl implements ItemReviewRepository {
  final ItemReviewRemoteDataSource remoteDataSource;

  ItemReviewRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ItemReviewEntity>> getReviewsByUser(String userId) =>
      remoteDataSource.getReviewsByUser(userId);

  @override
  Future<List<ItemReviewEntity>> getReviewsByProduct(String productId) =>
      remoteDataSource.getReviewsByProduct(productId);

  @override
  Future<ItemReviewEntity> addReview({
    required String userId,
    required int productId,
    required int rating,
    required String comment,
  }) =>
      remoteDataSource.addReview(
        userId: userId,
        productId: productId,
        rating: rating,
        comment: comment,
      );

  @override
  Future<ItemReviewEntity> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) =>
      remoteDataSource.updateReview(
        reviewId: reviewId,
        rating: rating,
        comment: comment,
      );

  @override
  Future<void> deleteReview(String reviewId) =>
      remoteDataSource.deleteReview(reviewId);
}
