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
}
