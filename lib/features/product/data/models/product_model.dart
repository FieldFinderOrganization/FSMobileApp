import '../../domain/entities/product_entity.dart';

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
    );
  }
}
