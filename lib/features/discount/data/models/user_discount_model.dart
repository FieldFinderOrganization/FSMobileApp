import '../../domain/entities/user_discount_entity.dart';

class UserDiscountModel extends UserDiscountEntity {
  const UserDiscountModel({
    required super.userDiscountId,
    required super.discountCode,
    required super.description,
    required super.walletStatus,
    required super.value,
    required super.type,
    required super.startDate,
    required super.endDate,
    super.minOrderValue,
    super.maxDiscountAmount,
    required super.scope,
    super.applicableProductIds = const [],
    super.applicableCategoryIds = const [],
    super.kind = 'PROMOTION',
    super.remainingValue,
  });

  factory UserDiscountModel.fromJson(Map<String, dynamic> json) {
    return UserDiscountModel(
      userDiscountId: json['userDiscountId']?.toString() ?? '',
      discountCode: json['discountCode'] as String? ?? '',
      description: json['description'] as String? ?? '',
      walletStatus: json['status'] as String? ?? 'AVAILABLE',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      type: json['type'] as String? ?? 'PERCENTAGE',
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble(),
      scope: json['scope'] as String? ?? 'GLOBAL',
      applicableProductIds: (json['applicableProductIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
      applicableCategoryIds:
          (json['applicableCategoryIds'] as List<dynamic>?)
                  ?.map((e) => (e as num).toInt())
                  .toList() ??
              [],
      kind: json['kind'] as String? ?? 'PROMOTION',
      remainingValue: (json['remainingValue'] as num?)?.toDouble(),
    );
  }
}
