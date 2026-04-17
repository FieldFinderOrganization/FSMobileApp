class TopProductModel {
  final dynamic productId;
  final String name;
  final String? imageUrl;
  final int totalSold;
  final double totalRevenue;

  const TopProductModel({
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.totalSold,
    required this.totalRevenue,
  });

  factory TopProductModel.fromJson(Map<String, dynamic> json) {
    return TopProductModel(
      productId: json['productId'],
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      totalSold: (json['totalSold'] as num).toInt(),
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
    );
  }
}

class ProductCategoryModel {
  final String category;
  final int count;

  const ProductCategoryModel({required this.category, required this.count});

  factory ProductCategoryModel.fromJson(Map<String, dynamic> json) {
    return ProductCategoryModel(
      category: json['category'] as String,
      count: (json['count'] as num).toInt(),
    );
  }
}

class ProductStatisticsModel {
  final int totalProducts;
  final int totalSold;
  final List<TopProductModel> topProducts;
  final List<ProductCategoryModel> byCategory;

  const ProductStatisticsModel({
    required this.totalProducts,
    required this.totalSold,
    required this.topProducts,
    required this.byCategory,
  });

  factory ProductStatisticsModel.fromJson(Map<String, dynamic> json) {
    return ProductStatisticsModel(
      totalProducts: (json['totalProducts'] as num).toInt(),
      totalSold: (json['totalSold'] as num).toInt(),
      topProducts: (json['topProducts'] as List<dynamic>)
          .map((e) => TopProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      byCategory: (json['byCategory'] as List<dynamic>)
          .map((e) => ProductCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
