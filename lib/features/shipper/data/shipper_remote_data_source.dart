import '../../../core/network/dio_client.dart';
import '../../order/data/models/order_model.dart';

class ShipperRemoteDataSource {
  final DioClient dioClient;

  const ShipperRemoteDataSource({required this.dioClient});

  /// Đơn CONFIRMED chưa có shipper nhận.
  Future<List<OrderModel>> getAvailableOrders() async {
    final res = await dioClient.dio.get('/orders/available');
    return (res.data as List<dynamic>)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Đơn shipper hiện tại đang/đã giao.
  Future<List<OrderModel>> getMyOrders() async {
    final res = await dioClient.dio.get('/orders/shipper/me');
    return (res.data as List<dynamic>)
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderModel> claimOrder(int orderId) async {
    final res = await dioClient.dio.put('/orders/$orderId/claim');
    return OrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<OrderModel> updateStatus(int orderId, String status) async {
    final res = await dioClient.dio.put(
      '/orders/$orderId/status',
      queryParameters: {'status': status},
    );
    return OrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Vị trí cuối từ Redis (null nếu hết TTL / chưa có).
  Future<Map<String, dynamic>?> getLastLocation(int orderId) async {
    final res = await dioClient.dio.get('/orders/$orderId/last-location');
    if (res.statusCode == 204 || res.data == null) return null;
    return res.data as Map<String, dynamic>;
  }
}
