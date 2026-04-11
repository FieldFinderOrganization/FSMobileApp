import 'package:dio/dio.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/discount_entity.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDatasource _datasource;

  HomeRepositoryImpl(this._datasource);

  @override
  Future<List<ProductEntity>> fetchProducts() async {
    try {
      return await _datasource.fetchProducts();
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
  Future<List<PitchEntity>> fetchPitches() async {
    try {
      return await _datasource.fetchPitches();
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
