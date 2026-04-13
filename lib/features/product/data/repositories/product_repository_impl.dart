import 'package:dio/dio.dart';
import '../../../home/data/models/category_model.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/product_remote_data_source.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<ProductEntity>> getAllProducts() async {
    try {
      return await _remoteDataSource.getAllProducts();
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
