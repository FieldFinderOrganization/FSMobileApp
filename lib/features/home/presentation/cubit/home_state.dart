import '../../domain/entities/product_entity.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/discount_entity.dart';

enum LoadStatus { initial, loading, success, failure }

const int kProductPageSize = 6;

/// Danh mục bị ẩn khỏi bộ lọc chính
const Set<String> kHiddenCategories = {'All Shoes', 'All Clothing'};

/// Từ khoá tìm trong tên sản phẩm cho từng danh mục chức năng.
/// Giúp sản phẩm như "Football Gloves" xuất hiện khi chọn "Gloves"
/// dù categoryName của nó là "Football Accessories".
const Map<String, List<String>> kCategoryKeywords = {
  'Gloves': ['glove'],
  'Socks': ['sock'],
  'Bags And Backpacks': ['bag', 'backpack', 'duffel', 'tote', 'pouch', 'waist'],
  'Hats And Headwears': ['hat', 'cap', 'beanie', 'headband', 'visor', 'bandana'],
  'Tops And T-Shirts': ['shirt', 't-shirt', 'tee', 'jersey', 'polo', 'tank', 'top'],
  'Shorts': ['short'],
  'Pants And Leggings': ['pant', 'legging', 'trouser', 'tight', 'jogger'],
  'Hoodies And Sweatshirts': ['hoodie', 'sweatshirt', 'pullover', 'fleece'],
  'Jackets And Gilets': ['jacket', 'gilet', 'windbreaker', 'anorak', 'vest'],
  'Sandals And Slides': ['sandal', 'slide', 'flip'],
  'Gym And Training': ['gym', 'training'],
  'Lifestyle': ['lifestyle', 'casual'],
};

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

  /// Danh mục cha đang chọn ('' = Tất cả)
  final String selectedCategoryName;

  /// Các danh mục con đang được chọn (multi-select)
  final Set<String> selectedSubCategoryNames;

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
    this.selectedSubCategoryNames = const {},
    this.visibleProductCount = kProductPageSize,
    this.errorMessage,
  });

  // ─── Derived helpers ────────────────────────────────────────────────────

  /// Danh mục cha (không có parentName, hoặc parentName không nằm trong DS)
  List<CategoryEntity> get rootCategories => categories
      .where((c) =>
          (c.parentName == null || c.parentName!.isEmpty) &&
          !kHiddenCategories.contains(c.name))
      .toList();

  /// Danh mục con trực tiếp của [selectedCategoryName]
  List<CategoryEntity> get subCategories => selectedCategoryName.isEmpty
      ? []
      : categories
          .where((c) =>
              c.parentName == selectedCategoryName &&
              !kHiddenCategories.contains(c.name))
          .toList();

  // ─── Filter logic ────────────────────────────────────────────────────────

  List<ProductEntity> get _filtered {
    if (selectedCategoryName.isEmpty) return products;

    // Bestseller → dùng top-selling API
    if (selectedCategoryName == 'Bestseller') return topProducts;

    // Xác định tập category target
    final Set<String> targetNames;
    if (selectedSubCategoryNames.isNotEmpty) {
      // Mở rộng mỗi sub-category đã chọn theo cây con
      targetNames = {};
      for (final sub in selectedSubCategoryNames) {
        targetNames.addAll(getDescendantNames(categories, sub));
      }
    } else {
      targetNames = getDescendantNames(categories, selectedCategoryName);
    }

    // Tổng hợp keyword từ tất cả target category
    final keywords = <String>{};
    for (final name in targetNames) {
      final kws = kCategoryKeywords[name];
      if (kws != null) keywords.addAll(kws);
    }

    return products.where((p) {
      // 1. Khớp categoryName theo cây
      if (targetNames.contains(p.categoryName)) return true;
      // 2. Khớp brand (cho category là tên brand: Nike, Adidas…)
      if (targetNames.contains(p.brand)) return true;
      // 3. Khớp tên sản phẩm theo keyword
      if (keywords.isNotEmpty) {
        final nameLower = p.name.toLowerCase();
        if (keywords.any((kw) => nameLower.contains(kw))) return true;
      }
      return false;
    }).toList();
  }

  List<ProductEntity> get visibleProducts =>
      _filtered.take(visibleProductCount).toList();

  bool get hasMoreProducts => visibleProductCount < _filtered.length;

  List<DiscountEntity> get activeDiscounts =>
      discounts.where((d) => d.isActive).toList();

  // ─── copyWith ─────────────────────────────────────────────────────────────

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
    Set<String>? selectedSubCategoryNames,
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
      selectedSubCategoryNames:
          selectedSubCategoryNames ?? this.selectedSubCategoryNames,
      visibleProductCount: visibleProductCount ?? this.visibleProductCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
