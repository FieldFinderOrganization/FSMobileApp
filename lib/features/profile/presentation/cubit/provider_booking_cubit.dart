import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/error_utils.dart';
import '../../../pitch/data/models/booking_response_model.dart';
import '../../../pitch/data/repositories/booking_repository_impl.dart';

abstract class ProviderBookingState extends Equatable {
  const ProviderBookingState();
  @override
  List<Object?> get props => [];
}

class ProviderBookingInitial extends ProviderBookingState {}

class ProviderBookingLoading extends ProviderBookingState {}

/// Chế độ sắp xếp danh sách đơn của chủ sân.
/// created  = theo thời gian tạo, mới nhất lên đầu (mặc định).
/// schedule = theo lịch đá (ngày + giờ tăng dần) như lịch agenda.
enum BookingSort { created, schedule }

class ProviderBookingLoaded extends ProviderBookingState {
  final List<BookingResponseModel> allBookings;
  final List<BookingResponseModel> filteredBookings;
  final String? selectedStatus;
  final BookingSort sortMode;

  const ProviderBookingLoaded({
    required this.allBookings,
    required this.filteredBookings,
    this.selectedStatus,
    this.sortMode = BookingSort.created,
  });

  ProviderBookingLoaded copyWith({
    List<BookingResponseModel>? allBookings,
    List<BookingResponseModel>? filteredBookings,
    String? selectedStatus,
    BookingSort? sortMode,
    bool clearStatus = false,
  }) {
    return ProviderBookingLoaded(
      allBookings: allBookings ?? this.allBookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      selectedStatus: clearStatus ? null : (selectedStatus ?? this.selectedStatus),
      sortMode: sortMode ?? this.sortMode,
    );
  }

  @override
  List<Object?> get props => [allBookings, filteredBookings, selectedStatus, sortMode];
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
    // Giữ nguyên chế độ sort khi reload (hủy đơn, kéo refresh...).
    final currentSort =
        state is ProviderBookingLoaded ? (state as ProviderBookingLoaded).sortMode : BookingSort.created;
    final currentStatus =
        state is ProviderBookingLoaded ? (state as ProviderBookingLoaded).selectedStatus : null;
    emit(ProviderBookingLoading());
    try {
      final bookings = await repository.getBookingsByProvider(providerId);
      emit(ProviderBookingLoaded(
        allBookings: bookings,
        filteredBookings: _applyFilterSort(bookings, currentStatus, currentSort),
        selectedStatus: currentStatus,
        sortMode: currentSort,
      ));
    } on DioException catch (e) {
      emit(ProviderBookingError(e.response?.data?['message'] ?? e.message ?? 'Lỗi tải dữ liệu'));
    } catch (e) {
      emit(ProviderBookingError(e.toString()));
    }
  }

  /// Provider hủy đơn của khách. Trả về null nếu thành công (list tự reload),
  /// ngược lại trả về message lỗi để UI hiện SnackBar.
  Future<String?> cancelBooking(String bookingId, String reason) async {
    try {
      await repository.providerCancelBooking(bookingId, reason: reason);
      await loadBookings();
      return null;
    } catch (e) {
      return messageFromError(e, fallback: 'Hủy đơn thất bại');
    }
  }

  void filterByStatus(String? status) {
    if (state is! ProviderBookingLoaded) return;
    final s = state as ProviderBookingLoaded;
    emit(s.copyWith(
      filteredBookings: _applyFilterSort(s.allBookings, status, s.sortMode),
      selectedStatus: status,
      clearStatus: status == null || status == 'Tất cả',
    ));
  }

  /// Đổi chế độ sắp xếp (mới tạo / theo lịch đá), giữ nguyên filter trạng thái.
  void setSortMode(BookingSort mode) {
    if (state is! ProviderBookingLoaded) return;
    final s = state as ProviderBookingLoaded;
    if (s.sortMode == mode) return;
    emit(s.copyWith(
      filteredBookings: _applyFilterSort(s.allBookings, s.selectedStatus, mode),
      sortMode: mode,
    ));
  }

  /// Lọc theo trạng thái rồi sắp xếp theo [mode]. Dùng chung cho mọi đường đổi view.
  List<BookingResponseModel> _applyFilterSort(
    List<BookingResponseModel> all,
    String? status,
    BookingSort mode,
  ) {
    final List<BookingResponseModel> filtered;
    if (status == 'BLOCK') {
      // Chỉ đơn khóa lịch / đặt ngoài app
      filtered = all.where((b) => b.blockType != null).toList();
    } else if (status == null || status == 'Tất cả') {
      // Đơn của khách (loại khóa lịch)
      filtered = all.where((b) => b.blockType == null).toList();
    } else {
      filtered = all
          .where((b) =>
              b.blockType == null &&
              b.status.toUpperCase() == status.toUpperCase())
          .toList();
    }
    _sortInPlace(filtered, mode);
    return filtered;
  }

  void _sortInPlace(List<BookingResponseModel> list, BookingSort mode) {
    if (mode == BookingSort.schedule) {
      // Theo lịch đá: ngày mới nhất lên đầu (giảm dần), cùng ngày thì giờ muộn hơn lên trước.
      list.sort((a, b) {
        final byDate = b.bookingDate.compareTo(a.bookingDate); // ISO yyyy-MM-dd
        if (byDate != 0) return byDate;
        return _earliestSlot(b).compareTo(_earliestSlot(a));
      });
    } else {
      // Mới tạo: createdAt giảm dần (mới nhất lên đầu).
      list.sort((a, b) {
        final da = _parseTime(a.createdAt);
        final db = _parseTime(b.createdAt);
        return db.compareTo(da);
      });
    }
  }

  int _earliestSlot(BookingResponseModel b) =>
      b.slots.isEmpty ? 1 << 30 : b.slots.reduce((x, y) => x < y ? x : y);

  DateTime _parseTime(String? s) =>
      s != null ? DateTime.tryParse(s) ?? DateTime(0) : DateTime(0);
}
