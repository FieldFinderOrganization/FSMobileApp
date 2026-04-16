import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../product/data/models/product_model.dart';
import '../../../pitch/data/models/pitch_model.dart';
import '../models/category_model.dart';
import '../models/discount_model.dart';

class HomeRemoteDatasource {
  final Dio _dio;

  HomeRemoteDatasource(this._dio);

  Future<List<ProductModel>> fetchProducts() async {
    final response = await _dio.get(
      ApiConstants.products,
      queryParameters: {'page': 0, 'size': 25},
    );
    final List<dynamic> content = response.data['content'] as List<dynamic>;
    return content
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProductModel>> fetchTopProducts() async {
    final response = await _dio.get(ApiConstants.topProducts);
    return (response.data as List<dynamic>)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PitchModel>> fetchPitches() async {
    final response = await _dio.get(ApiConstants.pitches);
    return (response.data as List<dynamic>)
        .map((e) => PitchModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryModel>> fetchCategories() async {
    final response = await _dio.get(ApiConstants.categories);
    return (response.data as List<dynamic>)
        .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DiscountModel>> fetchDiscounts() async {
    final response = await _dio.get(ApiConstants.discounts);
    return (response.data as List<dynamic>)
        .map((e) => DiscountModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
