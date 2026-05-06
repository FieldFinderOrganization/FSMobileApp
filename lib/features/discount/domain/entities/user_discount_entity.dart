class UserDiscountEntity {
  final String userDiscountId;
  final String discountCode;
  final String description;
  final String walletStatus; // AVAILABLE | USED | EXPIRED
  final double value;
  final String type; // PERCENTAGE | FIXED_AMOUNT
  final DateTime startDate;
  final DateTime endDate;
  final double? minOrderValue;
  final double? maxDiscountAmount;
  final String scope; // GLOBAL | SPECIFIC_PRODUCT | CATEGORY
  final List<int> applicableProductIds;
  final List<int> applicableCategoryIds;
  final String kind; // PROMOTION | REFUND_CREDIT
  final double? remainingValue; // null = mã promo cũ; số = số dư mã hoàn tiền

  const UserDiscountEntity({
    required this.userDiscountId,
    required this.discountCode,
    required this.description,
    required this.walletStatus,
    required this.value,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.minOrderValue,
    this.maxDiscountAmount,
    required this.scope,
    this.applicableProductIds = const [],
    this.applicableCategoryIds = const [],
    this.kind = 'PROMOTION',
    this.remainingValue,
  });

  bool get isAvailable => walletStatus == 'AVAILABLE';
  bool get isPercentage => type == 'PERCENTAGE';
  bool get isRefundCredit => kind == 'REFUND_CREDIT';

  /// Giá trị thực còn dùng được. Promo: value gốc. Refund: remainingValue.
  double get effectiveValue =>
      isRefundCredit ? (remainingValue ?? value) : value;

  String get displayValue =>
      isPercentage ? '${value.toInt()}%' : '${value.toInt()}đ';

  String get scopeLabel {
    if (isRefundCredit) return 'Hoàn tiền';
    switch (scope) {
      case 'GLOBAL':
        return 'Toàn bộ đơn hàng';
      case 'SPECIFIC_PRODUCT':
        return 'Sản phẩm cụ thể';
      case 'CATEGORY':
        return 'Danh mục';
      default:
        return scope;
    }
  }
}
