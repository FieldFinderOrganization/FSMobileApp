import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/booking_request_model.dart';

class BookingRemoteDataSource {
  final DioClient dioClient;

  BookingRemoteDataSource({required this.dioClient});

  Future<List<int>> getBookedSlots(String pitchId, String date) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.bookingSlots}/$pitchId',
        queryParameters: {'date': date},
      );
      return (response.data as List).map((e) => e as int).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> createBooking(BookingRequestModel bookingRequest) async {
    try {
      await dioClient.dio.post(
        ApiConstants.bookings,
        data: bookingRequest.toJson(),
      );
    } catch (e) {
      rethrow;
    }
  }
}
