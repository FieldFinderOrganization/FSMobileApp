class CartItemEntity {
  final int productId;
  final String productName;
  final String imageUrl;
  final String brand;
  final String sex;
  final String size;
  final double originalPrice;
  final double unitPrice;
  final double totalPrice;
  final int quantity;
  final int stockAvailable;
  final int? salePercent;
  final int? categoryId;
  final List<String> appliedDiscountCodes;

  const CartItemEntity({
    required this.productId,
    required this.productName,
    required this.imageUrl,
    required this.brand,
    required this.sex,
    required this.size,
    required this.originalPrice,
    required this.unitPrice,
    required this.totalPrice,
    required this.quantity,
    required this.stockAvailable,
    this.salePercent,
    this.categoryId,
    this.appliedDiscountCodes = const [],
  });

  /// Sản phẩm đã hết hàng hoàn toàn
  bool get isOutOfStock => stockAvailable == 0;

  /// Số lượng trong giỏ vượt tồn kho (do người khác vừa mua)
  bool get exceedsStock => !isOutOfStock && quantity > stockAvailable;

  CartItemEntity copyWith({
    int? quantity,
    double? totalPrice,
    int? stockAvailable,
  }) {
    return CartItemEntity(
      productId: productId,
      productName: productName,
      imageUrl: imageUrl,
      brand: brand,
      sex: sex,
      size: size,
      originalPrice: originalPrice,
      unitPrice: unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      quantity: quantity ?? this.quantity,
      stockAvailable: stockAvailable ?? this.stockAvailable,
      salePercent: salePercent,
      categoryId: categoryId,
      appliedDiscountCodes: appliedDiscountCodes,
    );
  }
}
