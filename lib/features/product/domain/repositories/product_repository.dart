import '../../../home/domain/entities/category_entity.dart';
import '../entities/product_entity.dart';
import '../entities/suggested_products_entity.dart';

abstract class ProductRepository {
  Future<Map<String, dynamic>> getAllProducts({int page = 0, int size = 10, int? categoryId, String? brand, String? sort});
  Future<ProductEntity> getProductById(String id);
  Future<List<CategoryEntity>> fetchCategories();
  Future<SuggestedProductsEntity> getSuggested(String productId, {int limit = 10});
  Future<List<ProductEntity>> getSuggestedForPitch({int limit = 10});
}
