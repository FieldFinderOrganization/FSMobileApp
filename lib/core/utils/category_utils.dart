import '../../features/product/domain/entities/product_entity.dart';
// import '../../features/home/domain/entities/category_entity.dart';

class CategoryUtils {
  static const List<String> shoeKeywords = [
    'shoe',
    'sneaker',
    'cleat',
    'boot',
    'footwear',
    'sandal',
    'slide',
    'flip',
  ];

  static const List<String> clothingKeywords = [
    'shirt',
    't-shirt',
    'tee',
    'jersey',
    'polo',
    'tank',
    'top',
    'short',
    'pant',
    'legging',
    'trouser',
    'tight',
    'jogger',
    'hoodie',
    'sweatshirt',
    'pullover',
    'fleece',
    'jacket',
    'gilet',
    'windbreaker',
    'anorak',
    'vest',
    'sock',
  ];

  static bool isShoes(ProductEntity product) {
    final name = product.name.toLowerCase();
    final cat = product.categoryName.toLowerCase();

    // Check if category name contains "shoes" or similar
    if (cat.contains('shoe') || cat.contains('sandal') || cat.contains('slide'))
      return true;

    // Check keywords in name
    return shoeKeywords.any((kw) => name.contains(kw));
  }

  static bool isClothing(ProductEntity product) {
    final name = product.name.toLowerCase();
    final cat = product.categoryName.toLowerCase();

    // Specific category matches
    if (cat.contains('clothing')) return true;

    // Check keywords in name or category
    return clothingKeywords.any((kw) => name.contains(kw) || cat.contains(kw));
  }

  static bool isAccessories(ProductEntity product) {
    // According to user: Accessories = Everything except Clothing and Shoes
    return !isClothing(product) && !isShoes(product);
  }

  /// Checks if a product matches a target category (hierarchically or semantically)
  static bool doesProductMatchCategory({
    required ProductEntity product,
    required String targetCategoryName,
    required Set<String> descendantTargetNames,
  }) {
    if (targetCategoryName.isEmpty) return true;

    // 1. Hierarchical match (Standard)
    if (descendantTargetNames.contains(product.categoryName)) return true;

    final targetLower = targetCategoryName.toLowerCase();

    // 2. Semantic match for broad categories
    if (targetLower == 'shoes') {
      return isShoes(product);
    }
    if (targetLower == 'clothing') {
      return isClothing(product);
    }
    if (targetLower == 'accessories') {
      return isAccessories(product);
    }

    // 3. Fallback: Check if target name matches product's category name or product name
    final pName = product.name.toLowerCase();
    final pCat = product.categoryName.toLowerCase();
    if (pCat.contains(targetLower)) return true;
    if (pName.contains(targetLower)) return true;

    return false;
  }
}
