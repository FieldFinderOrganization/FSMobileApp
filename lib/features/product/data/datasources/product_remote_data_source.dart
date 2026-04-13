import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSource(this._dio);

  Future<List<ProductModel>> getAllProducts() async {
    final response = await _dio.get(ApiConstants.products);
    return (response.data as List<dynamic>)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    return List<Map<String, dynamic>>.from(response.data);
  }
}
