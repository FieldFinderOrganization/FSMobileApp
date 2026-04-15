import '../datasources/booking_remote_datasource.dart';
import '../models/booking_request_model.dart';
import '../models/booking_response_model.dart';

abstract class BookingRepository {
  Future<List<int>> getBookedSlots(String pitchId, String date);
  Future<String> createBooking(BookingRequestModel bookingRequest);
  Future<List<BookingResponseModel>> getBookingsByUser(String userId);
  Future<void> cancelBooking(String bookingId);
}

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<int>> getBookedSlots(String pitchId, String date) {
    return remoteDataSource.getBookedSlots(pitchId, date);
  }

  @override
  Future<String> createBooking(BookingRequestModel bookingRequest) {
    return remoteDataSource.createBooking(bookingRequest);
  }

  @override
  Future<List<BookingResponseModel>> getBookingsByUser(String userId) {
    return remoteDataSource.getBookingsByUser(userId);
  }

  @override
  Future<void> cancelBooking(String bookingId) {
    return remoteDataSource.cancelBooking(bookingId);
  }
}
