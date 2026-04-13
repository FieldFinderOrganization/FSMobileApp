import '../../../home/domain/entities/category_entity.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getAllProducts();
  Future<List<CategoryEntity>> fetchCategories();
}
