import '../../../product/domain/entities/product_entity.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/discount_entity.dart';
import '../../../../core/utils/string_utils.dart';

enum LoadStatus { initial, loading, success, failure }

enum SortOption { none, priceAsc, priceDesc }

const int kProductPageSize = 6;

const Set<String> kHiddenCategories = {'All Shoes', 'All Clothing'};

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
  final Set<String> selectedSubCategoryNames;

  final SortOption sortOption;
  final Set<String> selectedGenders; // 'Men', 'Women', 'Unisex'

  final int visibleProductCount;
  final bool hasLoadedMore; // true sau khi nhấn "Xem thêm" ít nhất 1 lần

  final String selectedDistrict; // '' = Tất cả
  final String selectedPitchType; // 'Sân 5', 'Sân 7', 'Sân 11'
  final String pitchSortOrder; // 'asc', 'desc', 'none'

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
    this.sortOption = SortOption.none,
    this.selectedGenders = const {},
    this.visibleProductCount = kProductPageSize,
    this.hasLoadedMore = false,
    this.selectedDistrict = '',
    this.selectedPitchType = '',
    this.pitchSortOrder = 'none',
    this.errorMessage,
  });

  // ── Derived ─────────────────────────────────────────────────────────────

  List<CategoryEntity> get rootCategories => categories
      .where((c) =>
          (c.parentName == null || c.parentName!.isEmpty) &&
          !kHiddenCategories.contains(c.name))
      .toList();

  List<CategoryEntity> get subCategories => selectedCategoryName.isEmpty
      ? []
      : categories
          .where((c) =>
              c.parentName == selectedCategoryName &&
              !kHiddenCategories.contains(c.name))
          .toList();

  // ── Filter → Gender → Sort ───────────────────────────────────────────────

  List<ProductEntity> get _categoryFiltered {
    if (selectedCategoryName.isEmpty) return products;
    if (selectedCategoryName == 'Bestseller') return topProducts;

    final Set<String> targetNames;
    if (selectedSubCategoryNames.isNotEmpty) {
      targetNames = {};
      for (final sub in selectedSubCategoryNames) {
        targetNames.addAll(getDescendantNames(categories, sub));
      }
    } else {
      targetNames = getDescendantNames(categories, selectedCategoryName);
    }

    final keywords = <String>{};
    for (final name in targetNames) {
      final kws = kCategoryKeywords[name];
      if (kws != null) keywords.addAll(kws);
    }

    return products.where((p) {
      if (targetNames.contains(p.categoryName)) return true;
      if (targetNames.contains(p.brand)) return true;
      if (keywords.isNotEmpty) {
        final nameLower = p.name.toLowerCase();
        if (keywords.any((kw) => nameLower.contains(kw))) return true;
      }
      return false;
    }).toList();
  }

  List<ProductEntity> get _processed {
    var result = _categoryFiltered;

    // Gender filter
    if (selectedGenders.isNotEmpty) {
      final targets = Set<String>.from(selectedGenders);
      // Nếu chọn Men hoặc Women thì Unisex cũng pass
      if (targets.contains('Men') || targets.contains('Women')) {
        targets.add('Unisex');
      }
      result = result.where((p) => targets.contains(p.sex)).toList();
    }

    // Sort
    switch (sortOption) {
      case SortOption.priceAsc:
        result = [...result]
          ..sort((a, b) =>
              (a.salePrice ?? a.price).compareTo(b.salePrice ?? b.price));
      case SortOption.priceDesc:
        result = [...result]
          ..sort((a, b) =>
              (b.salePrice ?? b.price).compareTo(a.salePrice ?? a.price));
      case SortOption.none:
        break;
    }

    return result;
  }

  List<ProductEntity> get visibleProducts =>
      _processed.take(visibleProductCount).toList();

  bool get hasMoreProducts => visibleProductCount < _processed.length;

  List<DiscountEntity> get activeDiscounts =>
      discounts.where((d) => d.isActive).toList();

  /// Sân đã lọc theo khu vực, loại sân và sắp xếp đang chọn (Dùng cho tab Sân)
  List<PitchEntity> get filteredPitches {
    var result = pitches;
    
    if (selectedDistrict.isNotEmpty) {
      result = result.where((p) => p.district == selectedDistrict).toList();
    }
    
    if (selectedPitchType.isNotEmpty) {
      result = result.where((p) => p.displayType == selectedPitchType).toList();
    }
    
    if (pitchSortOrder == 'asc') {
      result = [...result]..sort((a, b) => a.price.compareTo(b.price));
    } else if (pitchSortOrder == 'desc') {
      result = [...result]..sort((a, b) => b.price.compareTo(a.price));
    }
    
    return result;
  }

  /// Sân đã lọc theo Loại và Sắp xếp giá, nhưng bỏ qua Quận (Dùng cho Tìm kiếm toàn cục)
  List<PitchEntity> get searchFilteredPitches {
    var result = pitches;

    if (selectedPitchType.isNotEmpty) {
      result = result.where((p) => p.displayType == selectedPitchType).toList();
    }

    if (pitchSortOrder == 'asc') {
      result = [...result]..sort((a, b) => a.price.compareTo(b.price));
    } else if (pitchSortOrder == 'desc') {
      result = [...result]..sort((a, b) => b.price.compareTo(a.price));
    }

    return result;
  }

  /// Danh sách quận duy nhất có trong toàn bộ danh sách sân
  List<String> get availableDistricts {
    final districts = pitches
        .map((p) => p.district)
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    districts.sort();
    return districts;
  }

  /// Danh sách quận có ít nhất một sân khớp với Loại sân và Câu truy vấn tìm kiếm hiện tại
  List<String> getActiveDistricts(String query) {
    if (query.isEmpty && selectedPitchType.isEmpty) return availableDistricts;

    final normalizedQuery = StringUtils.removeDiacritics(query.toLowerCase());
    final matches = pitches.where((p) {
      // 1. Phải khớp với Loại sân đang lọc
      final matchesType = selectedPitchType.isEmpty || p.displayType == selectedPitchType;
      if (!matchesType) return false;

      // 2. Nếu có search query, phải khớp tên hoặc loại
      if (query.isEmpty) return true;
      final nameStr = StringUtils.removeDiacritics(p.name.toLowerCase());
      final typeStr = StringUtils.removeDiacritics(p.displayType.toLowerCase());
      return nameStr.contains(normalizedQuery) || typeStr.contains(normalizedQuery);
    });

    final districts = matches.map((p) => p.district).where((d) => d.isNotEmpty).toSet().toList();
    districts.sort();
    return districts;
  }

  // ── copyWith ─────────────────────────────────────────────────────────────

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
    SortOption? sortOption,
    Set<String>? selectedGenders,
    int? visibleProductCount,
    bool? hasLoadedMore,
    String? selectedDistrict,
    String? selectedPitchType,
    String? pitchSortOrder,
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
      sortOption: sortOption ?? this.sortOption,
      selectedGenders: selectedGenders ?? this.selectedGenders,
      visibleProductCount: visibleProductCount ?? this.visibleProductCount,
      hasLoadedMore: hasLoadedMore ?? this.hasLoadedMore,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedPitchType: selectedPitchType ?? this.selectedPitchType,
      pitchSortOrder: pitchSortOrder ?? this.pitchSortOrder,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
