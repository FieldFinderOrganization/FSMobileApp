import '../../domain/entities/product_entity.dart';
import '../../domain/entities/suggested_products_entity.dart';
import '../../../pitch/domain/entities/suggested_pitches_entity.dart';

enum ProductDetailStatus { initial, loading, success, failure }

class ProductDetailState {
  final ProductDetailStatus status;
  final ProductEntity? product;
  final String? selectedSize;
  final String errorMessage;
  final SuggestedProductsEntity suggested;
  final SuggestedPitchesEntity suggestedPitches;
  final bool suggestedLoading;

  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.product,
    this.selectedSize,
    this.errorMessage = '',
    this.suggested = const SuggestedProductsEntity(),
    this.suggestedPitches = const SuggestedPitchesEntity(),
    this.suggestedLoading = false,
  });

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductEntity? product,
    String? selectedSize,
    String? errorMessage,
    SuggestedProductsEntity? suggested,
    SuggestedPitchesEntity? suggestedPitches,
    bool? suggestedLoading,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      selectedSize: selectedSize ?? this.selectedSize,
      errorMessage: errorMessage ?? this.errorMessage,
      suggested: suggested ?? this.suggested,
      suggestedPitches: suggestedPitches ?? this.suggestedPitches,
      suggestedLoading: suggestedLoading ?? this.suggestedLoading,
    );
  }
}
