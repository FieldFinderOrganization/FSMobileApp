import 'cart_item_entity.dart';

class CartEntity {
  final List<CartItemEntity> items;
  final double totalCartPrice;

  const CartEntity({
    required this.items,
    required this.totalCartPrice,
  });

  bool get isEmpty => items.isEmpty;
}
