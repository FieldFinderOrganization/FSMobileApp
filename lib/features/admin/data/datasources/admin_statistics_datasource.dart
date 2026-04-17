import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_overview_model.dart';
import '../models/booking_by_day_model.dart';
import '../models/pitch_type_model.dart';
import '../models/product_statistics_model.dart';
import '../models/recent_booking_model.dart';
import '../models/revenue_point_model.dart';

class AdminStatisticsDatasource {
  final DioClient dioClient;

  const AdminStatisticsDatasource({required this.dioClient});

  Future<AdminOverviewModel> getOverview() async {
    final response = await dioClient.dio.get(ApiConstants.adminStatisticsOverview);
    return AdminOverviewModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<RevenuePointModel>> getRevenue({
    required String startDate,
    required String endDate,
  }) async {
    final response = await dioClient.dio.get(
      ApiConstants.adminStatisticsRevenue,
      queryParameters: {'startDate': startDate, 'endDate': endDate},
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => RevenuePointModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BookingByDayModel>> getBookingsByDay() async {
    final response = await dioClient.dio.get(ApiConstants.adminStatisticsBookingsByDay);
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => BookingByDayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PitchTypeModel>> getPitchesByType() async {
    final response = await dioClient.dio.get(ApiConstants.adminStatisticsPitchesByType);
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => PitchTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecentBookingModel>> getRecentBookings() async {
    final response = await dioClient.dio.get(ApiConstants.adminStatisticsRecentBookings);
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => RecentBookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductStatisticsModel> getProductStatistics() async {
    final response = await dioClient.dio.get(ApiConstants.adminStatisticsProducts);
    return ProductStatisticsModel.fromJson(response.data as Map<String, dynamic>);
  }
}
