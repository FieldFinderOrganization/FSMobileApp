import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/review_model.dart';

class ReviewRemoteDatasource {
  final Dio _dio;

  ReviewRemoteDatasource(this._dio);

  Future<List<ReviewModel>> fetchReviewsByPitch(String pitchId) async {
    final response = await _dio.get('${ApiConstants.reviews}/pitch/$pitchId');
    return (response.data as List<dynamic>)
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
