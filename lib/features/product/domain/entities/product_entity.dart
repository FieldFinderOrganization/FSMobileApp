import 'product_variant_entity.dart';

class ProductEntity {
  final String id;
  final String name;
  final String description;
  final String categoryName;
  final double price;
  final int? salePercent;
  final double? salePrice;
  final String imageUrl;
  final String brand;
  final String sex;
  final List<String> tags;
  final int totalSold;
  final List<ProductVariantEntity> variants;
  final List<String>? appliedDiscountCodes;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryName,
    required this.price,
    this.salePercent,
    this.salePrice,
    required this.imageUrl,
    required this.brand,
    required this.sex,
    required this.tags,
    required this.totalSold,
    this.variants = const [],
    this.appliedDiscountCodes,
  });

  bool get isOnSale => salePercent != null && salePercent! > 0;
  bool get hasPersonalizedDiscount =>
      appliedDiscountCodes != null && appliedDiscountCodes!.isNotEmpty;
}
