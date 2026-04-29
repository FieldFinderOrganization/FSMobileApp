import '../../domain/entities/cart_item_entity.dart';

class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.productId,
    required super.productName,
    required super.imageUrl,
    required super.brand,
    required super.sex,
    required super.size,
    required super.originalPrice,
    required super.unitPrice,
    required super.totalPrice,
    required super.quantity,
    required super.stockAvailable,
    super.salePercent,
    super.categoryId,
    super.appliedDiscountCodes,
    super.availableGlobalCodes,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      productId: (json['productId'] as num).toInt(),
      productName: json['productName'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      sex: json['sex'] as String? ?? '',
      size: json['size'] as String? ?? '',
      originalPrice: (json['originalPrice'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      stockAvailable: (json['stockAvailable'] as num?)?.toInt() ?? 0,
      salePercent: (json['salePercent'] as num?)?.toInt(),
      categoryId: (json['categoryId'] as num?)?.toInt(),
      appliedDiscountCodes: (json['appliedDiscountCodes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      availableGlobalCodes: (json['availableGlobalCodes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
