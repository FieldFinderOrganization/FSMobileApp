import '../../domain/entities/cart_entity.dart';

enum CartStatus { initial, loading, success, failure }

class CartState {
  final CartStatus status;
  final CartEntity? cart;
  final String? errorMessage;
  final String? successMessage;

  const CartState({
    this.status = CartStatus.initial,
    this.cart,
    this.errorMessage,
    this.successMessage,
  });

  CartState copyWith({
    CartStatus? status,
    CartEntity? cart,
    String? errorMessage,
    String? successMessage,
  }) {
    return CartState(
      status: status ?? this.status,
      cart: cart ?? this.cart,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}
