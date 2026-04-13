import 'package:flutter/material.dart';
import '../../domain/entities/product_entity.dart';
import '../../../home/domain/entities/category_entity.dart';
import '../../../home/presentation/cubit/home_state.dart'; // Reuse LoadStatus and SortOption

Set<String> _getDescendantNames(
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

class ProductState {
  final LoadStatus status;
  final LoadStatus categoriesStatus;
  final List<ProductEntity> products;
  final List<CategoryEntity> categories;
  final String searchQuery;
  final Set<String> selectedBrands;
  final String selectedCategory; // Parent category name
  final Set<String> selectedSubCategoryNames;
  final RangeValues priceRange;
  final SortOption sortOption;
  final String? errorMessage;

  const ProductState({
    this.status = LoadStatus.initial,
    this.categoriesStatus = LoadStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.searchQuery = '',
    this.selectedBrands = const {},
    this.selectedCategory = '',
    this.selectedSubCategoryNames = const {},
    this.priceRange = const RangeValues(0, 1000),
    this.sortOption = SortOption.none,
    this.errorMessage,
  });

  // ── Derived ─────────────────────────────────────────────────────────────

  List<CategoryEntity> get rootCategories => categories
      .where((c) => (c.parentName == null || c.parentName!.isEmpty))
      .toList();

  List<CategoryEntity> get subCategories => selectedCategory.isEmpty
      ? []
      : categories
          .where((c) => c.parentName == selectedCategory)
          .toList();

  List<ProductEntity> get filteredProducts {
    var result = products;

    // Filter by Category (Hierarchical)
    if (selectedCategory.isNotEmpty) {
      final Set<String> targetNames;
      if (selectedSubCategoryNames.isNotEmpty) {
        targetNames = {};
        for (final sub in selectedSubCategoryNames) {
          targetNames.addAll(_getDescendantNames(categories, sub));
        }
      } else {
        targetNames = _getDescendantNames(categories, selectedCategory);
      }
      result = result.where((p) => targetNames.contains(p.categoryName)).toList();
    }

    // Filter by Search Query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(query)).toList();
    }

    // Filter by Brand
    if (selectedBrands.isNotEmpty) {
      result = result.where((p) => selectedBrands.contains(p.brand)).toList();
    }

    // Filter by Price
    result = result.where((p) {
      final effectivePrice = p.salePrice ?? p.price;
      return effectivePrice >= priceRange.start && effectivePrice <= priceRange.end;
    }).toList();

    // Sort
    switch (sortOption) {
      case SortOption.priceAsc:
        result = [...result]..sort((a, b) => (a.salePrice ?? a.price).compareTo(b.salePrice ?? b.price));
      case SortOption.priceDesc:
        result = [...result]..sort((a, b) => (b.salePrice ?? b.price).compareTo(a.salePrice ?? a.price));
      case SortOption.none:
        break;
    }

    return result;
  }

  List<String> get allBrands {
    final brands = products.map((p) => p.brand).where((b) => b.isNotEmpty).toSet().toList();
    brands.sort();
    return brands;
  }

  double get maxPriceInList {
    if (products.isEmpty) return 1000;
    return products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }

  // ── copyWith ─────────────────────────────────────────────────────────────

  ProductState copyWith({
    LoadStatus? status,
    LoadStatus? categoriesStatus,
    List<ProductEntity>? products,
    List<CategoryEntity>? categories,
    String? searchQuery,
    Set<String>? selectedBrands,
    String? selectedCategory,
    Set<String>? selectedSubCategoryNames,
    RangeValues? priceRange,
    SortOption? sortOption,
    String? errorMessage,
  }) {
    return ProductState(
      status: status ?? this.status,
      categoriesStatus: categoriesStatus ?? this.categoriesStatus,
      products: products ?? this.products,
      categories: categories ?? this.categories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedBrands: selectedBrands ?? this.selectedBrands,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedSubCategoryNames: selectedSubCategoryNames ?? this.selectedSubCategoryNames,
      priceRange: priceRange ?? this.priceRange,
      sortOption: sortOption ?? this.sortOption,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
