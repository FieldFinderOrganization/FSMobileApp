import 'package:dio/dio.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<Map<String, dynamic>> getAllProducts({int page = 0, int size = 10, int? categoryId}) async {
    try {
      final data = await _remoteDataSource.getAllProducts(page: page, size: size, categoryId: categoryId);
      final products = (data['content'] as List)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList();
      
      return {
        'products': products,
        'totalElements': data['totalElements'] ?? 0,
        'totalPages': data['totalPages'] ?? 0,
        'last': data['last'] ?? true,
        'number': data['number'] ?? 0,
      };
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<ProductEntity> getProductById(String id) async {
    try {
      return await _remoteDataSource.getProductById(id);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<CategoryEntity>> fetchCategories() async {
    try {
      final data = await _remoteDataSource.fetchCategories();
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Exception _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Không thể kết nối máy chủ. Vui lòng kiểm tra mạng.');
    }
    final message = e.response?.data?['message'] as String?;
    return Exception(message ?? 'Đã có lỗi xảy ra khi tải sản phẩm.');
  }
}
