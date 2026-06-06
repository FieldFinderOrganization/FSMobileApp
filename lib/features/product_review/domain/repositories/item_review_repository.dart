import '../entities/item_review_entity.dart';

abstract class ItemReviewRepository {
  Future<List<ItemReviewEntity>> getReviewsByUser(String userId);
  Future<List<ItemReviewEntity>> getReviewsByProduct(String productId);
  Future<ItemReviewEntity> addReview({
    required String userId,
    required int productId,
    required int rating,
    required String comment,
  });
  Future<ItemReviewEntity> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  });
  Future<void> deleteReview(String reviewId);
}
