import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> getAllProducts({int page = 0, int size = 10, int? categoryId}) async {
    final Map<String, dynamic> params = {'page': page, 'size': size};
    if (categoryId != null) params['categoryId'] = categoryId;
    final response = await _dio.get(
      ApiConstants.products,
      queryParameters: params,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<ProductModel> getProductById(String id) async {
    final response = await _dio.get('${ApiConstants.products}/$id');
    return ProductModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    return List<Map<String, dynamic>>.from(response.data);
  }
}
