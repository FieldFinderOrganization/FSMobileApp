class DiscountEntity {
  final String id;
  final String code;
  final String description;
  final double value;
  final String discountType;
  final String status;
  final DateTime startDate;
  final DateTime endDate;
  final String kind;  // PROMOTION | REFUND_CREDIT
  final String scope; // GLOBAL | CATEGORY | SPECIFIC_PRODUCT

  const DiscountEntity({
    required this.id,
    required this.code,
    required this.description,
    required this.value,
    required this.discountType,
    required this.status,
    required this.startDate,
    required this.endDate,
    this.kind = 'PROMOTION',
    this.scope = 'GLOBAL',
  });

  bool get isActive => status == 'ACTIVE';
  bool get isPercentage => discountType == 'PERCENTAGE';
  bool get isPromotion => kind == 'PROMOTION';
  bool get isAllowedScope =>
      scope == 'GLOBAL' || scope == 'CATEGORY' || scope == 'SPECIFIC_PRODUCT';
}
