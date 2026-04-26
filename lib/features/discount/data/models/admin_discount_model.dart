import '../../domain/entities/admin_discount_entity.dart';

class AdminDiscountModel extends AdminDiscountEntity {
  const AdminDiscountModel({
    required super.id,
    required super.code,
    required super.description,
    required super.value,
    required super.discountType,
    super.minOrderValue,
    super.maxDiscountAmount,
    required super.scope,
    super.applicableProductIds = const [],
    super.applicableCategoryIds = const [],
    required super.quantity,
    required super.startDate,
    required super.endDate,
    required super.status,
  });

  factory AdminDiscountModel.fromJson(Map<String, dynamic> json) {
    return AdminDiscountModel(
      id: json['id']?.toString() ?? '',
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      discountType: json['discountType'] as String? ?? 'PERCENTAGE',
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      maxDiscountAmount: (json['maxDiscountAmount'] as num?)?.toDouble(),
      scope: json['scope'] as String? ?? 'GLOBAL',
      applicableProductIds: (json['applicableProductIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      applicableCategoryIds:
          (json['applicableCategoryIds'] as List<dynamic>?)
                  ?.map((e) => e as int)
                  .toList() ??
              [],
      quantity: json['quantity'] as int? ?? 0,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'INACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'description': description,
      'value': value,
      'discountType': discountType,
      'minOrderValue': minOrderValue,
      'maxDiscountAmount': maxDiscountAmount,
      'scope': scope,
      'applicableProductIds': applicableProductIds,
      'applicableCategoryIds': applicableCategoryIds,
      'quantity': quantity,
      'startDate': startDate.toIso8601String().substring(0, 10),
      'endDate': endDate.toIso8601String().substring(0, 10),
      'status': status,
    };
  }
}
