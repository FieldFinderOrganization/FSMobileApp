class DiscountEntity {
  final String id;
  final String code;
  final String description;
  final double value;
  final String discountType;
  final String status;
  final DateTime startDate;
  final DateTime endDate;

  const DiscountEntity({
    required this.id,
    required this.code,
    required this.description,
    required this.value,
    required this.discountType,
    required this.status,
    required this.startDate,
    required this.endDate,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isPercentage => discountType == 'PERCENTAGE';
}
