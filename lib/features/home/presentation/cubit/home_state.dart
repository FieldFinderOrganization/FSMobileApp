import '../../domain/entities/product_entity.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/discount_entity.dart';

enum LoadStatus { initial, loading, success, failure }

const int kProductPageSize = 6;

/// Các chip danh mục bị ẩn khỏi bộ lọc (vì ít ý nghĩa hoặc trùng lặp)
const Set<String> kHiddenCategories = {'All Shoes', 'All Clothing'};

/// Trả về Set tên của [parentName] + toàn bộ con cháu (đệ quy).
Set<String> getDescendantNames(
  List<CategoryEntity> categories,
  String parentName,
) {
  final result = <String>{parentName};
  void walk(String current) {
    for (final cat in categories) {
      if (cat.parentName == current && !result.contains(cat.name)) {
        result.add(cat.name);
        walk(cat.name);
      }
    }
  }
  walk(parentName);
  return result;
}

class HomeState {
  final LoadStatus productsStatus;
  final LoadStatus topProductsStatus;
  final LoadStatus pitchesStatus;
  final LoadStatus categoriesStatus;
  final LoadStatus discountsStatus;

  final List<ProductEntity> products;
  final List<ProductEntity> topProducts;
  final List<PitchEntity> pitches;
  final List<CategoryEntity> categories;
  final List<DiscountEntity> discounts;

  final String selectedCategoryName;
  final int visibleProductCount;
  final String? errorMessage;

  const HomeState({
    this.productsStatus = LoadStatus.initial,
    this.topProductsStatus = LoadStatus.initial,
    this.pitchesStatus = LoadStatus.initial,
    this.categoriesStatus = LoadStatus.initial,
    this.discountsStatus = LoadStatus.initial,
    this.products = const [],
    this.topProducts = const [],
    this.pitches = const [],
    this.categories = const [],
    this.discounts = const [],
    this.selectedCategoryName = '',
    this.visibleProductCount = kProductPageSize,
    this.errorMessage,
  });

  List<ProductEntity> get _filtered {
    // Tất cả sản phẩm
    if (selectedCategoryName.isEmpty) return products;

    // "Bestseller" → dùng topProducts từ API top-selling
    if (selectedCategoryName == 'Bestseller') return topProducts;

    // Thử lọc theo cây category (category + toàn bộ con cháu)
    final validNames = getDescendantNames(categories, selectedCategoryName);
    final byCategory =
        products.where((p) => validNames.contains(p.categoryName)).toList();

    // Nếu không có kết quả theo category → thử lọc theo brand
    // (dành cho các category là tên brand: Nike, Adidas, Puma, ...)
    if (byCategory.isEmpty) {
      return products
          .where((p) =>
              p.brand.toLowerCase() == selectedCategoryName.toLowerCase())
          .toList();
    }

    return byCategory;
  }

  List<ProductEntity> get visibleProducts =>
      _filtered.take(visibleProductCount).toList();

  bool get hasMoreProducts => visibleProductCount < _filtered.length;

  List<DiscountEntity> get activeDiscounts =>
      discounts.where((d) => d.isActive).toList();

  HomeState copyWith({
    LoadStatus? productsStatus,
    LoadStatus? topProductsStatus,
    LoadStatus? pitchesStatus,
    LoadStatus? categoriesStatus,
    LoadStatus? discountsStatus,
    List<ProductEntity>? products,
    List<ProductEntity>? topProducts,
    List<PitchEntity>? pitches,
    List<CategoryEntity>? categories,
    List<DiscountEntity>? discounts,
    String? selectedCategoryName,
    int? visibleProductCount,
    String? errorMessage,
  }) {
    return HomeState(
      productsStatus: productsStatus ?? this.productsStatus,
      topProductsStatus: topProductsStatus ?? this.topProductsStatus,
      pitchesStatus: pitchesStatus ?? this.pitchesStatus,
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      discountsStatus: discountsStatus ?? this.discountsStatus,
      products: products ?? this.products,
      topProducts: topProducts ?? this.topProducts,
      pitches: pitches ?? this.pitches,
      categories: categories ?? this.categories,
      discounts: discounts ?? this.discounts,
      selectedCategoryName: selectedCategoryName ?? this.selectedCategoryName,
      visibleProductCount: visibleProductCount ?? this.visibleProductCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
