import '../../../home/domain/entities/category_entity.dart';
import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getAllProducts();
  Future<ProductEntity> getProductById(String id);
  Future<List<CategoryEntity>> fetchCategories();
}
