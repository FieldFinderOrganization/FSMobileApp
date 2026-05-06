import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../models/refund_request_model.dart';

class RefundRemoteDataSource {
  final DioClient dioClient;

  const RefundRemoteDataSource({required this.dioClient});

  /// Lấy thông tin mã hoàn tiền theo nguồn (ORDER | BOOKING).
  /// Trả về null nếu chưa có (HTTP 404).
  Future<RefundRequestModel?> getBySource({
    required String type,
    required String sourceId,
  }) async {
    try {
      final response = await dioClient.dio.get(
        '/refunds/by-source',
        queryParameters: {'type': type, 'id': sourceId},
      );
      return RefundRequestModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
