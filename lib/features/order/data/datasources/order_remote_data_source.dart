import '../../../../core/network/dio_client.dart';
import '../models/order_model.dart';

class OrderRemoteDataSource {
  final DioClient dioClient;

  const OrderRemoteDataSource({required this.dioClient});

  /// Hủy đơn — BE tự quyết định có phát hành mã hoàn tiền không (PENDING vs PAID+24h).
  /// Mobile sau 200 OK gọi /refunds/by-source để lấy mã nếu có.
  Future<void> cancelOrder(int orderId, {String? reason}) async {
    await dioClient.dio.put(
      '/orders/$orderId/cancel',
      queryParameters: reason != null && reason.isNotEmpty
          ? {'reason': reason}
          : null,
    );
  }

  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    final response = await dioClient.dio.get('/orders/user/$userId');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
