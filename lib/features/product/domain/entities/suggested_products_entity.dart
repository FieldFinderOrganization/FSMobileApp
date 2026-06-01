import 'product_entity.dart';

class SuggestedProductsEntity {
  final List<ProductEntity> similar;
  final List<ProductEntity> topSelling;
  final List<ProductEntity> historyBased;

  const SuggestedProductsEntity({
    this.similar = const [],
    this.topSelling = const [],
    this.historyBased = const [],
  });

  bool get isEmpty => similar.isEmpty && topSelling.isEmpty && historyBased.isEmpty;
}
