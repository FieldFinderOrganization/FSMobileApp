import 'package:dio/dio.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/discount_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDatasource _datasource;

  HomeRepositoryImpl(this._datasource);

  @override
  Future<Map<String, dynamic>> fetchProducts({
    int page = 0,
    int size = 10,
    int? categoryId,
    Set<String>? genders,
    String? brand,
    String? sort,
  }) async {
    try {
      final result = await _datasource.fetchProducts(
        page: page,
        size: size,
        categoryId: categoryId,
        genders: genders,
        brand: brand,
        sort: sort,
      );
      return {
        'content': (result['content'] as List).cast<ProductEntity>(),
        'last': result['last'] as bool,
      };
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<ProductEntity>> fetchTopProducts() async {
    try {
      return await _datasource.fetchTopProducts();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchPitches({
    int page = 0,
    int size = 10,
    String? district,
    String? type,
    String? sort,
  }) async {
    try {
      final result = await _datasource.fetchPitches(
        page: page,
        size: size,
        district: district,
        type: type,
        sort: sort,
      );
      return {
        'content': (result['content'] as List).cast<PitchEntity>(),
        'last': result['last'] as bool,
      };
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<CategoryEntity>> fetchCategories() async {
    try {
      return await _datasource.fetchCategories();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  @override
  Future<List<DiscountEntity>> fetchDiscounts() async {
    try {
      return await _datasource.fetchDiscounts();
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
    return Exception(message ?? 'Đã có lỗi xảy ra. Vui lòng thử lại.');
  }
}
