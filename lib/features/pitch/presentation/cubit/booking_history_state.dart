import 'package:equatable/equatable.dart';
import '../../data/models/booking_response_model.dart';

abstract class BookingHistoryState extends Equatable {
  const BookingHistoryState();

  @override
  List<Object?> get props => [];
}

class BookingHistoryInitial extends BookingHistoryState {}

class BookingHistoryLoading extends BookingHistoryState {}

class BookingHistorySuccess extends BookingHistoryState {
  final List<BookingResponseModel> allBookings;
  final List<BookingResponseModel> filteredBookings;
  final String? selectedStatus;
  final DateTimeRange? selectedDateRange;
  final bool sortAscending;

  const BookingHistorySuccess({
    required this.allBookings,
    required this.filteredBookings,
    this.selectedStatus,
    this.selectedDateRange,
    this.sortAscending = false,
  });

  BookingHistorySuccess copyWith({
    List<BookingResponseModel>? allBookings,
    List<BookingResponseModel>? filteredBookings,
    String? selectedStatus,
    DateTimeRange? selectedDateRange,
    bool? sortAscending,
    bool clearStatus = false,
    bool clearDateRange = false,
  }) {
    return BookingHistorySuccess(
      allBookings: allBookings ?? this.allBookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedDateRange: clearDateRange ? null : (selectedDateRange ?? this.selectedDateRange),
      sortAscending: sortAscending ?? this.sortAscending,
    );
  }

  @override
  List<Object?> get props => [
        allBookings,
        filteredBookings,
        selectedStatus,
        selectedDateRange,
        sortAscending,
      ];
}

class BookingHistoryError extends BookingHistoryState {
  final String message;

  const BookingHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

// Simple wrapper for DateRange if needed, but Flutter has DateTimeRange
class DateTimeRange extends Equatable {
  final DateTime start;
  final DateTime end;

  const DateTimeRange({required this.start, required this.end});

  @override
  List<Object?> get props => [start, end];
}
