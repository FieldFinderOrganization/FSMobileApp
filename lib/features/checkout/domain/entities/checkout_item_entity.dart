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
  final List<String> availableGlobalCodes;

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
    this.availableGlobalCodes = const [],
  });

  /// Giá đã áp item-level discount × số lượng (dùng để hiển thị).
  double get totalPrice => unitPrice * quantity;

  /// Giá gốc × số lượng (dùng làm base tính lại discount ở checkout).
  /// Tránh double-discount khi cart đã trừ sẵn rồi checkout trừ lại.
  double get originalTotalPrice => originalPrice * quantity;
}
