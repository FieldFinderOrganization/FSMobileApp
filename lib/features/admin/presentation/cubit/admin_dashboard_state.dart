import 'package:equatable/equatable.dart';
import '../../data/models/admin_overview_model.dart';
import '../../data/models/booking_by_day_model.dart';
import '../../data/models/pitch_type_model.dart';
import '../../data/models/product_statistics_model.dart';
import '../../data/models/recent_booking_model.dart';
import '../../data/models/revenue_point_model.dart';

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {
  const AdminDashboardInitial();
}

class AdminDashboardLoading extends AdminDashboardState {
  const AdminDashboardLoading();
}

class AdminDashboardLoaded extends AdminDashboardState {
  final AdminOverviewModel overview;
  final List<RevenuePointModel> revenueData;
  final List<BookingByDayModel> bookingsByDay;
  final List<PitchTypeModel> pitchesByType;
  final List<RecentBookingModel> recentBookings;
  final ProductStatisticsModel productStatistics;
  final int selectedTimeRange;

  const AdminDashboardLoaded({
    required this.overview,
    required this.revenueData,
    required this.bookingsByDay,
    required this.pitchesByType,
    required this.recentBookings,
    required this.productStatistics,
    this.selectedTimeRange = 1,
  });

  AdminDashboardLoaded copyWith({
    AdminOverviewModel? overview,
    List<RevenuePointModel>? revenueData,
    List<BookingByDayModel>? bookingsByDay,
    List<PitchTypeModel>? pitchesByType,
    List<RecentBookingModel>? recentBookings,
    ProductStatisticsModel? productStatistics,
    int? selectedTimeRange,
  }) {
    return AdminDashboardLoaded(
      overview: overview ?? this.overview,
      revenueData: revenueData ?? this.revenueData,
      bookingsByDay: bookingsByDay ?? this.bookingsByDay,
      pitchesByType: pitchesByType ?? this.pitchesByType,
      recentBookings: recentBookings ?? this.recentBookings,
      productStatistics: productStatistics ?? this.productStatistics,
      selectedTimeRange: selectedTimeRange ?? this.selectedTimeRange,
    );
  }

  @override
  List<Object?> get props => [
        overview,
        revenueData,
        bookingsByDay,
        pitchesByType,
        recentBookings,
        productStatistics,
        selectedTimeRange,
      ];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;

  const AdminDashboardError(this.message);

  @override
  List<Object?> get props => [message];
}
