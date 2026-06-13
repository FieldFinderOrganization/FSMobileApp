import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/payment_request_model.dart';
import '../models/payment_response_model.dart';

class PaymentRemoteDataSource {
  final DioClient dioClient;

  PaymentRemoteDataSource({required this.dioClient});

  Future<PaymentResponseModel> createPayment(PaymentRequestModel request) async {
    try {
      final response = await dioClient.dio.post(
        '${ApiConstants.payments}/create',
        data: request.toJson(),
      );
      return PaymentResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentResponseModel> getPaymentStatusByBookingId(String bookingId) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.payments}/status-by-booking/$bookingId',
      );
      return PaymentResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> requestBody) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.orders,
        data: requestBody,
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentResponseModel> createShopPayment(Map<String, dynamic> requestBody) async {
    try {
      final response = await dioClient.dio.post(
        '${ApiConstants.payments}/create-shop-payment',
        data: requestBody,
      );
      return PaymentResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Báo giá phí ship (preview ở checkout). [subtotal] = giá trị đơn sau giảm giá.
  Future<Map<String, dynamic>> getShippingQuote({
    required double destLat,
    required double destLng,
    required double subtotal,
  }) async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.shippingQuote,
        queryParameters: {
          'destLat': destLat,
          'destLng': destLng,
          'subtotal': subtotal,
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<PaymentResponseModel> getShopPaymentStatus(String orderId) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.payments}/status-by-order/$orderId',
      );
      return PaymentResponseModel.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
