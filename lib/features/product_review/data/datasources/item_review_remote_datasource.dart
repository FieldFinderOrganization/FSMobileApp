import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/item_review_model.dart';

class ItemReviewRemoteDataSource {
  final DioClient dioClient;

  ItemReviewRemoteDataSource({required this.dioClient});

  Future<List<ItemReviewModel>> getReviewsByUser(String userId) async {
    final response =
        await dioClient.dio.get('${ApiConstants.itemReviews}/user/$userId');
    return (response.data as List<dynamic>)
        .map((e) => ItemReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ItemReviewModel>> getReviewsByProduct(String productId) async {
    final response = await dioClient.dio
        .get('${ApiConstants.itemReviews}/product/$productId');
    return (response.data as List<dynamic>)
        .map((e) => ItemReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ItemReviewModel> addReview({
    required String userId,
    required int productId,
    required int rating,
    required String comment,
  }) async {
    final response = await dioClient.dio.post(ApiConstants.itemReviews, data: {
      'userId': userId,
      'productId': productId,
      'rating': rating,
      'comment': comment,
    });
    return ItemReviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ItemReviewModel> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    final response = await dioClient.dio.put(
      '${ApiConstants.itemReviews}/$reviewId',
      data: {
        'rating': rating,
        'comment': comment,
      },
    );
    return ItemReviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteReview(String reviewId) async {
    await dioClient.dio.delete('${ApiConstants.itemReviews}/$reviewId');
  }
}
