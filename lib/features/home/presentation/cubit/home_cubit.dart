import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/home_repository.dart';
import '../../../product/domain/entities/product_entity.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import 'home_state.dart';

export 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final HomeRepository _repository;
  Timer? _searchDebounce;

  HomeCubit({required HomeRepository repository})
      : _repository = repository,
        super(const HomeState());

  Future<void> loadAll() async {
    // Reset pages
    emit(state.copyWith(
      pitchesPage: 0,
      pitchesHasMore: true,
      productsPage: 0,
      productsHasMore: true,
    ));

    await Future.wait([
      _loadCategories(),
      _loadDiscounts(),
      _loadPitchesFirstPage(),
      _loadTopProducts(),
      _loadProductsFirstPage(),
    ]);
  }

  Future<void> _loadCategories() async {
    emit(state.copyWith(categoriesStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchCategories();
      emit(state.copyWith(categories: data, categoriesStatus: LoadStatus.success));
    } catch (e) {
      emit(state.copyWith(
          categoriesStatus: LoadStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _loadDiscounts() async {
    emit(state.copyWith(discountsStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchDiscounts();
      emit(state.copyWith(discounts: data, discountsStatus: LoadStatus.success));
    } catch (e) {
      emit(state.copyWith(
          discountsStatus: LoadStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _loadPitchesFirstPage() async {
    emit(state.copyWith(
      pitchesStatus: LoadStatus.loading,
      pitches: [], // Clear old pitches
      pitchesPage: 0,
    ));
    try {
      String? sortStr;
      if (state.pitchSortOrder == 'asc') sortStr = 'price,asc';
      if (state.pitchSortOrder == 'desc') sortStr = 'price,desc';

      final result = await _repository.fetchPitches(
        page: 0,
        size: 10,
        district: state.selectedDistrict,
        type: state.selectedPitchType,
        sort: sortStr,
        name: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );
      final pitches = result['content'] as List<PitchEntity>;

      // Populate allDistricts once from the unfiltered first load
      final isUnfiltered = state.selectedDistrict.isEmpty &&
          state.selectedPitchType.isEmpty &&
          state.searchQuery.isEmpty;
      final allDistricts = isUnfiltered
          ? (pitches.map((p) => p.district).where((d) => d.isNotEmpty).toSet().toList()..sort())
          : state.allDistricts;

      emit(state.copyWith(
        pitches: pitches,
        pitchesPage: 0,
        pitchesHasMore: !(result['last'] as bool),
        pitchesStatus: LoadStatus.success,
        allDistricts: allDistricts,
      ));
    } catch (e) {
      emit(state.copyWith(
          pitchesStatus: LoadStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> loadNextPagePitches() async {
    if (state.isLoadingMorePitches || !state.pitchesHasMore) return;

    emit(state.copyWith(isLoadingMorePitches: true));
    try {
      final nextPage = state.pitchesPage + 1;
      String? sortStr;
      if (state.pitchSortOrder == 'asc') sortStr = 'price,asc';
      if (state.pitchSortOrder == 'desc') sortStr = 'price,desc';

      final result = await _repository.fetchPitches(
        page: nextPage,
        size: 10,
        district: state.selectedDistrict,
        type: state.selectedPitchType,
        sort: sortStr,
        name: state.searchQuery.isNotEmpty ? state.searchQuery : null,
      );

      final newPitches = result['content'] as List<PitchEntity>;
      final isLast = result['last'] as bool;

      emit(state.copyWith(
        isLoadingMorePitches: false,
        pitches: [...state.pitches, ...newPitches],
        pitchesPage: nextPage,
        pitchesHasMore: !isLast,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMorePitches: false));
    }
  }

  Future<void> _loadTopProducts() async {
    emit(state.copyWith(topProductsStatus: LoadStatus.loading));
    try {
      final data = await _repository.fetchTopProducts();
      emit(state.copyWith(
          topProducts: data, topProductsStatus: LoadStatus.success));
    } catch (e) {
      emit(state.copyWith(
          topProductsStatus: LoadStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _loadProductsFirstPage() async {
    emit(state.copyWith(productsStatus: LoadStatus.loading));
    try {
      String? sortStr;
      if (state.sortOption == SortOption.priceAsc) sortStr = 'price,asc';
      if (state.sortOption == SortOption.priceDesc) sortStr = 'price,desc';

      final categoryNameToUse = state.selectedSubCategoryNames.isNotEmpty
          ? state.selectedSubCategoryNames.first
          : state.selectedCategoryName;

      final result = await _repository.fetchProducts(
        page: 0,
        size: 10,
        categoryId: _getCategoryIdFromName(categoryNameToUse),
        brand: state.selectedBrand,
        genders: state.selectedGenders,
        sort: sortStr,
      );
      emit(state.copyWith(
        products: result['content'] as List<ProductEntity>,
        productsPage: 0,
        productsHasMore: !(result['last'] as bool),
        productsStatus: LoadStatus.success,
      ));
    } catch (e) {
      emit(state.copyWith(
          productsStatus: LoadStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> loadNextPageProducts() async {
    if (state.isLoadingMoreProducts || !state.productsHasMore) return;

    emit(state.copyWith(isLoadingMoreProducts: true));
    try {
      final nextPage = state.productsPage + 1;
      String? sortStr;
      if (state.sortOption == SortOption.priceAsc) sortStr = 'price,asc';
      if (state.sortOption == SortOption.priceDesc) sortStr = 'price,desc';

      final categoryNameToUse = state.selectedSubCategoryNames.isNotEmpty
          ? state.selectedSubCategoryNames.first
          : state.selectedCategoryName;

      final result = await _repository.fetchProducts(
        page: nextPage,
        size: 10,
        categoryId: _getCategoryIdFromName(categoryNameToUse),
        brand: state.selectedBrand,
        genders: state.selectedGenders,
        sort: sortStr,
      );

      final newProducts = result['content'] as List<ProductEntity>;
      final isLast = result['last'] as bool;

      emit(state.copyWith(
        isLoadingMoreProducts: false,
        products: [...state.products, ...newProducts],
        productsPage: nextPage,
        productsHasMore: !isLast,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMoreProducts: false));
    }
  }

  int? _getCategoryIdFromName(String name) {
    if (name.isEmpty) return null;
    try {
      final category = state.categories.firstWhere((c) => c.name == name);
      return int.tryParse(category.id);
    } catch (_) {
      return null;
    }
  }

  // ── Category ─────────────────────────────────────────────────────────────

  void selectCategory(String categoryName) {
    emit(state.copyWith(
      selectedCategoryName: categoryName,
      selectedSubCategoryNames: {},
      selectedBrand: '', // Reset brand when changing category
      isProductsExpanded: false,
      visibleProductCount: 4,
      hasLoadedMore: false,
    ));
    // For simplicity in this demo, we just reload all or you could trigger _loadProductsFirstPage with category
    _loadProductsFirstPage();
  }

  void toggleSubCategory(String subCategoryName) {
    final current = Set<String>.from(state.selectedSubCategoryNames);
    if (current.contains(subCategoryName)) {
      current.remove(subCategoryName);
    } else {
      current.add(subCategoryName);
    }
    emit(state.copyWith(
      selectedSubCategoryNames: current,
      isProductsExpanded: false,
      visibleProductCount: 4,
      hasLoadedMore: false,
    ));
    // Trigger reload
    _loadProductsFirstPage();
  }

  // ── Pagination ────────────────────────────────────────────────────────────

  /// Xem thêm: Hiện tại chuyển sang Infinite Scroll tự động
  void loadMoreProducts() => expandProducts();

  void expandProducts() {
    emit(state.copyWith(
      isProductsExpanded: true,
      visibleProductCount: 99, // Show all currently loaded
    ));
  }

  void collapseProducts() {
    emit(state.copyWith(
      isProductsExpanded: false,
      visibleProductCount: 4,
    ));
  }

  // ── Filters ───────────────────────────────────────────────────────────────

  void setSortOption(SortOption option) {
    final next = state.sortOption == option ? SortOption.none : option;
    emit(state.copyWith(
      sortOption: next,
      isProductsExpanded: false,
      visibleProductCount: 4,
      hasLoadedMore: false,
    ));
    _loadProductsFirstPage();
  }

  void toggleGender(String gender) {
    final current = Set<String>.from(state.selectedGenders);
    if (current.contains(gender)) {
      current.remove(gender);
    } else {
      current.add(gender);
    }
    emit(state.copyWith(
      selectedGenders: current,
      isProductsExpanded: false,
      visibleProductCount: 4,
      hasLoadedMore: false,
    ));
    _loadProductsFirstPage();
  }

  void setBrand(String brand) {
    final next = state.selectedBrand == brand ? '' : brand;
    emit(state.copyWith(
      selectedBrand: next,
      isProductsExpanded: false,
      visibleProductCount: 4,
      hasLoadedMore: false,
    ));
    _loadProductsFirstPage();
  }

  // ── Pitch District ────────────────────────────────────────────────────────

  void selectDistrict(String district) {
    final next = state.selectedDistrict == district ? '' : district;
    emit(state.copyWith(selectedDistrict: next));
    _loadPitchesFirstPage();
  }

  void updateSearchQuery(String query) {
    _searchDebounce?.cancel();
    emit(state.copyWith(searchQuery: query));
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _loadPitchesFirstPage();
    });
  }

  void updatePitchFilters({String? type, String? sort}) {
    emit(state.copyWith(
      selectedPitchType: type ?? state.selectedPitchType,
      pitchSortOrder: sort ?? state.pitchSortOrder,
    ));
    _loadPitchesFirstPage();
  }

  void reset() => emit(const HomeState());

  Future<void> refresh() => loadAll();
}

