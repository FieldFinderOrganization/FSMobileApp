class AdminDiscountEntity {
  final String id;
  final String code;
  final String description;
  final double value;
  final String discountType; // PERCENTAGE | FIXED_AMOUNT
  final double? minOrderValue;
  final double? maxDiscountAmount;
  final String scope; // GLOBAL | SPECIFIC_PRODUCT | CATEGORY
  final List<int> applicableProductIds;
  final List<int> applicableCategoryIds;
  final int quantity;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // ACTIVE | INACTIVE | EXPIRED

  const AdminDiscountEntity({
    required this.id,
    required this.code,
    required this.description,
    required this.value,
    required this.discountType,
    this.minOrderValue,
    this.maxDiscountAmount,
    required this.scope,
    this.applicableProductIds = const [],
    this.applicableCategoryIds = const [],
    required this.quantity,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  /// Tính trạng thái thực tế: nếu đã qua endDate thì luôn là EXPIRED
  String get effectiveStatus {
    if (endDate.isBefore(DateTime.now())) return 'EXPIRED';
    return status;
  }

  bool get isActive => effectiveStatus == 'ACTIVE';
  bool get isPercentage => discountType == 'PERCENTAGE';

  String get displayValue =>
      isPercentage ? '${value.toInt()}%' : '${value.toInt()}đ';
}
