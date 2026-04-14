import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/cart_model.dart';

Exception _mapDio(DioException e) {
  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout) {
    return Exception('Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.');
  }
  final msg = e.response?.data is Map
      ? (e.response?.data as Map)['message'] as String?
      : null;
  return Exception(msg ?? 'Đã có lỗi xảy ra.');
}

class CartRemoteDataSource {
  final Dio _dio;

  CartRemoteDataSource(this._dio);

  Future<CartModel> getCart() async {
    final response = await _dio.get(ApiConstants.cart);
    return CartModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> addItem(int productId, String size, int quantity) async {
    try {
      await _dio.post(ApiConstants.cartAdd, data: {
        'productId': productId,
        'size': size,
        'quantity': quantity,
      });
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<void> updateItem(int productId, String size, int quantity) async {
    try {
      await _dio.put(ApiConstants.cartUpdate, data: {
        'productId': productId,
        'size': size,
        'quantity': quantity,
      });
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<void> removeItem(int productId, String size) async {
    try {
      await _dio.delete(ApiConstants.cartRemove, queryParameters: {
        'productId': productId,
        'size': size,
      });
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }

  Future<void> clearCart() async {
    try {
      await _dio.delete(ApiConstants.cartClear);
    } on DioException catch (e) {
      throw _mapDio(e);
    }
  }
}
