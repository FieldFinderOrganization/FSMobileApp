import '../../domain/entities/product_entity.dart';

enum ProductDetailStatus { initial, loading, success, failure }

class ProductDetailState {
  final ProductDetailStatus status;
  final ProductEntity? product;
  final String? selectedSize;
  final String errorMessage;

  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.product,
    this.selectedSize,
    this.errorMessage = '',
  });

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    ProductEntity? product,
    String? selectedSize,
    String? errorMessage,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      product: product ?? this.product,
      selectedSize: selectedSize ?? this.selectedSize,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
