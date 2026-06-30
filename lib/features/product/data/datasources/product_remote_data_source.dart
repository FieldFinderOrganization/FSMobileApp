import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/product_model.dart';

class ProductRemoteDataSource {
  final Dio _dio;

  ProductRemoteDataSource(this._dio);

  Future<Map<String, dynamic>> getAllProducts({int page = 0, int size = 10, int? categoryId, List<String>? brands, String? sort}) async {
    final Map<String, dynamic> params = {'page': page, 'size': size};
    if (categoryId != null) params['categoryId'] = categoryId;
    // Nhiều brand → gửi lặp `brand=A&brand=B` (ListFormat.multi) khớp Set<String> ở BE.
    final cleanBrands = brands?.where((b) => b.isNotEmpty).toList() ?? const [];
    if (cleanBrands.isNotEmpty) params['brand'] = cleanBrands;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    final response = await _dio.get(
      ApiConstants.products,
      queryParameters: params,
      options: Options(listFormat: ListFormat.multi),
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

  Future<Map<String, List<ProductModel>>> fetchSuggested(
    String productId, {
    int limit = 10,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.products}/$productId/suggested',
      queryParameters: {
        'limit': limit,
      },
    );
    final data = response.data as Map<String, dynamic>;
    List<ProductModel> parse(String key) {
      final list = data[key] as List?;
      if (list == null) return [];
      return list
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return {
      'similar': parse('similar'),
      'topSelling': parse('topSelling'),
      'historyBased': parse('historyBased'),
    };
  }

  Future<List<ProductModel>> fetchSuggestedForPitch({
    int limit = 10,
  }) async {
    final response = await _dio.get(
      ApiConstants.suggestedProductsForPitch,
      queryParameters: {
        'limit': limit,
      },
    );
    final list = response.data as List?;
    if (list == null) return [];
    return list
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
