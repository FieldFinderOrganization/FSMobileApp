import '../../../product/domain/entities/product_entity.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/discount_entity.dart';
import '../../../../core/utils/string_utils.dart';
import '../../../../core/utils/category_utils.dart';

enum LoadStatus { initial, loading, success, failure }

enum SortOption { none, priceAsc, priceDesc }

const int kProductPageSize = 5;


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

  // Pagination for Pitches (Tab Sân)
  final int pitchesPage;
  final bool pitchesHasMore;
  final bool isLoadingMorePitches;

  // Pagination for Products (All Products section)
  final int productsPage;
  final bool productsHasMore;
  final bool isLoadingMoreProducts;

  final String selectedCategoryName;
  final Set<String> selectedSubCategoryNames;

  final SortOption sortOption;
  final Set<String> selectedGenders; // 'Men', 'Women', 'Unisex'
  final String selectedBrand;

  final int visibleProductCount;
  final bool isProductsExpanded;
  final bool hasLoadedMore;

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
    this.pitchesPage = 0,
    this.pitchesHasMore = true,
    this.isLoadingMorePitches = false,
    this.productsPage = 0,
    this.productsHasMore = true,
    this.isLoadingMoreProducts = false,
    this.selectedCategoryName = '',
    this.selectedSubCategoryNames = const {},
    this.sortOption = SortOption.none,
    this.selectedGenders = const {},
    this.selectedBrand = '',
    this.visibleProductCount = 4,
    this.isProductsExpanded = false,
    this.hasLoadedMore = false,
    this.selectedDistrict = '',
    this.selectedPitchType = '',
    this.pitchSortOrder = 'none',
    this.errorMessage,
  });

  // ── Derived ─────────────────────────────────────────────────────────────
  // ── Derived (Simplified) ──────────────────────────────────────────

  List<CategoryEntity> get rootCategories => categories
      .where((c) => c.parentName == null || c.parentName!.isEmpty)
      .toList();

  List<CategoryEntity> get subCategories => selectedCategoryName.isEmpty
      ? []
      : categories
          .where((c) => c.parentName == selectedCategoryName)
          .toList();

  // ── No longer doing heavy client-side filtering ─────────────────────────

  List<ProductEntity> get visibleProducts => products;

  bool get hasMoreProducts => productsHasMore;

  List<DiscountEntity> get activeDiscounts =>
      discounts.where((d) => d.isActive).toList();

  /// Sân hiện tại đã được server lọc (district, type, sort).
  List<PitchEntity> get filteredPitches => pitches;

  /// Sân đã lọc cho Tìm kiếm toàn cục (Vẫn giữ client-side đơn giản nếu cần)
  List<PitchEntity> get searchFilteredPitches {
    var result = pitches;
    if (selectedPitchType.isNotEmpty) {
      result = result.where((p) => p.displayType == selectedPitchType).toList();
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
    int? pitchesPage,
    bool? pitchesHasMore,
    bool? isLoadingMorePitches,
    int? productsPage,
    bool? productsHasMore,
    bool? isLoadingMoreProducts,
    String? selectedCategoryName,
    Set<String>? selectedSubCategoryNames,
    SortOption? sortOption,
    Set<String>? selectedGenders,
    String? selectedBrand,
    int? visibleProductCount,
    bool? isProductsExpanded,
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
      pitchesPage: pitchesPage ?? this.pitchesPage,
      pitchesHasMore: pitchesHasMore ?? this.pitchesHasMore,
      isLoadingMorePitches: isLoadingMorePitches ?? this.isLoadingMorePitches,
      productsPage: productsPage ?? this.productsPage,
      productsHasMore: productsHasMore ?? this.productsHasMore,
      isLoadingMoreProducts:
          isLoadingMoreProducts ?? this.isLoadingMoreProducts,
      selectedCategoryName: selectedCategoryName ?? this.selectedCategoryName,
      selectedSubCategoryNames:
          selectedSubCategoryNames ?? this.selectedSubCategoryNames,
      sortOption: sortOption ?? this.sortOption,
      selectedGenders: selectedGenders ?? this.selectedGenders,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      visibleProductCount: visibleProductCount ?? this.visibleProductCount,
      isProductsExpanded: isProductsExpanded ?? this.isProductsExpanded,
      hasLoadedMore: hasLoadedMore ?? this.hasLoadedMore,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedPitchType: selectedPitchType ?? this.selectedPitchType,
      pitchSortOrder: pitchSortOrder ?? this.pitchSortOrder,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
