import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../home/presentation/cubit/home_state.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;

  ProductCubit({required ProductRepository repository})
      : _repository = repository,
        super(const ProductState());

  int? _getCategoryIdFromName(String name) {
    if (name.isEmpty) return null;
    try {
      final category = state.categories.firstWhere((c) => c.name == name);
      return int.tryParse(category.id);
    } catch (_) {
      return null;
    }
  }

  Future<void> loadProducts({int? categoryId}) async {
    emit(state.copyWith(
      status: LoadStatus.loading,
      currentPage: 0,
      hasMore: true,
      products: [],
    ));
    try {
      final result = await _repository.getAllProducts(page: 0, size: 10, categoryId: categoryId);
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
        hasMore: !last,
        priceRange: RangeValues(0, maxPrice),
      ));

      // Loading categories as well
      await _loadCategories();
    } catch (e) {
      emit(state.copyWith(
        status: LoadStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final categoryId = _getCategoryIdFromName(state.selectedCategory);
      final result = await _repository.getAllProducts(page: nextPage, size: 10, categoryId: categoryId);
      final List<ProductEntity> newProducts = result['products'] as List<ProductEntity>;
      final bool last = result['last'] as bool;

      emit(state.copyWith(
        isLoadingMore: false,
        products: [...state.products, ...newProducts],
        currentPage: nextPage,
        hasMore: !last,
      ));
    } catch (e) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _loadCategories() async {
    emit(state.copyWith(categoriesStatus: LoadStatus.loading));
    try {
      final categories = await _repository.fetchCategories();
      emit(state.copyWith(
        categoriesStatus: LoadStatus.success,
        categories: categories,
      ));
    } catch (e) {
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
    loadProducts(categoryId: categoryId);
  }

  void toggleSubCategory(String subCategoryName) {
    // Toggle: deselect if already selected → reload parent; select → reload for this subcategory
    final isAlreadySelected = state.selectedSubCategoryNames.contains(subCategoryName);
    final newSub = isAlreadySelected ? <String>{} : <String>{subCategoryName};

    emit(state.copyWith(selectedSubCategoryNames: newSub));

    if (isAlreadySelected) {
      // Back to parent category
      final parentCategoryId = _getCategoryIdFromName(state.selectedCategory);
      loadProducts(categoryId: parentCategoryId);
    } else {
      // Load specifically for this subcategory
      final subCategoryId = _getCategoryIdFromName(subCategoryName);
      loadProducts(categoryId: subCategoryId);
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
  }

  void updatePriceRange(RangeValues values) {
    emit(state.copyWith(priceRange: values));
  }

  void setSortOption(SortOption option) {
    emit(state.copyWith(sortOption: option));
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
  }

  Future<void> reload() async {
    // If a subcategory is active, reload with it; otherwise reload parent category
    final activeCategory = state.selectedSubCategoryNames.isNotEmpty
        ? state.selectedSubCategoryNames.first
        : state.selectedCategory;
    final categoryId = _getCategoryIdFromName(activeCategory);
    await loadProducts(categoryId: categoryId);
  }

  void reset() {
    emit(const ProductState());
  }
}
