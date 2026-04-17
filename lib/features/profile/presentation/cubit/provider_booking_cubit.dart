import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../pitch/data/models/booking_response_model.dart';
import '../../../pitch/data/repositories/booking_repository_impl.dart';

abstract class ProviderBookingState extends Equatable {
  const ProviderBookingState();
  @override
  List<Object?> get props => [];
}

class ProviderBookingInitial extends ProviderBookingState {}

class ProviderBookingLoading extends ProviderBookingState {}

class ProviderBookingLoaded extends ProviderBookingState {
  final List<BookingResponseModel> allBookings;
  final List<BookingResponseModel> filteredBookings;
  final String? selectedStatus;

  const ProviderBookingLoaded({
    required this.allBookings,
    required this.filteredBookings,
    this.selectedStatus,
  });

  ProviderBookingLoaded copyWith({
    List<BookingResponseModel>? allBookings,
    List<BookingResponseModel>? filteredBookings,
    String? selectedStatus,
    bool clearStatus = false,
  }) {
    return ProviderBookingLoaded(
      allBookings: allBookings ?? this.allBookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
    );
  }

  @override
  List<Object?> get props => [allBookings, filteredBookings, selectedStatus];
}

class ProviderBookingError extends ProviderBookingState {
  final String message;
  const ProviderBookingError(this.message);
  @override
  List<Object?> get props => [message];
}

class ProviderBookingCubit extends Cubit<ProviderBookingState> {
  final BookingRepository repository;
  final String providerId;

  ProviderBookingCubit({
    required this.repository,
    required this.providerId,
  }) : super(ProviderBookingInitial());

  Future<void> loadBookings() async {
    emit(ProviderBookingLoading());
    try {
      final bookings = await repository.getBookingsByProvider(providerId);
      bookings.sort((a, b) {
        final dateA = a.createdAt != null ? DateTime.tryParse(a.createdAt!) ?? DateTime(0) : DateTime(0);
        final dateB = b.createdAt != null ? DateTime.tryParse(b.createdAt!) ?? DateTime(0) : DateTime(0);
        return dateB.compareTo(dateA);
      });
      emit(ProviderBookingLoaded(
        allBookings: bookings,
        filteredBookings: bookings,
      ));
    } on DioException catch (e) {
      emit(ProviderBookingError(e.response?.data?['message'] ?? e.message ?? 'Lỗi tải dữ liệu'));
    } catch (e) {
      emit(ProviderBookingError(e.toString()));
    }
  }

  void filterByStatus(String? status) {
    if (state is! ProviderBookingLoaded) return;
    final s = state as ProviderBookingLoaded;
    final filtered = (status == null || status == 'Tất cả')
        ? s.allBookings
        : s.allBookings.where((b) => b.status.toUpperCase() == status.toUpperCase()).toList();
    emit(s.copyWith(
      filteredBookings: filtered,
      selectedStatus: status,
      clearStatus: status == null || status == 'Tất cả',
    ));
  }
}
