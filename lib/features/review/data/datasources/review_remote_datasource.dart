import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../pitch/data/models/review_model.dart';

class ReviewRemoteDataSource {
  final DioClient dioClient;

  ReviewRemoteDataSource({required this.dioClient});

  Future<List<ReviewModel>> getReviewsByUser(String userId) async {
    final response = await dioClient.dio.get('${ApiConstants.userReviews}/$userId');
    return (response.data as List<dynamic>)
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ReviewModel> addReview({
    required String pitchId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final response = await dioClient.dio.post(ApiConstants.reviews, data: {
      'pitchId': pitchId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
    });
    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteReview(String reviewId) async {
    await dioClient.dio.delete('${ApiConstants.reviews}/$reviewId');
  }

  Future<ReviewModel> updateReview({
    required String reviewId,
    required String pitchId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    final response = await dioClient.dio.put(
      '${ApiConstants.reviews}/$reviewId',
      data: {
        'pitchId': pitchId,
        'userId': userId,
        'rating': rating,
        'comment': comment,
      },
    );
    return ReviewModel.fromJson(response.data as Map<String, dynamic>);
  }
}
