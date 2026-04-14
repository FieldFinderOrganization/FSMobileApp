import '../entities/cart_entity.dart';

abstract class CartRepository {
  Future<CartEntity> getCart();
  Future<void> addItem(int productId, String size, int quantity);
  Future<void> updateItem(int productId, String size, int quantity);
  Future<void> removeItem(int productId, String size);
  Future<void> clearCart();
}
