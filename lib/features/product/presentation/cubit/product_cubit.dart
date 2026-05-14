import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../home/presentation/cubit/home_state.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;

  /// Tăng mỗi lần bắt đầu `loadProducts` để bỏ qua kết quả cũ (prefetch / phân trang vs đổi filter).
  int _catalogLoadGeneration = 0;

  ProductCubit({required ProductRepository repository})
      : _repository = repository,
        super(const ProductState());

  String? _sortParam([SortOption? option]) {
    final opt = option ?? state.sortOption;
    switch (opt) {
      case SortOption.priceAsc:
        return 'price,asc';
      case SortOption.priceDesc:
        return 'price,desc';
      case SortOption.none:
        return null;
    }
    return null;
  }

  String? get _brandParam {
    if (state.selectedBrands.length == 1) return state.selectedBrands.first;
    return null;
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

  /// Giống `reload()`: id danh mục đang áp dụng cho list (sub ưu tiên hơn parent).
  int? _activeCategoryIdForListing() {
    final activeName = state.selectedSubCategoryNames.isNotEmpty
        ? state.selectedSubCategoryNames.first
        : state.selectedCategory;
    return _getCategoryIdFromName(activeName);
  }

  Future<void> loadProducts({int? categoryId, String? brand, String? sort}) async {
    final session = ++_catalogLoadGeneration;
    emit(state.copyWith(
      status: LoadStatus.loading,
      currentPage: 0,
      hasMore: true,
      products: [],
      priceRange: const RangeValues(0, 1000),
    ));
    try {
      final result = await _repository.getAllProducts(page: 0, size: 10, categoryId: categoryId, brand: brand, sort: sort);
      if (session != _catalogLoadGeneration) return;

      final List<ProductEntity> products = result['products'] as List<ProductEntity>;
      final bool last = result['last'] as bool;

      // Calculate max price to set the initial range correctly
      double maxPrice = 1000;
      if (products.isNotEmpty) {
        maxPrice = products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
      }

      emit(state.copyWith(
        status: LoadStatus.success,
        products: products,
        currentPage: 0,
        hasMore: !last,
        priceRange: RangeValues(0, maxPrice),
      ));

      await _loadCategories(session);
      if (session != _catalogLoadGeneration) return;

      // Trang 2 trong nền để kéo xuống bớt chờ (user vẫn có pull-to-refresh).
      if (!last) {
        unawaited(_prefetchNextPage(session));
      }
    } catch (e) {
      if (session != _catalogLoadGeneration) return;
      emit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;
    final session = _catalogLoadGeneration;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final categoryId = _activeCategoryIdForListing();
      final result = await _repository.getAllProducts(page: nextPage, size: 10, categoryId: categoryId, brand: _brandParam, sort: _sortParam());
      if (session != _catalogLoadGeneration) return;

      final List<ProductEntity> newProducts = result['products'] as List<ProductEntity>;
      final bool last = result['last'] as bool;

      emit(state.copyWith(
        isLoadingMore: false,
        products: [...state.products, ...newProducts],
        currentPage: nextPage,
        hasMore: !last,
      ));
    } catch (e) {
      if (session != _catalogLoadGeneration) return;
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _prefetchNextPage(int session) async {
    if (session != _catalogLoadGeneration) return;
    await loadNextPage();
  }

  Future<void> _loadCategories(int session) async {
    emit(state.copyWith(categoriesStatus: LoadStatus.loading));
    try {
      final categories = await _repository.fetchCategories();
      if (session != _catalogLoadGeneration) return;
      emit(state.copyWith(
        categoriesStatus: LoadStatus.success,
        categories: categories,
      ));
    } catch (e) {
      if (session != _catalogLoadGeneration) return;
      emit(state.copyWith(categoriesStatus: LoadStatus.failure));
    }
  }

  void updateSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void selectCategory(String categoryName) {
    final newCategory = state.selectedCategory == categoryName ? '' : categoryName;
    emit(state.copyWith(
      selectedCategory: newCategory,
      selectedSubCategoryNames: {},
    ));
    final categoryId = _getCategoryIdFromName(newCategory);
    loadProducts(categoryId: categoryId, brand: _brandParam, sort: _sortParam());
  }

  void toggleSubCategory(String subCategoryName) {
    // Toggle: deselect if already selected → reload parent; select → reload for this subcategory
    final isAlreadySelected = state.selectedSubCategoryNames.contains(subCategoryName);
    final newSub = isAlreadySelected ? <String>{} : <String>{subCategoryName};

    emit(state.copyWith(selectedSubCategoryNames: newSub));

    if (isAlreadySelected) {
      // Back to parent category
      final parentCategoryId = _getCategoryIdFromName(state.selectedCategory);
      loadProducts(categoryId: parentCategoryId, brand: _brandParam, sort: _sortParam());
    } else {
      // Load specifically for this subcategory
      final subCategoryId = _getCategoryIdFromName(subCategoryName);
      loadProducts(categoryId: subCategoryId, brand: _brandParam, sort: _sortParam());
    }
  }

  void toggleBrand(String brand) {
    final current = Set<String>.from(state.selectedBrands);
    if (current.contains(brand)) {
      current.remove(brand);
    } else {
      current.add(brand);
    }
    emit(state.copyWith(selectedBrands: current));
    final categoryId = _getCategoryIdFromName(
      state.selectedSubCategoryNames.isNotEmpty
          ? state.selectedSubCategoryNames.first
          : state.selectedCategory,
    );
    final brandParam = current.length == 1 ? current.first : null;
    loadProducts(categoryId: categoryId, brand: brandParam, sort: _sortParam());
  }

  void updatePriceRange(RangeValues values) {
    emit(state.copyWith(priceRange: values));
  }

  void setSortOption(SortOption option) {
    emit(state.copyWith(sortOption: option));
    final categoryId = _getCategoryIdFromName(
      state.selectedSubCategoryNames.isNotEmpty
          ? state.selectedSubCategoryNames.first
          : state.selectedCategory,
    );
    loadProducts(categoryId: categoryId, brand: _brandParam, sort: _sortParam(option));
  }

  void clearFilters() {
    emit(state.copyWith(
      searchQuery: '',
      selectedBrands: const {},
      selectedCategory: '',
      selectedSubCategoryNames: const {},
      sortOption: SortOption.none,
      priceRange: RangeValues(0, state.maxPriceInList),
    ));
    loadProducts();
  }

  Future<void> reload() async {
    // If a subcategory is active, reload with it; otherwise reload parent category
    final activeCategory = state.selectedSubCategoryNames.isNotEmpty
        ? state.selectedSubCategoryNames.first
        : state.selectedCategory;
    final categoryId = _getCategoryIdFromName(activeCategory);
    await loadProducts(categoryId: categoryId, brand: _brandParam, sort: _sortParam());
  }

  void reset() {
    _catalogLoadGeneration++;
    emit(const ProductState());
  }
}
