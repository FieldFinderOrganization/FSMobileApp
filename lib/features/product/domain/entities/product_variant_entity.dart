class ProductVariantEntity {
  final String size;
  final int quantity;
  final int stockTotal;

  const ProductVariantEntity({
    required this.size,
    required this.quantity,
    required this.stockTotal,
  });

  bool get isAvailable => quantity > 0;
}
