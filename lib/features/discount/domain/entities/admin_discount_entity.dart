import '../../../../core/utils/money_utils.dart';

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
  final String kind; // PROMOTION | REFUND_CREDIT
  final String? minTier; // null = mọi hạng | MEMBER | SILVER | GOLD | DIAMOND (hạng đó trở lên)
  final int? pointCost; // null = không đổi bằng điểm; có giá = chỉ đổi qua điểm thưởng

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
    this.kind = 'PROMOTION',
    this.minTier,
    this.pointCost,
  });

  /// Tính trạng thái thực tế: nếu đã qua endDate thì luôn là EXPIRED
  String get effectiveStatus {
    if (endDate.isBefore(DateTime.now())) return 'EXPIRED';
    return status;
  }

  bool get isActive => effectiveStatus == 'ACTIVE';
  bool get isPercentage => discountType == 'PERCENTAGE';
  bool get isPromotion => kind == 'PROMOTION';

  /// Mã public user có thể claim: promo + ACTIVE + trong hạn + còn kho.
  bool get isClaimable {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final started = !today.isBefore(start);
    final notExpired = !today.isAfter(end);
    return isPromotion &&
        status == 'ACTIVE' &&
        started &&
        notExpired &&
        quantity > 0;
  }

  String get displayValue =>
      isPercentage ? '${value.toInt()}%' : formatVnd(value);
}
