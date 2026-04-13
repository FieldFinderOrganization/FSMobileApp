import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/product_repository.dart';
import '../../../home/presentation/cubit/home_state.dart';
import 'product_state.dart';

class ProductCubit extends Cubit<ProductState> {
  final ProductRepository _repository;

  ProductCubit({required ProductRepository repository})
      : _repository = repository,
        super(const ProductState());

  Future<void> loadProducts() async {
    emit(state.copyWith(status: LoadStatus.loading));
    try {
      final products = await _repository.getAllProducts();
      
      // Calculate max price to set the initial range correctly
      double maxPrice = 1000;
      if (products.isNotEmpty) {
        maxPrice = products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
      }

      emit(state.copyWith(
        status: LoadStatus.success,
        products: products,
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
    // Reset sub-categories when parent changes
    emit(state.copyWith(
      selectedCategory: state.selectedCategory == categoryName ? '' : categoryName,
      selectedSubCategoryNames: {},
    ));
  }

  void toggleSubCategory(String subCategoryName) {
    final current = Set<String>.from(state.selectedSubCategoryNames);
    if (current.contains(subCategoryName)) {
      current.remove(subCategoryName);
    } else {
      current.add(subCategoryName);
    }
    emit(state.copyWith(selectedSubCategoryNames: current));
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
}
