import '../../domain/entities/product_entity.dart';
import '../../domain/entities/pitch_entity.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/discount_entity.dart';

enum LoadStatus { initial, loading, success, failure }

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
    this.errorMessage,
  });

  List<ProductEntity> get filteredProducts => selectedCategoryName.isEmpty
      ? products
      : products
          .where((p) => p.categoryName == selectedCategoryName)
          .toList();

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
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
