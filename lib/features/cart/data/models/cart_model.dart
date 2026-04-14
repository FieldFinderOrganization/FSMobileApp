import '../../domain/entities/cart_entity.dart';
import 'cart_item_model.dart';

class CartModel extends CartEntity {
  const CartModel({
    required super.items,
    required super.totalCartPrice,
  });

  factory CartModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return CartModel(
      items: itemsJson
          .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalCartPrice: (json['totalCartPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
