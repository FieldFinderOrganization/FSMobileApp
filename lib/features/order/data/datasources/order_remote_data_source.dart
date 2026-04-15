import '../../../../core/network/dio_client.dart';
import '../models/order_model.dart';

class OrderRemoteDataSource {
  final DioClient dioClient;

  const OrderRemoteDataSource({required this.dioClient});

  Future<void> cancelOrder(int orderId) async {
    await dioClient.dio.put('/orders/$orderId/cancel');
  }

  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    final response = await dioClient.dio.get('/orders/user/$userId');
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
