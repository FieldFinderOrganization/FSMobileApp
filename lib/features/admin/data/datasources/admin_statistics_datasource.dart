import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/admin_booking_list_model.dart';
import '../models/booking_stats_model.dart';
import '../models/admin_order_list_model.dart';
import '../models/admin_overview_model.dart';
import '../models/admin_pitch_list_model.dart';
import '../models/admin_rating_stats_model.dart';
import '../models/admin_user_list_model.dart';
import '../models/admin_user_stats_model.dart';
import '../models/booking_by_day_model.dart';
import '../models/pitch_type_model.dart';
import '../models/product_statistics_model.dart';
import '../models/recent_booking_model.dart';
import '../models/revenue_point_model.dart';
import '../../../order/data/models/order_model.dart';
import '../../../pitch/data/models/review_model.dart';
import '../../../product_review/data/models/item_review_model.dart';

class AdminStatisticsDatasource {
  final DioClient dioClient;

  const AdminStatisticsDatasource({required this.dioClient});

  /// Chi tiết đơn đầy đủ (có toạ độ giao + shipper) để admin theo dõi/đổi trạng thái.
  Future<OrderModel> getOrderById(int orderId) async {
    final response = await dioClient.dio.get('/orders/$orderId');
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<OrderModel> updateOrderStatus(int orderId, String status) async {
    final response = await dioClient.dio.put(
      '/orders/$orderId/status',
      queryParameters: {'status': status},
    );
    return OrderModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminOverviewModel> getOverview() async {
    final response = await dioClient.dio.get(
      ApiConstants.adminStatisticsOverview,
    );
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
    final response = await dioClient.dio.get(
      ApiConstants.adminStatisticsBookingsByDay,
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => BookingByDayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PitchTypeModel>> getPitchesByType() async {
    final response = await dioClient.dio.get(
      ApiConstants.adminStatisticsPitchesByType,
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => PitchTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<RecentBookingModel>> getRecentBookings() async {
    final response = await dioClient.dio.get(
      ApiConstants.adminStatisticsRecentBookings,
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((e) => RecentBookingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProductStatisticsModel> getProductStatistics() async {
    final response = await dioClient.dio.get(
      ApiConstants.adminStatisticsProducts,
    );
    return ProductStatisticsModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<AdminPitchListModel> getAdminPitches({
    int page = 0,
    int size = 10,
    String search = '',
    String? type,
    String? sort,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      'search': search,
    };
    if (type != null) params['type'] = type;
    if (sort != null) params['sort'] = sort;
    final response = await dioClient.dio.get(
      ApiConstants.adminPitchesList,
      queryParameters: params,
    );
    return AdminPitchListModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminUserListModel> getUsers({
    int page = 0,
    int size = 10,
    String search = '',
    String? status,
    String? role,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      'search': search,
    };
    if (status != null) params['status'] = status;
    if (role != null) params['role'] = role;
    final response = await dioClient.dio.get(
      ApiConstants.adminUsers,
      queryParameters: params,
    );
    return AdminUserListModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminUserStatsModel> getUserStats() async {
    final response = await dioClient.dio.get(ApiConstants.adminUserStats);
    return AdminUserStatsModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<BookingStatsModel> getBookingStats() async {
    final response = await dioClient.dio.get(ApiConstants.adminBookingStats);
    return BookingStatsModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminBookingListModel> getAdminBookings({
    int page = 0,
    int size = 10,
    String? status,
    String? startDate,
    String? endDate,
    double? minPrice,
    double? maxPrice,
  }) async {
    final params = <String, dynamic>{'page': page, 'size': size};
    if (status != null) params['status'] = status;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (minPrice != null) params['minPrice'] = minPrice;
    if (maxPrice != null) params['maxPrice'] = maxPrice;
    final response = await dioClient.dio.get(
      ApiConstants.adminBookingsList,
      queryParameters: params,
    );
    return AdminBookingListModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<AdminOrderListModel> getAdminOrders({
    int page = 0,
    int size = 10,
    String? status,
    String search = '',
    String? startDate,
    String? endDate,
    double? minAmount,
    double? maxAmount,
    String sort = 'default',
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'size': size,
      'search': search,
      'sort': sort,
    };
    if (status != null) params['status'] = status;
    if (startDate != null) params['startDate'] = startDate;
    if (endDate != null) params['endDate'] = endDate;
    if (minAmount != null) params['minAmount'] = minAmount;
    if (maxAmount != null) params['maxAmount'] = maxAmount;
    final response = await dioClient.dio.get(
      ApiConstants.adminOrdersList,
      queryParameters: params,
    );
    return AdminOrderListModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> getOrderStats() async {
    final response = await dioClient.dio.get(ApiConstants.adminOrderStats);
    return (response.data as List<dynamic>)
        .map((e) => e as Map<String, dynamic>)
        .toList();
  }

  Future<AdminRatingStatsModel> getRatingStats() async {
    final response = await dioClient.dio.get(ApiConstants.adminReviewStats);
    return AdminRatingStatsModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ---------------- Kiểm duyệt đánh giá (admin) ----------------

  /// Đánh giá SÂN theo trạng thái (PENDING | REJECTED | APPROVED).
  Future<List<ReviewModel>> getPitchReviewsForModeration(String status) async {
    final response = await dioClient.dio.get(
      ApiConstants.adminModerationPitchReviews,
      queryParameters: {'status': status},
    );
    return (response.data as List<dynamic>)
        .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Đánh giá SẢN PHẨM theo trạng thái.
  Future<List<ItemReviewModel>> getProductReviewsForModeration(
      String status) async {
    final response = await dioClient.dio.get(
      ApiConstants.adminModerationProductReviews,
      queryParameters: {'status': status},
    );
    return (response.data as List<dynamic>)
        .map((e) => ItemReviewModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> approvePitchReview(String reviewId) async {
    await dioClient.dio.put(
      '${ApiConstants.adminModerationPitchReviews}/$reviewId/approve',
    );
  }

  Future<void> rejectPitchReview(String reviewId, {String? reason}) async {
    await dioClient.dio.put(
      '${ApiConstants.adminModerationPitchReviews}/$reviewId/reject',
      data: {'reason': reason},
    );
  }

  Future<void> approveProductReview(String reviewId) async {
    await dioClient.dio.put(
      '${ApiConstants.adminModerationProductReviews}/$reviewId/approve',
    );
  }

  Future<void> rejectProductReview(String reviewId, {String? reason}) async {
    await dioClient.dio.put(
      '${ApiConstants.adminModerationProductReviews}/$reviewId/reject',
      data: {'reason': reason},
    );
  }

  /// Số lượng theo trạng thái (badge): {pitch:{pending,approved,rejected}, product:{...}, pendingTotal}.
  Future<Map<String, dynamic>> getModerationCounts() async {
    final response = await dioClient.dio.get(ApiConstants.adminModerationCounts);
    return response.data as Map<String, dynamic>;
  }

  /// Ngưng sân từ targetDate (Admin — áp dụng cho mọi sân).
  Future<void> deactivatePitch(String pitchId, DateTime targetDate) async {
    final dateStr =
        '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    await dioClient.dio.patch(
      '${ApiConstants.pitches}/$pitchId/status',
      data: {'targetDate': dateStr},
    );
  }

  /// Kích hoạt lại sân INACTIVE (Admin).
  Future<void> reactivatePitch(String pitchId) async {
    await dioClient.dio.patch(
      '${ApiConstants.pitches}/$pitchId/status',
      data: {'status': 'ACTIVE'},
    );
  }
}
