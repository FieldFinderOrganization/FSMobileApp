import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/booking_repository_impl.dart';
import 'booking_history_state.dart';
import '../../data/models/booking_response_model.dart';

class BookingHistoryCubit extends Cubit<BookingHistoryState> {
  final BookingRepository repository;
  final String userId;

  BookingHistoryCubit({
    required this.repository,
    required this.userId,
  }) : super(BookingHistoryInitial());

  Future<void> loadBookings() async {
    emit(BookingHistoryLoading());
    try {
      final bookings = await repository.getBookingsByUser(userId);
      // Sort by date descending (newest first)
      bookings.sort((a, b) => b.bookingDate.compareTo(a.bookingDate));
      
      emit(BookingHistorySuccess(
        allBookings: bookings,
        filteredBookings: bookings,
      ));
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? e.toString();
      emit(BookingHistoryError(message));
    } catch (e) {
      emit(BookingHistoryError(e.toString()));
    }
  }

  void filterByStatus(String? status) {
    if (state is! BookingHistorySuccess) return;
    final currentState = state as BookingHistorySuccess;

    final filtered = _applyFilters(
      currentState.allBookings,
      status,
      currentState.selectedDateRange,
      currentState.sortAscending,
    );

    emit(currentState.copyWith(
      filteredBookings: filtered,
      selectedStatus: status,
      clearStatus: status == null,
    ));
  }

  void filterByDateRange(DateTimeRange? range) {
    if (state is! BookingHistorySuccess) return;
    final currentState = state as BookingHistorySuccess;

    final filtered = _applyFilters(
      currentState.allBookings,
      currentState.selectedStatus,
      range,
      currentState.sortAscending,
    );

    emit(currentState.copyWith(
      filteredBookings: filtered,
      selectedDateRange: range,
      clearDateRange: range == null,
    ));
  }

  void toggleSortOrder() {
    if (state is! BookingHistorySuccess) return;
    final currentState = state as BookingHistorySuccess;
    final newAscending = !currentState.sortAscending;

    final filtered = _applyFilters(
      currentState.allBookings,
      currentState.selectedStatus,
      currentState.selectedDateRange,
      newAscending,
    );

    emit(currentState.copyWith(
      filteredBookings: filtered,
      sortAscending: newAscending,
    ));
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await repository.cancelBooking(bookingId);
      await loadBookings();
    } on DioException catch (e) {
      final message = e.response?.data?['message'] ?? e.message ?? e.toString();
      emit(BookingHistoryError(message));
    } catch (e) {
      emit(BookingHistoryError(e.toString()));
    }
  }

  List<BookingResponseModel> _applyFilters(
    List<BookingResponseModel> all,
    String? status,
    DateTimeRange? range,
    bool ascending,
  ) {
    final result = all.where((booking) {
      bool matchStatus = true;
      if (status != null && status != 'Tất cả') {
        matchStatus = booking.status.toUpperCase() == status.toUpperCase();
      }

      bool matchDate = true;
      if (range != null) {
        final bookingDate = DateTime.parse(booking.bookingDate);
        matchDate = bookingDate.isAfter(range.start.subtract(const Duration(days: 1))) &&
                    bookingDate.isBefore(range.end.add(const Duration(days: 1)));
      }

      return matchStatus && matchDate;
    }).toList();

    result.sort((a, b) {
      final cmp = a.bookingDate.compareTo(b.bookingDate);
      return ascending ? cmp : -cmp;
    });

    return result;
  }
}
