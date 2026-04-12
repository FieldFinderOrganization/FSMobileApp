import '../../../product/domain/entities/product_entity.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../entities/category_entity.dart';
import '../entities/discount_entity.dart';

abstract class HomeRepository {
  Future<List<ProductEntity>> fetchProducts();
  Future<List<ProductEntity>> fetchTopProducts();
  Future<List<PitchEntity>> fetchPitches();
  Future<List<CategoryEntity>> fetchCategories();
  Future<List<DiscountEntity>> fetchDiscounts();
}
