import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/booking_request_model.dart';
import '../models/booking_response_model.dart';

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

  Future<String> createBooking(BookingRequestModel bookingRequest) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.bookings,
        data: bookingRequest.toJson(),
      );
      return response.data['bookingId'];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await dioClient.dio.put(
        '${ApiConstants.bookings}/$bookingId/cancel',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BookingResponseModel>> getBookingsByUser(String userId) async {
    try {
      final response = await dioClient.dio.get(
        '${ApiConstants.userBookings}/$userId',
      );

      return (response.data as List)
          .map((e) => BookingResponseModel.fromJson(e))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
}
