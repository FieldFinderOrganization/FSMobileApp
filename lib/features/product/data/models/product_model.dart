import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_variant_entity.dart';

class ProductVariantModel extends ProductVariantEntity {
  const ProductVariantModel({
    required super.size,
    required super.quantity,
    required super.stockTotal,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      size: json['size'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      stockTotal: json['stockTotal'] as int? ?? 0,
    );
  }
}

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.categoryName,
    required super.price,
    super.salePercent,
    super.salePrice,
    required super.imageUrl,
    required super.brand,
    required super.sex,
    required super.tags,
    required super.totalSold,
    super.variants = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      salePercent: json['salePercent'] as int?,
      salePrice: json['salePrice'] != null
          ? (json['salePrice'] as num).toDouble()
          : null,
      imageUrl: json['imageUrl'] as String? ?? '',
      brand: json['brand'] as String? ?? '',
      sex: json['sex'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalSold: json['totalSold'] as int? ?? 0,
      variants: (json['variants'] as List<dynamic>?)
              ?.map((e) => ProductVariantModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
