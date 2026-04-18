import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../product/data/models/product_model.dart';
import '../../../pitch/data/models/pitch_model.dart';
import '../models/category_model.dart';
import '../models/discount_model.dart';

class HomeRemoteDatasource {
  final Dio _dio;

  HomeRemoteDatasource(this._dio);

  Future<Map<String, dynamic>> fetchProducts({
    int page = 0,
    int size = 10,
    int? categoryId,
    Set<String>? genders,
    String? brand,
    String? sort, // format: "field,asc" or "field,desc"
  }) async {
    final Map<String, dynamic> params = {'page': page, 'size': size};
    if (categoryId != null) params['categoryId'] = categoryId;
    if (genders != null && genders.isNotEmpty) {
      params['genders'] = genders.join(',');
    }
    if (brand != null && brand.isNotEmpty) params['brand'] = brand;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;

    final response = await _dio.get(
      ApiConstants.products,
      queryParameters: params,
    );

    final List<dynamic> content = response.data['content'] as List<dynamic>;
    final bool last = response.data['last'] as bool? ?? true;

    return {
      'content': content
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'last': last,
    };
  }

  Future<List<ProductModel>> fetchTopProducts() async {
    final response = await _dio.get(ApiConstants.topProducts);
    return (response.data as List<dynamic>)
        .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> fetchPitches({
    int page = 0,
    int size = 10,
    String? district,
    String? type,
    String? sort,
    String? name,
  }) async {
    final Map<String, dynamic> params = {'page': page, 'size': size};
    if (district != null && district.isNotEmpty) params['district'] = district;
    if (type != null && type.isNotEmpty) params['type'] = type;
    if (sort != null && sort.isNotEmpty) params['sort'] = sort;
    if (name != null && name.isNotEmpty) params['name'] = name;

    final response = await _dio.get(
      ApiConstants.pitches,
      queryParameters: params,
    );

    final List<dynamic> content = response.data['content'] as List<dynamic>;
    final bool last = response.data['last'] as bool? ?? true;

    return {
      'content': content
          .map((e) => PitchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      'last': last,
    };
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
