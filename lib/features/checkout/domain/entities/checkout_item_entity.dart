class CheckoutItemEntity {
  final int productId;
  final String productName;
  final String brand;
  final String imageUrl;
  final String size;
  final double unitPrice;
  final double originalPrice;
  final int? salePercent;
  final int quantity;
  final int? categoryId;
  final List<String> autoAppliedCodes;

  const CheckoutItemEntity({
    required this.productId,
    required this.productName,
    required this.brand,
    required this.imageUrl,
    required this.size,
    required this.unitPrice,
    required this.originalPrice,
    this.salePercent,
    required this.quantity,
    this.categoryId,
    this.autoAppliedCodes = const [],
  });

  double get totalPrice => unitPrice * quantity;
}
