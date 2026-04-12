import '../datasources/booking_remote_datasource.dart';
import '../models/booking_request_model.dart';

abstract class BookingRepository {
  Future<List<int>> getBookedSlots(String pitchId, String date);
  Future<void> createBooking(BookingRequestModel bookingRequest);
}

class BookingRepositoryImpl implements BookingRepository {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<int>> getBookedSlots(String pitchId, String date) {
    return remoteDataSource.getBookedSlots(pitchId, date);
  }

  @override
  Future<void> createBooking(BookingRequestModel bookingRequest) {
    return remoteDataSource.createBooking(bookingRequest);
  }
}
