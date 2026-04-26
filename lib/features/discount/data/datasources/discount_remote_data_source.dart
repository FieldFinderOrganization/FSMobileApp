import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/admin_discount_model.dart';
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
}
