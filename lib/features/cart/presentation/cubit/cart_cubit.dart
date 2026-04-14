import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cart_entity.dart';
import '../../domain/entities/cart_item_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final CartRepository _cartRepository;

  CartCubit(this._cartRepository) : super(const CartState());

  Future<void> loadCart() async {
    emit(state.copyWith(status: CartStatus.loading));
    try {
      final cart = await _cartRepository.getCart();

      // Validate each item against current stock
      final adjustedItems = <CartItemEntity>[];
      final serverUpdates = <Future<void>>[];

      for (final item in cart.items) {
        if (item.exceedsStock) {
          // Quantity in cart exceeds available stock — auto-adjust down
          final adjusted = item.copyWith(
            quantity: item.stockAvailable,
            totalPrice: item.unitPrice * item.stockAvailable,
          );
          adjustedItems.add(adjusted);
          // Sync silently with server
          serverUpdates.add(
            _cartRepository
                .updateItem(item.productId, item.size, item.stockAvailable)
                .catchError((_) {}),
          );
        } else {
          adjustedItems.add(item);
        }
      }

      // Total excludes fully out-of-stock items
      final total = adjustedItems
          .where((i) => !i.isOutOfStock)
          .fold<double>(0.0, (sum, i) => sum + i.totalPrice);

      emit(CartState(
        status: CartStatus.success,
        cart: CartEntity(items: adjustedItems, totalCartPrice: total),
      ));

      // Fire-and-forget adjustments
      Future.wait(serverUpdates);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(status: CartStatus.failure, errorMessage: msg));
    }
  }

  Future<void> addItem(int productId, String size, int quantity,
      {int? stockAvailable}) async {
    // Client-side stock guard
    final existingItem = state.cart?.items
        .where((i) => i.productId == productId && i.size == size)
        .firstOrNull;

    final stock = stockAvailable ?? existingItem?.stockAvailable;
    if (stock != null) {
      final currentQty = existingItem?.quantity ?? 0;
      if (currentQty + quantity > stock) {
        emit(state.copyWith(
          status: CartStatus.failure,
          errorMessage: 'Số lượng trong giỏ đã đạt giới hạn tồn kho (Còn: $stock)',
        ));
        return;
      }
    }

    try {
      await _cartRepository.addItem(productId, size, quantity);
      // Always reload to get fresh stock info from server
      await loadCartSilently(successMessage: 'Đã thêm vào giỏ hàng!');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(status: CartStatus.failure, errorMessage: msg));
    }
  }

  /// Loads cart without emitting loading state, used after mutations.
  Future<void> loadCartSilently({String? successMessage}) async {
    try {
      final cart = await _cartRepository.getCart();

      final adjustedItems = <CartItemEntity>[];
      final serverUpdates = <Future<void>>[];

      for (final item in cart.items) {
        if (item.exceedsStock) {
          final adjusted = item.copyWith(
            quantity: item.stockAvailable,
            totalPrice: item.unitPrice * item.stockAvailable,
          );
          adjustedItems.add(adjusted);
          serverUpdates.add(
            _cartRepository
                .updateItem(item.productId, item.size, item.stockAvailable)
                .catchError((_) {}),
          );
        } else {
          adjustedItems.add(item);
        }
      }

      final total = adjustedItems
          .where((i) => !i.isOutOfStock)
          .fold<double>(0.0, (sum, i) => sum + i.totalPrice);

      emit(CartState(
        status: CartStatus.success,
        cart: CartEntity(items: adjustedItems, totalCartPrice: total),
        successMessage: successMessage,
      ));

      Future.wait(serverUpdates);
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(status: CartStatus.failure, errorMessage: msg));
    }
  }

  /// Optimistically updates quantity, syncs with server silently.
  Future<void> updateItem(int productId, String size, int quantity) async {
    if (quantity <= 0) {
      await removeItem(productId, size);
      return;
    }

    final previous = state.cart;
    if (previous == null) return;

    // Guard: never exceed stockAvailable (client-side)
    final target = previous.items
        .where((i) => i.productId == productId && i.size == size)
        .firstOrNull;
    if (target == null) return;
    if (quantity > target.stockAvailable) return;

    // Optimistic update
    final updatedItems = previous.items.map((item) {
      if (item.productId == productId && item.size == size) {
        return item.copyWith(
          quantity: quantity,
          totalPrice: item.unitPrice * quantity,
        );
      }
      return item;
    }).toList();

    final newTotal = updatedItems
        .where((i) => !i.isOutOfStock)
        .fold<double>(0.0, (sum, i) => sum + i.totalPrice);

    emit(CartState(
      status: CartStatus.success,
      cart: CartEntity(items: updatedItems, totalCartPrice: newTotal),
    ));

    // Sync with server silently
    try {
      await _cartRepository.updateItem(productId, size, quantity);
    } catch (e) {
      // Revert on failure
      emit(CartState(status: CartStatus.success, cart: previous));
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(status: CartStatus.failure, errorMessage: msg));
    }
  }

  Future<void> removeItem(int productId, String size) async {
    final previous = state.cart;

    // Optimistic remove
    if (previous != null) {
      final updatedItems = previous.items
          .where((i) => !(i.productId == productId && i.size == size))
          .toList();
      final newTotal = updatedItems
          .where((i) => !i.isOutOfStock)
          .fold<double>(0.0, (sum, i) => sum + i.totalPrice);
      emit(CartState(
        status: CartStatus.success,
        cart: CartEntity(items: updatedItems, totalCartPrice: newTotal),
      ));
    }

    try {
      await _cartRepository.removeItem(productId, size);
    } catch (_) {
      if (previous != null) {
        emit(CartState(status: CartStatus.success, cart: previous));
      }
    }
  }

  Future<void> clearCart() async {
    try {
      await _cartRepository.clearCart();
      emit(CartState(
        status: CartStatus.success,
        cart: CartEntity(items: const [], totalCartPrice: 0.0),
      ));
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      emit(state.copyWith(status: CartStatus.failure, errorMessage: msg));
    }
  }
}
