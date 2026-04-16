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
      
      final filtered = _applyFilters(
        bookings,
        null,
        null,
        false, // sortAscending
        BookingSortMode.schedule,
      );

      emit(BookingHistorySuccess(
        allBookings: bookings,
        filteredBookings: filtered,
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
      currentState.sortMode,
    );

    emit(currentState.copyWith(
      filteredBookings: filtered,
      selectedStatus: status,
      clearStatus: status == null,
    ));
  }

  void clearMessage() {
    if (state is BookingHistorySuccess) {
      final currentState = state as BookingHistorySuccess;
      if (currentState.message != null) {
        emit(currentState.copyWith(clearMessage: true));
      }
    }
  }

  void setSortMode(BookingSortMode mode) {
    if (state is! BookingHistorySuccess) return;
    final currentState = state as BookingHistorySuccess;

    final filtered = _applyFilters(
      currentState.allBookings,
      currentState.selectedStatus,
      currentState.selectedDateRange,
      currentState.sortAscending,
      mode,
    );

    emit(currentState.copyWith(
      filteredBookings: filtered,
      sortMode: mode,
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
      currentState.sortMode,
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
      currentState.sortMode,
    );

    emit(currentState.copyWith(
      filteredBookings: filtered,
      sortAscending: newAscending,
    ));
  }

  Future<void> cancelBooking(String bookingId) async {
    try {
      await repository.cancelBooking(bookingId);
      final bookings = await repository.getBookingsByUser(userId);
      
      final filtered = _applyFilters(
        bookings,
        null,
        null,
        false, // sortAscending
        BookingSortMode.schedule,
      );

      emit(BookingHistorySuccess(
        allBookings: bookings,
        filteredBookings: filtered,
        message: 'Hủy đặt sân thành công!',
      ));
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
    BookingSortMode sortMode,
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
      int cmp;
      if (sortMode == BookingSortMode.schedule) {
        // Primary: Match Date
        cmp = a.bookingDate.compareTo(b.bookingDate);
        if (cmp == 0) {
          // Secondary: Start Slot
          final slotA = a.slots.isNotEmpty ? a.slots.first : 0;
          final slotB = b.slots.isNotEmpty ? b.slots.first : 0;
          cmp = slotA.compareTo(slotB);
        }
      } else {
        // Creation Time Mode
        final dateA = a.createdAt != null ? DateTime.parse(a.createdAt!) : DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = b.createdAt != null ? DateTime.parse(b.createdAt!) : DateTime.fromMillisecondsSinceEpoch(0);
        cmp = dateA.compareTo(dateB);
      }
      
      // Finally use bookingId as tie-breaker for stable sort
      if (cmp == 0) {
        cmp = a.bookingId.compareTo(b.bookingId);
      }

      return ascending ? cmp : -cmp;
    });

    return result;
  }
}
