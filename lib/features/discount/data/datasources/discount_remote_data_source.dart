import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/admin_discount_model.dart';
import '../models/tier_info_model.dart';
import '../models/user_discount_model.dart';

class DiscountRemoteDataSource {
  final Dio _dio;

  DiscountRemoteDataSource(this._dio);

  Future<List<UserDiscountModel>> getWallet(String userId) async {
    final response = await _dio.get(ApiConstants.discountWallet(userId));
    final list = response.data as List<dynamic>;
    return list
        .map((e) => UserDiscountModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Lưu mã public vào ví user. BE: POST /discounts/{userId}/save {discountCode}.
  Future<void> saveToWallet(String userId, String code) async {
    await _dio.post(
      ApiConstants.discountSave(userId),
      data: {'discountCode': code},
    );
  }

  Future<List<AdminDiscountModel>> getAllDiscounts() async {
    final response = await _dio.get(ApiConstants.discounts);
    final list = response.data as List<dynamic>;
    return list
        .map((e) => AdminDiscountModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AdminDiscountModel> createDiscount(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.discounts, data: body);
    return AdminDiscountModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminDiscountModel> updateDiscount(
      String id, Map<String, dynamic> body) async {
    final response =
        await _dio.put('${ApiConstants.discounts}/$id', data: body);
    return AdminDiscountModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminDiscountModel> toggleStatus(String id, String status) async {
    final response = await _dio.patch(
      ApiConstants.discountStatus(id),
      data: {'status': status},
    );
    return AdminDiscountModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> assignToUsers(String id, List<String> userIds) async {
    await _dio.post(
      ApiConstants.assignDiscount(id),
      data: {'userIds': userIds},
    );
  }

  Future<void> deleteDiscount(String id) async {
    await _dio.delete('${ApiConstants.discounts}/$id');
  }

  /// Gán mã cho mọi user thuộc hạng [tier] trở lên. BE: POST /discounts/{id}/assign-tier.
  Future<void> assignToTier(String id, String tier) async {
    await _dio.post(
      ApiConstants.assignDiscountTier(id),
      data: {'tier': tier},
    );
  }

  /// Hạng thành viên + tiến độ. BE: GET /users/{id}/tier.
  Future<TierInfoModel> getTierInfo(String userId) async {
    final response = await _dio.get(ApiConstants.userTier(userId));
    return TierInfoModel.fromJson(response.data as Map<String, dynamic>);
  }
}
