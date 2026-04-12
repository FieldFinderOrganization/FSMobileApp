import '../datasources/payment_remote_datasource.dart';
import '../models/payment_request_model.dart';
import '../models/payment_response_model.dart';

abstract class PaymentRepository {
  Future<PaymentResponseModel> createPayment(PaymentRequestModel request);
  Future<PaymentResponseModel> getPaymentStatusByBookingId(String bookingId);
}

class PaymentRepositoryImpl implements PaymentRepository {
  final PaymentRemoteDataSource remoteDataSource;

  PaymentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<PaymentResponseModel> createPayment(PaymentRequestModel request) {
    return remoteDataSource.createPayment(request);
  }

  @override
  Future<PaymentResponseModel> getPaymentStatusByBookingId(String bookingId) {
    return remoteDataSource.getPaymentStatusByBookingId(bookingId);
  }
}
