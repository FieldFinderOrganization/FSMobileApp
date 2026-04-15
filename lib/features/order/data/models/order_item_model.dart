class OrderItemModel {
  final int productId;
  final String productName;
  final int quantity;
  final double price;
  final String? imageUrl;
  final String size;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    this.imageUrl,
    required this.size,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: (json['productId'] as num?)?.toInt() ?? 0,
      productName: json['productName'] as String? ?? 'Sản phẩm',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['imageUrl'] as String?,
      size: json['size'] as String? ?? '',
    );
  }
}
