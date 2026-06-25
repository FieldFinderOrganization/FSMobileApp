import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../order/data/models/order_model.dart';
import '../../wallet/data/models/wallet_transaction_model.dart';
import '../../wallet/data/models/wallet_view_model.dart';
import 'models/shipper_cod_remit_model.dart';

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

  /// Thu nhập shipper tính server-side: { today, week, month, todayCount, weekCount, monthCount }.
  Future<Map<String, dynamic>> getMyEarnings() async {
    final res = await dioClient.dio.get('/orders/shipper/me/earnings');
    return (res.data as Map<String, dynamic>);
  }

  Future<OrderModel> claimOrder(int orderId) async {
    final res = await dioClient.dio.put('/orders/$orderId/claim');
    return OrderModel.fromJson(res.data as Map<String, dynamic>);
  }

  // ----- Ví shipper (mirror ví chủ sân) -----

  /// Tổng quan ví: số dư, rút được, công nợ COD (số dư âm), trạng thái chặn.
  Future<WalletViewModel> getWallet() async {
    final res = await dioClient.dio.get('/shippers/wallet');
    return WalletViewModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Sao kê ví shipper (SHIP_EARNING / COD_COLLECTED / WITHDRAWAL ...).
  Future<List<WalletTransactionModel>> getWalletTransactions() async {
    final res = await dioClient.dio.get('/shippers/wallet/transactions');
    return (res.data as List<dynamic>)
        .map((e) => WalletTransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Shipper tự rút tiền về TK (gác bằng PIN).
  Future<void> withdraw(double amount, String pin) async {
    await dioClient.dio.post('/shippers/wallet/withdraw',
        data: {'amount': amount},
        options: Options(headers: {'X-Payment-Pin': pin}));
  }

  /// Tạo lệnh NỘP tiền COD qua PayOS → trả link/QR.
  Future<ShipperCodRemitModel> createCodRemit(double amount) async {
    final res = await dioClient.dio.post('/shippers/wallet/remit',
        data: {'amount': amount});
    return ShipperCodRemitModel.fromJson(res.data as Map<String, dynamic>);
  }

  /// Poll trạng thái 1 lệnh nộp COD: CREDITED | PENDING.
  Future<String> pollCodRemitStatus(String remitId) async {
    final res = await dioClient.dio.get('/shippers/wallet/remit/$remitId/status');
    return (res.data as Map<String, dynamic>)['status'] as String? ?? 'PENDING';
  }

  /// Cập nhật hồ sơ shipper (online toggle + thông tin xe + cá nhân).
  /// Dùng lại endpoint self-update PATCH /users/{id}/profile (owner-gated).
  /// Chỉ gửi field cần đổi → BE set một phần.
  Future<void> updateProfile(String userId, Map<String, dynamic> body) async {
    await dioClient.dio.patch('/users/$userId/profile', data: body);
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

  /// Kho giao hàng cố định (cấu hình BE). Trả {lat,lng,name,address}, null nếu lỗi.
  Future<Map<String, dynamic>?> getWarehouse() async {
    final res = await dioClient.dio.get('/warehouse');
    if (res.data == null) return null;
    return res.data as Map<String, dynamic>;
  }

  /// Tuyến đường shipper→đích từ OSRM (qua BE). null nếu OSRM tắt/lỗi.
  /// Trả {geometry: polyline encoded, distanceMeters, durationSeconds}.
  Future<Map<String, dynamic>?> getRoute(
    int orderId, {
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final res = await dioClient.dio.get(
      '/orders/$orderId/route',
      queryParameters: {
        'fromLat': fromLat,
        'fromLng': fromLng,
        'toLat': toLat,
        'toLng': toLng,
      },
    );
    if (res.statusCode == 204 || res.data == null) return null;
    return res.data as Map<String, dynamic>;
  }
}
