import 'package:equatable/equatable.dart';
import '../../data/models/booking_response_model.dart';
enum BookingSortMode { schedule, creationTime }

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
  final BookingSortMode sortMode;
  final String? message;

  const BookingHistorySuccess({
    required this.allBookings,
    required this.filteredBookings,
    this.selectedStatus,
    this.selectedDateRange,
    this.sortAscending = false,
    this.sortMode = BookingSortMode.schedule,
    this.message,
  });

  BookingHistorySuccess copyWith({
    List<BookingResponseModel>? allBookings,
    List<BookingResponseModel>? filteredBookings,
    String? selectedStatus,
    DateTimeRange? selectedDateRange,
    bool? sortAscending,
    BookingSortMode? sortMode,
    String? message,
    bool clearStatus = false,
    bool clearDateRange = false,
    bool clearMessage = false,
  }) {
    return BookingHistorySuccess(
      allBookings: allBookings ?? this.allBookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      selectedDateRange: clearDateRange ? null : (selectedDateRange ?? this.selectedDateRange),
      sortAscending: sortAscending ?? this.sortAscending,
      sortMode: sortMode ?? this.sortMode,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [
        allBookings,
        filteredBookings,
        selectedStatus,
        selectedDateRange,
        sortAscending,
        sortMode,
        message,
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
