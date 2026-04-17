import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/admin_statistics_datasource.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminStatisticsDatasource datasource;

  AdminDashboardCubit({required this.datasource}) : super(const AdminDashboardInitial());

  Future<void> loadDashboard({int timeRange = 1}) async {
    emit(const AdminDashboardLoading());
    try {
      final dateRange = _getDateRange(timeRange);
      final results = await Future.wait([
        datasource.getOverview(),
        datasource.getRevenue(startDate: dateRange.$1, endDate: dateRange.$2),
        datasource.getBookingsByDay(),
        datasource.getPitchesByType(),
        datasource.getRecentBookings(),
        datasource.getProductStatistics(),
      ]);
      emit(AdminDashboardLoaded(
        overview: results[0] as dynamic,
        revenueData: results[1] as dynamic,
        bookingsByDay: results[2] as dynamic,
        pitchesByType: results[3] as dynamic,
        recentBookings: results[4] as dynamic,
        productStatistics: results[5] as dynamic,
        selectedTimeRange: timeRange,
      ));
    } on DioException catch (e) {
      emit(AdminDashboardError(
        e.response?.data?['message'] as String? ?? 'Lỗi tải dữ liệu',
      ));
    } catch (_) {
      emit(const AdminDashboardError('Đã xảy ra lỗi. Vui lòng thử lại.'));
    }
  }

  Future<void> changeTimeRange(int index) async {
    final current = state;
    if (current is! AdminDashboardLoaded) return;
    try {
      final dateRange = _getDateRange(index);
      final revenueData = await datasource.getRevenue(
        startDate: dateRange.$1,
        endDate: dateRange.$2,
      );
      emit(current.copyWith(revenueData: revenueData, selectedTimeRange: index));
    } on DioException catch (_) {
      // Keep current state, just update selectedTimeRange
      emit(current.copyWith(selectedTimeRange: index));
    }
  }

  (String, String) _getDateRange(int timeRange) {
    final now = DateTime.now();
    final end = _formatDate(now);
    String start;
    switch (timeRange) {
      case 0: // 1 tuần
        start = _formatDate(now.subtract(const Duration(days: 7)));
      case 1: // 1 tháng
        start = _formatDate(DateTime(now.year, now.month - 1, now.day));
      case 2: // 1 năm
        start = _formatDate(DateTime(now.year - 1, now.month, now.day));
      default: // Tất cả - 5 năm
        start = _formatDate(DateTime(now.year - 5, now.month, now.day));
    }
    return (start, end);
  }

  String _formatDate(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
