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
  final int quantity; // remaining stock; 0 = depleted

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
    this.quantity = 0,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isPercentage => discountType == 'PERCENTAGE';
  bool get isPromotion => kind == 'PROMOTION';
  bool get isAllowedScope =>
      scope == 'GLOBAL' || scope == 'CATEGORY' || scope == 'SPECIFIC_PRODUCT';

  /// Mã user thực sự dùng được: ACTIVE + trong khoảng ngày + còn kho.
  /// Khớp với DiscountEligibilityUtil.isUsable phía backend.
  bool get isUsable {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final started = !today.isBefore(start);
    final notExpired = !today.isAfter(end); // end day inclusive, khớp backend
    return isActive && started && notExpired && quantity > 0;
  }
}
