import '../../../product/domain/entities/product_entity.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../entities/category_entity.dart';
import '../entities/discount_entity.dart';

abstract class HomeRepository {
  Future<Map<String, dynamic>> fetchProducts({
    int page = 0,
    int size = 10,
    int? categoryId,
    Set<String>? genders,
    String? brand,
    String? sort,
  });
  Future<List<ProductEntity>> fetchTopProducts();
  Future<Map<String, dynamic>> fetchPitches({
    int page = 0,
    int size = 10,
    String? district,
    String? type,
    String? sort,
  });
  Future<List<CategoryEntity>> fetchCategories();
  Future<List<DiscountEntity>> fetchDiscounts();
}
